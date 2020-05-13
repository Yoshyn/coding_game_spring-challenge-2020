require_relative 'pac_man'
require_relative 'path_finder'

class TargetableCell
  def initialize(pacman)
    @pacman = pacman
    @game = Game.instance
    @_cached = {}
  end

  def enemies; player(nil).pacmans;   end
  def allies;  pacman.player.pacmans; end

  def reachable_enemies;
    enemies.select { |enemy| pacman.can_reach?(enemy) }
  end

  def target_enemy
    @_cached[__method__] ||= begin
      enemy = reachable_enemies.detect { |enemy| pacman > enemy }
      if enemy
        pf = PathFinder.new(game.grid_turn, pacman.position)
        pf.shortest_path(enemy.position)
      end
    end
  end

  def must_switch?
    reachable_enemies && target_enemy.nil?
  end

  def target_scoring
    @_cached[__method__] ||= begin
      spf = ScoringPathFinder.new(game.grid_turn, pacman)
      spf.path_finder
    end
  end

  def target_bullet
    @_cached[__method__] ||= begin
      already_used_pos = game.turn_targeted_pos.to_a
      bullets = game.visible_pellets.except(*already_used_pos)
      bullets.sort_by { |pos, pts|
        pos.distance(pacman.position) - pts
      }.shift
    end
  end

  def target
    @_cached[__method__] ||= begin
      if target_enemy && target_enemy[:next]
        target_enemy.merge(kind: :pac)
      elsif target_scoring && target_scoring[:next]
        target_scoring.merge(kind: :bul)
      else
        bullet_pos, pts = target_bullet
        { next: bullet_pos, path: [bullet_pos], value: pts, kind: :def}
      end
    end
  end

  def next; target[:next];   end
  def path; target[:path];   end
  def value; target[:value]; end
  def kind; target[:kind];   end
  def clear_cache!; @_cached={};end

  private
  def can_instant_reach?(position)
    cir_pos = pacman.position.circle_area(current_speed)
    cir_pos.include?(position)
  end

  class ScoringPathFinder < PathFinder

    MAX_PROFIT = 10
    MAX_DEPTH = 20

    def initialize(grid, pacman)
      super(grid, pacman.position,
        break_if: method(:break_if),
        is_visitable: method(:is_visitable),
        move_cost: method(:move_cost),
        move_profit: method(:move_profit),
        move_size: pacman.speed
      )
    end

    def path_finder()
      @heuristic = PathFinder::Euristiques.method(:return_on_invest)
      dijkstra(
        break_if: @break_if, is_visitable: @is_visitable,
        move_profit: @move_profit, move_cost: @move_cost
      )
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
      current.profit + @grid[neighbor.to].data.to_i
    end

    def move_cost(current, neighbor)
      ((current.depth + neighbor.cost).to_f / @move_size).round
    end
  end
end
