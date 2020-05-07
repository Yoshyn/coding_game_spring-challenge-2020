require_relative "core_ext/object"

class PathFinder
  def initialize(grid); @grid = grid; end

  def shortest(from, to);
    return nil unless @grid.slice(from, to).all?(&:accessible?)
    @visited, @to_visit, current_uid = {}, [[0, from, nil]], nil

    while(!@to_visit.empty? && current_uid != to)
      @to_visit.sort_by! { |dist, _| dist }
      distance, current_uid, previous_uid = @to_visit.shift
      @visited[current_uid] ||= begin
        @grid[current_uid].neighbors.each do |ngh_uid, ngh_data|
          next unless @grid[ngh_uid].accessible?
          @to_visit << [
            distance + ngh_data.distance,
            ngh_uid, current_uid ]
        end
        [distance, previous_uid]
      end
    end

    distance, res_to = @visited[to]

    return nil unless res_to
    loop do
      break if @visited[res_to].last == from
      res_to = @visited[res_to].last
    end
    {
      to: res_to,
      dir: @grid[from].neighbors[res_to].direction,
      dist: distance
    }
  end

  def longest(from, to_conditions=[]);
    to_conditions << ->(visited) {
      visited.max_by { |k,v| v.first }
    }
    return nil unless @grid[from]&.accessible?
    @visited, @to_visit, current_uid = {}, [[0, from, nil]], nil

    while(!@to_visit.empty?)
      @to_visit.sort_by! { |dist, _| dist }
      distance, current_uid, previous_uid = @to_visit.shift
      @visited[current_uid] ||= begin
        @grid[current_uid].neighbors.each do |ngh_uid, ngh_data|
          next unless @grid[ngh_uid].accessible?
          @to_visit << [
            distance + ngh_data.distance,
            ngh_uid, current_uid ]
        end
        [distance, previous_uid]
      end
    end

    res_to, (distance, _) = to_conditions.map { |method|
      method.call(@visited) }.first
    loop do
      break if @visited[res_to].last == from
      res_to = @visited[res_to].last
    end

    {
      to: res_to,
      dir: @grid[from].neighbors[res_to].direction,
      dist: distance
    }
  end

  def to_s(separator: false);
    to_display = @grid.deep_clone
    @visited.each do |distance, origin|
      to_display[distance] = origin.join('-')
    end
    to_display.to_s(separator: separator)
  end
end
