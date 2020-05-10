require_relative "core_ext/object"

class Step
  include Comparable
  attr_reader :from, :to, :cost

  def initialize(from, to, cost);
    @from, @to, @cost = from, to, cost;
  end

  def <=>(other); cost <=> other.cost; end
  def to_a; [from, to, cost];end
end

class PathFinder

  def initialize(grid, from, unit_context = nil);
    @grid, @from, @unit_context = grid, from, unit_context;
    @visited = {}
  end

  def self.unfind_result;
    { next: nil, dir: nil, dist: 0, path: [] }
  end

  def shortest_path(to, move_size: 1)
    dijkstra(to)

    positions, (res_to, cost) = [to], @visited[to]
    return self.class.unfind_result unless res_to

    loop do
      break if res_to == @from
      positions << res_to
      res_to = @visited[res_to].first
    end
    fetch_key = (move_size <= positions.size) ? -move_size : -1
    {
      next: positions[fetch_key],
      path: positions.reverse(),
      cost: (cost / move_size.to_f).round
    }
  end

  def to_s(separator: false);
    to_display = @grid.deep_clone
    @visited.each do |cost, origin|
      to_display[cost] = origin.join('-')
    end
    to_display.to_s(separator: separator)
  end

  private

  def dijkstra(to);
    return self.class.unfind_result unless @grid[to]&.accessible?(@unit_context)
    @visited, current = {}, nil;
    to_visit = [ Step.new(@from, to, 0) ]
    while(!to_visit.empty? && current&.from != to)
      to_visit.sort!
      current = to_visit.shift
      @visited[current.from] ||= begin
        @grid[current.from].neighbors.each do |ngh_uid, ngh_data|
          next unless @grid[ngh_uid].accessible?(@unit_context)
          to_visit << Step.new(ngh_uid, current.from,
            current.cost + ngh_data.cost)
        end
        [current.to, current.cost]
      end
    end
  end

  def maximise_cost(max_cost: 10, max_depth: 5);
    @visited, to_visit, current = {}, [[@from, nil, 0]], nil;
    while(!to_visit.empty? && current != to)
      to_visit.sort_by! { |_, _, cost| cost }
      current, previous_uid, cost = to_visit.last
      @visited[current] ||= begin
        @grid[current].neighbors.each do |ngh_uid, ngh_data|
          next unless @grid[ngh_uid].accessible?(@unit_context)
          to_visit << [ ngh_uid, current,
            cost + ngh_data.cost ]
        end
        [previous_uid, cost]
      end
    end
  end
end
