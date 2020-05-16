require_relative 'path_finder'

class ScoringPathFinder < PathFinder

  MAX_PROFIT = Float::INFINITY
  MAX_DEPTH = Float::INFINITY

  def initialize(grid, pacman, max_profit: nil, max_depth: nil)
    @pacman = pacman
    @max_profit = max_profit || MAX_PROFIT
    @max_depth = max_depth || MAX_DEPTH
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
    dijkstra(
      break_if: @break_if, is_visitable: @is_visitable,
      move_profit: @move_profit, move_cost: @move_cost
    )

    # Max by [roi, ratio, depth (positive)]
    to = @visited.max { |(_, v1), (_, v2)|
      roi, ratio, depth = v1.heuristic
      roi2, ratio2, depth2 = v2.heuristic
      [roi, ratio, depth.abs] <=> [roi2, ratio2, depth2.abs]
      # v1.heuristic <=> v2.heuristic
    }.first

    generate_result(to)
  end

  private

  def game; Game.instance; end

  def is_visitable(cell); cell.accessible_for?(@pacman); end

  def break_if(current, to);
    (current.profit > @max_profit || current.depth >= @max_depth)
  end

  def move_profit(current, neighbor)
    next_profit = game.raw_visible_pellets[neighbor.to].to_i
    if game.turn_targeted_pos.include?(neighbor.to)
      # STDERR.puts "ALREADY TARGERTED #{neighbor.to}!"
      next_profit = 0
    elsif @pacman._positions.include?(neighbor.to)
      # STDERR.puts "ALREADY VISITED BY ME #{neighbor.to}!"
      next_profit = -2
    elsif next_profit > 1
      next_profit = 100
      # STDERR.puts "BIG BULLETS FOUND for(#{@pacman}) at #{neighbor.to}"
    elsif @pacman.turn_visible_pellets.include?(neighbor.to)
      # STDERR.puts "PAC_VISIBLE BULLET for(#{@pacman}) at #{neighbor.to}"
      next_profit = next_profit * 5
    end

    current.profit + next_profit
  end

  def move_cost(current, neighbor)
    ((current.cost.to_f + neighbor.cost) / @move_size).round
  end
end
