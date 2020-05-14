require_relative "core_ext/object"
require 'set'
require 'benchmark'

class PathFinder
  class StepList
    include Comparable
    attr_reader :previous, :uid, :depth, :cost, :profit

    def initialize(path_finder, previous, uid, profit, cost, depth);
      @previous, @uid = previous, uid
      @profit, @cost, @depth = profit, cost, depth
      @origin = path_finder.origin
      @heuristic_method = path_finder.heuristic
    end

    def <=>(other); heuristic <=> other.heuristic; end

    def heuristic
      @_heuristic ||= @heuristic_method.call(@origin, self)
    end

    def to_a; [previous, uid, profit, cost, depth]; end
    def to_s; "[#{previous.uid}=>#{uid}|#{heuristic}|#{profit}|#{cost}|#{depth}]" end
  end

  module Euristiques
    class ComparableArray < Array; include Comparable; end

    def self.return_on_invest(_, step)
      roi = (step.cost > 0) ? (step.profit-step.cost)/step.cost.to_f : -1
      ComparableArray.new([roi, step.profit])
    end

    def self.oil_stain(_, step); -step.depth; end

    def self.crow_flies(origin, step);
      -origin.distance(step.uid).to_i
    end
  end

  attr_reader :origin, :heuristic

  def initialize(grid, origin, break_if: nil, is_visitable: nil,
    move_cost: nil, move_profit: nil, move_size: 1)
    @grid, @origin, @move_size = grid, origin, move_size
    @break_if, @is_visitable = break_if, is_visitable
    @move_cost, @move_profit = move_cost, move_profit
  end

  # Shortest mean that we go first on low scoring
  def shortest_path(to)
    return self.class.no_result unless @is_visitable.call(@grid[to])
    @heuristic = PathFinder::Euristiques.method(:oil_stain)
    dijkstra(to: to,
      break_if: @break_if || -> (current,to) { current.uid == to }
    )
    generate_result(to)
  end

  # Shortest mean that we go first on high scoring
  def longest_path(max_depth: Float::INFINITY)
    @heuristic = PathFinder::Euristiques.method(:return_on_invest)
    dijkstra(
      break_if:    @break_if    || -> (current, to) { current.depth > max_depth },
      move_profit: @move_profit || -> (current, neighbor) { current.cost + neighbor.cost },
      move_cost:   @move_cost   || -> (current, neighbor) { current.depth + 1 },
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
    path, to_step = [], @visited[to]
    return self.class.no_result if to_step.nil? || to == @origin

    profit, cost, depth = to_step.profit, to_step.cost, to_step.depth
    while(to_step.uid != @origin)
      path.unshift(to_step.uid)
      to_step = to_step.previous
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
    to_visit = [ StepList.new(self, nil, @origin, 0, 0, 0) ]
    loop do
      current = to_visit.pop;
      # one_loop = Benchmark.realtime {
        @visited[current.uid] ||= begin
          @grid[current.uid].neighbors.each do |neighbor|
            next if !is_visitable.call(@grid[neighbor.to])
            next_step = nil
            next_step = StepList.new(self, current, neighbor.to,
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
        # } * 1000
        # STDERR.puts "one_loop take #{one_loop}ms | #{@visited.size()} | #{to_visit.count}"
        # binding.pry if one_loop > 10
      break if to_visit.empty? || break_if.call(current, to)
    end
  end
end
