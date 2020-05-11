require "minitest/autorun"
require "pry-byebug"
require_relative "../core_ext/hash"
require_relative "./helper"
require_relative "../path_finder"
require_relative "../cell"
require 'benchmark'

class TestCell < Cell
  def accessible?(_ = nil ); data != '#'; end
end

class PathFinderTest < Minitest::Test

  def assert_hash_includes(hash1, hash2)
    if hash1.include?(hash2)
      assert_equal true, hash1.include?(hash2)
    else
      assert_equal hash1, hash2
    end
  end

  def test_shortest_path_finder
    data ||= [
      ['.', '.', '.', '.', '.', '.', '#', '.'],
      ['.', '#', '.', '#', '#', '.', '#', '.'],
      ['.', '#', '#', '#', '.', '.', '#', '.'],
      ['.', '#', '.', '.', '.', '.', '#', '.'],
      ['.', '#', '#', '#', '#', '.', '#', '.'],
      ['.', '.', '.', '.', '.', '.', '#', '.'],
    ]
    grid = init_grid(data, GameCell);

    assert_equal({
        next: Position.new(0,1), # dir: :north,
        depth: 1, profit: 0, cost: 1,
        path: [Position.new(0,1)]},
      PathFinder.new(grid, Position.new(0,2)).shortest_path(
        Position.new(0,1)))

    assert_equal({
        next: Position.new(1,0), # dir: :west,
        profit: 0, cost: 7, depth: 7,
        path: [
          Position.new(1,0), Position.new(0,0),
          Position.new(0,1), Position.new(0,2),
          Position.new(0,3), Position.new(0,4),
          Position.new(0,5)]},
      PathFinder.new(grid, Position.new(2,0)).shortest_path(
        Position.new(0,5)))

    assert_equal({
      next: Position.new(2,0), # dir: :north,
      profit: 0, cost: 10, depth: 10,
      path: [ Position.new(2,0), Position.new(3,0),
        Position.new(4,0), Position.new(5,0),
        Position.new(5,1), Position.new(5,2),
        Position.new(5,3), Position.new(4,3),
        Position.new(3,3), Position.new(2,3)
      ]},
      PathFinder.new(grid, Position.new(2,1)).shortest_path(
        Position.new(2,3)))

    assert_equal({
      next: Position.new(3,0), # dir: :east,
       profit: 0, cost: 9, depth: 9,
      path: [ Position.new(3,0),
        Position.new(4,0), Position.new(5,0),
        Position.new(5,1), Position.new(5,2),
        Position.new(5,3), Position.new(4,3),
        Position.new(3,3), Position.new(2,3)
      ]},
      PathFinder.new(grid, Position.new(2,0)).shortest_path(
        Position.new(2,3)))

    assert_equal(PathFinder.no_result, PathFinder.new(grid, Position.new(2,0)).shortest_path(Position.new(10,10)))

    assert_equal(PathFinder.no_result, PathFinder.new(grid, Position.new(2,0)).shortest_path(
      Position.new(1,1)))

    assert_equal(PathFinder.no_result, PathFinder.new(grid, Position.new(0,0)).shortest_path(
      Position.new(7,0)))
  end

  def test_shortest_path_finder_move_value
    data ||= [
      ['.', '.', '.', '.', '.', '.', '#', '.'],
      ['.', '#', '.', '#', '#', '.', '#', '.'],
      ['.', '#', '#', '#', '.', '.', '#', '.'],
      ['.', '#', '.', '.', '.', '.', '#', '.'],
      ['.', '#', '#', '#', '#', '.', '#', '.'],
      ['.', '.', '.', '.', '.', '.', '#', '.'],
    ]
    grid = init_grid(data, GameCell);

    assert_equal({
      next: Position.new(0,1), # dir: :north,
      profit: 0, cost: 1, depth: 1,
      path: [Position.new(0,1)] },
      PathFinder.new(grid, Position.new(0,2), move_size: 2).shortest_path(
        Position.new(0,1) )
      )

    assert_equal({
      next: Position.new(0,0), # dir: :north,
      profit: 0, cost: 1, depth: 2,
      path: [Position.new(0,1), Position.new(0,0)]},
      PathFinder.new(grid, Position.new(0,2), move_size: 2).shortest_path(
        Position.new(0,0) )
      )

    assert_equal({
      next: Position.new(0,1), # dir: :north,
      profit: 0, cost: 2, depth: 3,
      path: [Position.new(0,2), Position.new(0,1), Position.new(0,0)]},
      PathFinder.new(grid, Position.new(0,3), move_size: 2).shortest_path(
        Position.new(0,0))
      )

    assert_equal({
      next: Position.new(0,0), # dir: :north,
      profit: 0, cost: 1, depth: 3,
      path: [Position.new(0,2), Position.new(0,1), Position.new(0,0)]},
      PathFinder.new(grid, Position.new(0,3), move_size: 3).shortest_path(
        Position.new(0,0))
      )
  end

  def test_tor_shortest_path_finder
    data ||= [
      ['#', '#', '.', '.', '#', '#'],
      ['.', '.', '.', '.', '.', '.'],
      ['#', '#', '.', '#', '#', '#'],
    ]
    grid = init_tor_grid(data, GameCell);

    assert_equal({
      next: Position.new(0,1), # dir: :west,
      profit: 0, cost: 2, depth: 2,
      path: [Position.new(0,1), Position.new(5,1)]
    },
      PathFinder.new(grid, Position.new(1,1)).shortest_path(
        Position.new(5,1)))

    grid[Position.new(0,1)].data = '#'
    assert_equal({
      next: Position.new(2,1), # dir: :east,
      profit: 0, cost: 4, depth: 4,
      path: [
        Position.new(2,1), Position.new(3,1),
        Position.new(4,1), Position.new(5,1)
      ]},
      PathFinder.new(grid, Position.new(1,1)).shortest_path(
        Position.new(5,1)))
  end

  def test_longest_path_finder
    data ||= [
      ['.', '#', '.', '.', '.', '.', '#', '.' ],
      ['.', '#', '.', '#', '#', '.', '#', '.' ],
      ['.', '#', '#', '#', '.', '.', '#', '.' ],
      ['.', '#', '#', '.', '.', '.', '#', '#' ],
      ['.', '#', '#', '#', '#', '.', '#', '#' ],
      ['.', '#', '.', '.', '#', '.', '#', '.' ],
    ]
    grid = init_grid(data, TestCell);

    assert_equal(PathFinder.no_result,
      PathFinder.new(grid, Position.new(7,5)).longest_path)

    assert_equal({
      next: Position.new(3,5), # dir: :south,
      profit: 1, depth: 1, cost: 1,
      path: [Position.new(3,5)]},
      PathFinder.new(grid, Position.new(2,5)).longest_path)

    assert_equal({
      next: Position.new(0,2), # dir: :south,
      profit: 4, depth: 4, cost: 4,
      path: [
        Position.new(0,2), Position.new(0,3),
        Position.new(0,4), Position.new(0,5)
      ]},
      PathFinder.new(grid, Position.new(0,1)).longest_path)

    grid[Position.new(1,0)].data = '.'

    ## skip thisSee test_longest_path_finder_loop
    # assert_hash_includes(
    #   PathFinder.new(grid, Position.new(0,1)).longest_path,
    #   { next: Position.new(0,0), depth: 13, cost: 13 } #dir: :north
    # )

    grid[Position.new(1,0)].data = '#'
    grid[Position.new(0,0)].set_neighbor(Position.new(7,0), 0, :west)

    assert_hash_includes(
      PathFinder.new(grid, Position.new(0,1)).longest_path,
      { next: Position.new(0,2), depth: 4 } #dir: :south
    )

    grid[Position.new(0,0)].get_neighbor(Position.new(7,0)).cost = 2

    assert_hash_includes(
      PathFinder.new(grid, Position.new(0,1), move_size: 1).longest_path,
      { next: Position.new(0,0) } #dir: :north
    )

    assert_hash_includes(
      PathFinder.new(grid, Position.new(0,1), move_size: 3).longest_path,
      { next: Position.new(7,0) } #dir: :north
    )
  end

  # TODO : solve this two horrible problem
  # One solution can be to make a crow fly
  def test_longest_path_finder_loop
    skip("This is an horrible probleme !")
    data ||= [
      ['.', '.', '.', '#' ],
      ['.', '#', '.', '#' ],
      ['#', '.', '.', '#' ],
      ['#', '.', '.', '#' ],
      ['#', '#', '.', '#' ]
    ]
    grid = init_grid(data, TestCell);
    assert_hash_includes(
      PathFinder.new(grid, Position.new(0,0)).longest_path,
      { next: Position.new(1,0), depth: 8, cost: 8 }
    )
    data ||= [
      ['#', '.', '.', '.',],
      ['#', '.', '#', '.',],
      ['#', '.', '.', '#',],
      ['#', '.', '.', '#',],
      ['#', '.', '#', '#',]
    ]
    grid = init_grid(data, TestCell);
    assert_hash_includes(
      PathFinder.new(grid, Position.new(3,0)).longest_path,
      { next: Position.new(1,0), depth: 8, cost: 8 }
    )
  end

  def test_longest_path_finder_max_depth
    data ||= [
      ['.', '#'],
      ['.', '#'],
      ['.', '#'],
      ['.', '#'],
      ['.', '#'],
      ['.', '.'],
    ]
    grid = init_grid(data, TestCell);

    assert_equal({
      next: Position.new(0,0),  # dir: :north,
      profit: 1, depth: 1, cost: 1,
      path: [ Position.new(0,0) ]},
      PathFinder.new(grid, Position.new(0,1)).longest_path(max_depth: 1))

    assert_equal({
      next: Position.new(0,2), # dir: :north,
      profit: 2, depth: 2, cost: 2,
      path: [ Position.new(0,2), Position.new(0,3) ]},
      PathFinder.new(grid, Position.new(0,1)).longest_path(max_depth: 2))
  end

  # # # Max cost is only to reduce the possibility count.
  # # # Like max_depth but max_depth is included in SPF
  def scoring_path_finder(grid, from,
    move_size: 1,
    max_cost: Float::INFINITY,
    max_depth: Float::INFINITY)

    break_if = -> (current, to) {
      current && (current.cost > max_cost || current.depth >= max_depth)
    }
    is_visitable = -> (cell) { cell.accessible? }
    move_profit  = -> (current, neighbor) {
      current.profit + grid[neighbor.to].data.to_i
    }
    move_cost = -> (current, neighbor) {
      ((current.depth + neighbor.cost).to_f / move_size).round
    }
    pf = PathFinder.new(grid, from,
      break_if: break_if,
      is_visitable: is_visitable,
      move_profit: move_profit,
      move_cost: move_cost,
      move_size: move_size
    )
    pf.longest_path(max_depth: max_depth)
  end

  def test_scoring_path_finder
    data ||= [
      ['#', '#', '2', '2', '2', '#'],
      ['5', '@', '1', '1', '1', '1'],
      ['#', '#', '1', '1', '#', '#'],
    ]
    grid = init_grid(data, TestCell);

    assert_equal({
      next: Position.new(0,1),
      profit: 5, depth: 1, cost: 1,
      path: [ Position.new(0,1) ]},
      scoring_path_finder(grid, Position.new(1,1)))

    assert_equal({
      next: Position.new(0,1),
      profit: 5, depth: 1, cost: 1,
      path: [ Position.new(0,1) ]},
      scoring_path_finder(grid, Position.new(1,1), move_size: 2))

    grid[Position.new(3,1)].data = "8"
    assert_equal({
      next: Position.new(0,1),
      profit: 5, depth: 1, cost: 1,
      path: [ Position.new(0,1) ]},
      scoring_path_finder(grid, Position.new(1,1)))

    assert_equal({
      next: Position.new(3,1),
      profit: 9, cost: 1, depth: 2,
      path: [ Position.new(2,1), Position.new(3,1)]},
      scoring_path_finder(grid,
        Position.new(1,1), move_size: 2))
  end

  def test_performance
    data ||= [
      ['.', '#', '.', '.', '.', '.', '#', '.' ]*4,
      ['.', '.', '.', '#', '#', '.', '#', '.' ]*4,
      ['.', '#', '#', '#', '.', '.', '.', '.' ]*4,
      ['.', '#', '#', '.', '.', '.', '#', '#' ]*4,
      ['.', '#', '#', '#', '#', '.', '.', '#' ]*4,
      ['.', '.', '.', '.', '.', '.', '#', '.' ]*4,
    ]*5
    grid = init_grid(data, TestCell);

    pf = nil
    max_value = 30 #ms
    running_time = Benchmark.realtime {
      10.times do
        pf = PathFinder.new(grid, Position.new(0,0))
        pf = pf.shortest_path(Position.new(30,28))
        # pf = PathFinder.new(grid,  Position.new(rand() + 15 %grid.width,rand() + 15 %grid.height)).longest_path(max_depth: 10)
      end
    } * 1000
    puts "pf : #{pf.except(:path)}"
    refute_operator running_time, :>, max_value
  end
end


# TODO : shortest & longest : remove le is Visitable avec cell.accessible ?
