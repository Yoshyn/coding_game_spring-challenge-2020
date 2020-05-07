require "minitest/autorun"
require "pry-byebug"
require_relative "./helper"
require_relative "../path_finder"
require_relative "../cell"

class TestCell < Cell
  def accessible?(); data != '#'; end
end

class PathFinderTest < Minitest::Test

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

    assert_equal({ to: Position.new(1,0), dir: :west, dist: 7 },
      PathFinder.new(grid).shortest(
        Position.new(2,0), Position.new(0,5))
      )

    assert_equal({ to: Position.new(2,0), dir: :north, dist: 10 },
      PathFinder.new(grid).shortest(
        Position.new(2,1), Position.new(2,3))
      )

    assert_equal({ to: Position.new(3,0), dir: :east, dist: 9 },
      PathFinder.new(grid).shortest(
        Position.new(2,0), Position.new(2,3))
      )

    assert_nil(PathFinder.new(grid).shortest(
      Position.new(2,0), Position.new(10,10)))

    assert_nil(PathFinder.new(grid).shortest(
      Position.new(1,1), Position.new(0,0)))

    assert_nil(PathFinder.new(grid).shortest(
      Position.new(2,0),
      Position.new(1,1)))

    assert_nil(PathFinder.new(grid).shortest(
      Position.new(0,0),
      Position.new(7,0)))
  end

  def test_longest_path_finder
    data ||= [
      ['.', '#', '.', '.', '.', '.', '#', '.'],
      ['.', '#', '.', '#', '#', '.', '#', '.'],
      ['.', '#', '#', '#', '.', '.', '#', '.'],
      ['.', '#', '#', '.', '.', '.', '#', '.'],
      ['.', '#', '#', '#', '#', '.', '#', '.'],
      ['.', '#', '.', '.', '.', '.', '#', '.'],
    ]
    grid = init_grid(data, GameCell);

    assert_equal({ to: Position.new(0,2), dir: :south, dist: 4 },
      PathFinder.new(grid).longest(
        Position.new(0,1))
      )

    grid[Position.new(1,0)].data = '.'

    assert_equal({ to: Position.new(0,0), dir: :north, dist: 14 },
      PathFinder.new(grid).longest(
        Position.new(0,1))
      )

    grid[Position.new(1,0)].data = '#'
    grid[Position.new(0,0)].set_neighbor(Position.new(7,0), 2, :west)

    assert_equal({ to: Position.new(0,0), dir: :north, dist: 8 },
      PathFinder.new(grid).longest(
        Position.new(0,1))
      )
  end

  def test_tor_shortest_path_finder
    data ||= [
      ['#', '#', '.', '.', '#', '#'],
      ['.', '.', '.', '.', '.', '.'],
      ['#', '#', '.', '#', '#', '#'],
    ]
    grid = init_tor_grid(data, GameCell);

    assert_equal({ to: Position.new(0,1), dir: :west, dist: 2 },
      PathFinder.new(grid).shortest(
        Position.new(1,1), Position.new(5,1))
      )

    grid[Position.new(0,1)].data = '#'
    assert_equal({ to: Position.new(2,1), dir: :east, dist: 4 },
      PathFinder.new(grid).shortest(
        Position.new(1,1), Position.new(5,1))
      )
  end
end
