require_relative 'pac_man'
require_relative 'path_finder'
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
    visible_enemies.select { |enemy|
      pacman > enemy
    }.min { |pac1, pac2|
      pac1.position.distance(pac2.position)
    }
  end

  MAX_DISTANCE_TARGET = 4
  def target_enemy
    @_cached[__method__] ||= begin
      STDERR.puts "<target_enemy for=#{pacman}>"
      result = nil
      enemy = targetable_enemy
      ms = Benchmark.realtime {
        if enemy && pacman.position.distance(enemy.position) < MAX_DISTANCE_TARGET
          pf = PathFinder.new(
            game.grid_turn, pacman.position,
            is_visitable: -> (cell) { cell && cell.accessible_for?(pacman) }
            )
          result = pf.shortest_path(enemy.position).merge(kind: :pac)
        end
      } * 1000
      STDERR.puts "<target_enemy take=#{ms}ms>"
      result
    end
  end

  def must_switch?
    @_cached[__method__] ||= begin
      !visible_enemies.empty? && targetable_enemy.nil?
    end
  end

  def target_scoring
    @_cached[__method__] ||= begin
      STDERR.puts "<target_scoring for=#{pacman}>"
      res = nil
      ms = Benchmark.realtime {
        spf = ScoringPathFinder.new(game.grid_turn, pacman)
        res = spf.path_finder.merge(kind: :sco)
      } * 1000
      STDERR.puts "<target_scoring take=#{ms}ms>"
      res
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
      { next: next_bullet, path: path, value: pts, kind: :bul}
    end
  end

  def target
    @_cached[__method__] ||= begin
      STDERR.puts "<target for=#{pacman}>"
      result = nil
      ms = Benchmark.realtime {
        result = if target_enemy && target_enemy[:next]
          target_enemy
        # elsif target_scoring && target_scoring[:next]
        #   target_scoring
        elsif target_bullet && target_bullet[:next]
          target_bullet
        else
          raise "This Should never hapen. No possible target ?"
        end
      } * 1000
      STDERR.puts "</target for=#{pacman} take=#{ms}ms result=#{result}"
      result
    end
  end

  def next; target[:next];  end
  def path; target[:path];  end
  def value; target[:value];end
  def kind; target[:kind];  end
  def reset!;
    @_visible_enemies = []
    @_cached={};
  end

  private
  class ScoringPathFinder < PathFinder

    MAX_PROFIT = 10
    MAX_DEPTH = 12

    def initialize(grid, pacman)
      @pacman = pacman
      super(grid, @pacman.position,
        break_if: method(:break_if),
        is_visitable: method(:is_visitable),
        move_cost: method(:move_cost),
        move_profit: method(:move_profit),
        move_size: @pacman.current_speed
      )
    end

    def path_finder()
      @heuristic = PathFinder::Euristiques.method(:return_on_invest)

      # ms = Benchmark.realtime {
        dijkstra(
          break_if: @break_if, is_visitable: @is_visitable,
          move_profit: @move_profit, move_cost: @move_cost
        )
      # } * 1000
      # STDERR.puts "<dijkstra take #{ms}ms"

      # Max by [ROI, cost] with spaceship operator
      to = @visited.max { |(_, v1), (_, v2)| v1 <=> v2 }.first
      generate_result(to)
    end

    private

    def is_visitable(cell);
      !Game.instance.turn_targeted_pos.include?(cell.uid) &&
        cell.accessible_for?(@pacman)
    end

    def break_if(current, to);
      current && (current.profit > MAX_PROFIT || current.depth >= MAX_DEPTH)
    end

    def move_profit(current, neighbor)
      current.profit + Game.instance.visible_pellets[neighbor.to].to_i
    end

    def move_cost(current, neighbor)
      ((current.cost.to_f + neighbor.cost) / @move_size).round
    end
  end
end
