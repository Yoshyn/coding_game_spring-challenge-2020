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

    assert_equal({
        next: Position.new(0,1),
        cost: 1, # dir: :north,
        path: [Position.new(0,1)]},
      PathFinder.new(grid, Position.new(0,2)).shortest_path(
        Position.new(0,1)))

    assert_equal({
        next: Position.new(1,0),
        cost: 7, # dir: :west,
        path: [
          Position.new(1,0), Position.new(0,0),
          Position.new(0,1), Position.new(0,2),
          Position.new(0,3), Position.new(0,4),
          Position.new(0,5)]},
      PathFinder.new(grid, Position.new(2,0)).shortest_path(
        Position.new(0,5)))

    assert_equal({
      next: Position.new(2,0),
      cost: 10, # dir: :north,
      path: [ Position.new(2,0), Position.new(3,0),
        Position.new(4,0), Position.new(5,0),
        Position.new(5,1), Position.new(5,2),
        Position.new(5,3), Position.new(4,3),
        Position.new(3,3), Position.new(2,3)
      ]},
      PathFinder.new(grid, Position.new(2,1)).shortest_path(
        Position.new(2,3)))

    assert_equal({
      next: Position.new(3,0),
      cost: 9, # dir: :east,
      path: [ Position.new(3,0),
        Position.new(4,0), Position.new(5,0),
        Position.new(5,1), Position.new(5,2),
        Position.new(5,3), Position.new(4,3),
        Position.new(3,3), Position.new(2,3)
      ]},
      PathFinder.new(grid, Position.new(2,0)).shortest_path(
        Position.new(2,3)))

    assert_equal(PathFinder.unfind_result, PathFinder.new(grid, Position.new(2,0)).shortest_path(Position.new(10,10)))

    assert_equal(PathFinder.unfind_result, PathFinder.new(grid, Position.new(2,0)).shortest_path(
      Position.new(1,1)))

    assert_equal(PathFinder.unfind_result, PathFinder.new(grid, Position.new(0,0)).shortest_path(
      Position.new(7,0)))
  end

  def test_shortest_path_finder_move_2
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
      next: Position.new(0,1),
      cost: 1, # dir: :north,
      path: [Position.new(0,1)] },
      PathFinder.new(grid, Position.new(0,2)).shortest_path(
        Position.new(0,1), move_size: 2 )
      )

    assert_equal({
      next: Position.new(0,0),
      cost: 1, # dir: :north,
      path: [Position.new(0,1), Position.new(0,0)]},
      PathFinder.new(grid, Position.new(0,2)).shortest_path(
        Position.new(0,0), move_size: 2 )
      )

    assert_equal({
      next: Position.new(0,1),
      cost: 2, # dir: :north,
      path: [Position.new(0,2),
        Position.new(0,1), Position.new(0,0)]},
      PathFinder.new(grid, Position.new(0,3)).shortest_path(
        Position.new(0,0), move_size: 2 )
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
      next: Position.new(0,1),
      cost: 2, # dir: :west,
      path: [Position.new(0,1), Position.new(5,1)]},
      PathFinder.new(grid, Position.new(1,1)).shortest_path(
        Position.new(5,1)))

    grid[Position.new(0,1)].data = '#'
    assert_equal({
      next: Position.new(2,1),
      cost: 4, # dir: :east,
      path: [
        Position.new(2,1), Position.new(3,1),
        Position.new(4,1), Position.new(5,1)
      ]},
      PathFinder.new(grid, Position.new(1,1)).shortest_path(
        Position.new(5,1)))
  end
end
