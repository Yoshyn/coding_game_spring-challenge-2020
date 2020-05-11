require_relative "core_ext/object"
require 'set'

class PathFinder
  class Step
    include Comparable
    attr_reader :from, :to, :depth, :cost, :profit

    def initialize(path_finder, from, to, profit, cost, depth);
      @from, @to = from, to
      @profit, @cost, @depth = profit, cost, depth
      @heuristic_method = path_finder.heuristic
    end

    def <=>(other); heuristic <=> other.heuristic; end

    def heuristic
      @_heuristic ||= @heuristic_method.call(profit, cost, depth)
    end

    def to_a; [from, to, profit, cost, depth]; end
    def to_s; "[#{from}=>#{to}|#{heuristic}|#{profit}|#{cost}|#{depth}]" end
  end

  module Euristiques
    class ComparableArray < Array; include Comparable; end

    def self.roi(profit, cost, _)
      roi = (cost > 0) ? (profit-cost)/cost.to_f : -1
      ComparableArray.new([roi, profit])
    end

    def self.oil_stain(_, _, depth); -depth; end
  end

  attr_reader :heuristic

  def initialize(grid, from, break_if: nil, is_visitable: nil,
    move_cost: nil, move_profit: nil, move_size: 1)
    @grid, @from, @move_size = grid, from, move_size
    @break_if, @is_visitable = break_if, is_visitable
    @move_cost, @move_profit = move_cost, move_profit
  end

  # Shortest mean that we go first on low scoring
  def shortest_path(to)
    return self.class.no_result unless @grid[to]&.accessible?(@unit_context)
    @heuristic = PathFinder::Euristiques.method(:oil_stain)
    dijkstra(
      to: to,
      break_if:       @break_if     || -> (current,to) { current&.from == to },
      is_visitable:   @is_visitable || -> (cell) { cell.accessible?(@unit_context) }
    )
    generate_result(to)
  end

  # Shortest mean that we go first on high scoring
  def longest_path(max_depth: Float::INFINITY)
    @heuristic = PathFinder::Euristiques.method(:roi)
    dijkstra(
      break_if:       @break_if     || -> (current,to) { current && (current.depth > max_depth) },
      is_visitable:   @is_visitable || -> (cell) { cell.accessible?(@unit_context) },
      move_profit:    @move_profit  || -> (current, neighbor) { current.cost + neighbor.cost },
      move_cost:      @move_cost    || -> (current, neighbor) { current.depth + 1 },
    )
    # Max by [ROI, cost] with spaceship operator
    to = @visited.max { |(_, v1), (_, v2)|
      v1 <=> v2
    }.first

    generate_result(to)
  end

  def to_s(separator: false);
    to_display = @grid.deep_clone
    @visited.each do |origin, cost|
      to_display[origin] = cost
    end
    to_display.to_s(separator: separator)
  end

  private

  def self.no_result;
    { next: nil, profit: 0, cost: 0, depth: 0, path: [] }
  end

  def generate_result(to)
    path, pf_step = [to], @visited[to]
    return self.class.no_result if pf_step.nil? || to == @from

    profit, cost, depth = pf_step.profit, pf_step.cost, pf_step.depth
    while(pf_step.to != @from)
      path.unshift(pf_step.to)
      pf_step = @visited[pf_step.to]
    end

    fetch_key = (@move_size < path.length) ? @move_size-1 : -1
    {
      next: path[fetch_key],
      profit: profit, cost: cost,
      depth: depth,
      path: path
    }
  end

  def dijkstra(to: nil,
    break_if:       @break_if     || -> (from, to) { false },
    is_visitable:   @is_visitable || -> (cell) { true },
    move_profit:    @move_profit  || -> (current, neighbor) { 0 },
    move_cost:      @move_cost    || -> (current, neighbor) {
      ((current.depth + neighbor.cost).to_f / @move_size).round
    }
  )
    @visited, current = {}, nil;
    to_visit = [ Step.new(self, @from, to, 0, 0, 0) ]
    while(!to_visit.empty? && !break_if.call(current, to))
      current = to_visit.pop;
      @visited[current.from] ||= begin
        @grid[current.from].neighbors.each do |neighbor|
          next if !is_visitable.call(@grid[neighbor.to])
          next_step = Step.new(self, neighbor.to, current.from,
            move_profit.call(current, neighbor),
            move_cost.call(current, neighbor),
            current.depth + 1)
          insert_at = to_visit.bsearch_index { |step|
            step.heuristic >= next_step.heuristic
          } || -1
          to_visit.insert(insert_at, next_step)
        end
        current
      end
    end
  end
end


# TODO :
#  1?) Replace Set if there's one equal and we go a better heuristic
#  2?) change the ponderation of neighbor ? add anotheir indicator.
