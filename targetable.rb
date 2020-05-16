require_relative 'pac_man'
require_relative 'scoring_path_finder'
require 'benchmark'

class TargetableCell

  attr_reader :pacman

  def initialize(pacman)
    @pacman = pacman
    @_cached = {}
    @_visible_enemies = []
  end

  def game; Game.instance; end

  def enemies; game.player(nil).pacmans; end
  def allies;  pacman.player.pacmans;     end

  def visible_enemies; @_visible_enemies; end

  def set_visible_enemy(pacman);
    @_visible_enemies << pacman
  end

  def targetable_enemy;
    @_cached[__method__] ||= begin
      visible_enemies.select { |enemy|
        pacman > enemy
      }.min { |pac1, pac2|
        pac1.position.distance(pac2.position)
      }
    end
  end

  def target_enemy
    @_cached[__method__] ||= begin
      enemy = targetable_enemy
      if enemy && pacman.current_speed == 2
        pf = PathFinder.new(
          game.grid_turn, pacman.position,
          is_visitable: -> (cell) { cell && cell.accessible_for?(pacman) },
          move_size: pacman.current_speed
        )
        pf.shortest_path(enemy.position).merge(kind: :pac)
      end
    end
  end

  def must_switch?
    @_cached[__method__] ||= begin
      !visible_enemies.empty? && targetable_enemy.nil? &&
        visible_enemies.detect { |enemy|
          pacman.position.distance(enemy.position) < 4
        }
    end
  end

  def target_scoring
    @_cached[__method__] ||= begin
      big_next, pts = game.visible_pellets.select { |_,v| v > 1}.sort_by { |pos, _|
        pos.distance(pacman.position)
      }.shift
      if big_next
        pf = PathFinder.new(game.grid_turn, pacman.position,
          is_visitable: -> (cell) { cell && cell.accessible_for?(pacman) },
          move_size: pacman.current_speed
        )
        spf = pf.shortest_path(big_next, max_depth: 15).merge(kind: :big)
        return spf if spf[:next]
      end
      spf = ScoringPathFinder.new(game.grid_turn, pacman,
        max_depth: 20)
      res = spf.path_finder.merge(kind: :sco)
      if res[:profit] >= 0
        res
      end
    end
  end

  def target_bullet
    @_cached[__method__] ||= begin
      STDERR.puts "<target_bullet for=#{pacman}>"
      next_bullet, path, pts = nil, nil, 0
      ms = Benchmark.realtime {
        mss = Benchmark.realtime {
          STDERR.puts "<sorting_distance over=#{game.visible_pellets.count}>"
          next_bullet, pts = game.visible_pellets.sort_by { |pos, pts|
            pos.distance(pacman.position) - pts
          }.shift
        } * 1000
        STDERR.puts "<sorting_distance take=#{mss}ms count=#{game.visible_pellets.count}>"
        msb = Benchmark.realtime {
          STDERR.puts "<bresenham for(#{pacman.position}) to(#{next_bullet})"
          path = pacman.position.bresenham(next_bullet)
        } * 1000
        STDERR.puts "<bresenham take=#{msb}ms count=#{path.count}>"
      } * 1000
      STDERR.puts "<target_bullet take=#{ms}ms>"
      { next: next_bullet, path: path, profit: pts, kind: :bul}
    end
  end

  def target
    @_cached[__method__] ||= begin
      if target_enemy && target_enemy[:next]
        target_enemy
      elsif target_scoring && target_scoring[:next]
        target_scoring
      elsif target_bullet && target_bullet[:next]
        target_bullet
      else
        raise "This Should never hapen. No possible target ?"
      end
    end
  end

  def next; target[:next];  end
  def path; target[:path];  end
  def value; target.slice(:profit, :cost); end
  def kind; target[:kind];  end
  def reset!;
    @_visible_enemies = []
    @_cached={};
  end
end
