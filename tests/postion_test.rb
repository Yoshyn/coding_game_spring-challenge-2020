require "minitest/autorun"
require "pry-byebug"
require_relative "./helper"
require_relative "../position"

class PositionTest < Minitest::Test

  def test_opposed_directions
    assert_equal :north, Position.opposed(:south)
    assert_equal :south, Position.opposed(:north)
    assert_equal :east,  Position.opposed(:west)
    assert_equal :west,  Position.opposed(:east)
  end

  def test_position;
    grid = init_grid();
    position = Position.new(0,0)
    assert_equal '(x0,y0)', grid[position].data
    position.move!(:north)
    assert_equal(position, Position.new(0,-1))
    position2 = position.move(:east)
    refute_equal(position, position2)
    assert_equal(true, position != position2)
    assert_equal(position2, Position.new(1,-1))
  end

  def test_square_area;
    grid = init_grid();
    positions = Position.new(2,1).square_area(1)
    assert_equal(9, positions.count)
    assert_equal([
      [1,0],[2,0],[3,0],
      [1,1],[2,1],[3,1],
      [1,2],[2,2],[3,2]
    ].sort, positions.map(&:to_a).sort)
  end

  def test_circle_area;
    grid = init_grid();
    positions = Position.new(2,1).circle_area(1)
    assert_equal(5, positions.count)
    assert_equal([
            [2,0],
      [1,1],[2,1],[3,1],
            [2,2]
    ].sort, positions.map(&:to_a).sort)


    positions = Position.new(2,1).circle_area(2)
    assert_equal(13, positions.count)
    assert_equal([
                  [2,-1],
           [1,0], [2,0], [3,0],
    [0,1], [1,1], [2,1], [3,1], [4,1],
           [1,2], [2,2], [3,2],
                  [2,3]
    ].sort, positions.map(&:to_a).sort)
  end
end
