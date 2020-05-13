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

  def test_tor_position;
    data ||= [
      ['(x0,y0)', '(x1,y0)', '(x2,y0)', '(x3,y0)'],
      ['(x0,y1)', '(x1,y1)', '(x2,y1)', '(x3,y1)'],
      ['(x0,y2)', '(x1,y2)', '(x2,y2)', '(x3,y2)'],
      ['(x0,y3)', '(x1,y3)', '(x2,y3)', '(x3,y3)'],
      ['(x0,y4)', '(x1,y4)', '(x2,y4)', '(x3,y4)'],
    ]
    grid = init_grid(data);
    position = TorPosition.new(0,0, grid.width, grid.height)
    assert_equal '(x0,y0)', grid[position].data
    position.move!(:north)
    assert_equal '(x0,y4)', grid[position].data

    max_x = grid.width
    max_y = grid.height

    assert_equal [0,0], TorPosition.new(0,0, max_x, max_y).to_a
    assert_equal [2,2], TorPosition.new(2,2, max_x, max_y).to_a
    assert_equal [0,4], TorPosition.new(0,-1, max_x, max_y).to_a
    assert_equal [0,3], TorPosition.new(0,-2, max_x, max_y).to_a
    assert_equal [3,0], TorPosition.new(-1,0, max_x, max_y).to_a

    tp    = TorPosition.new(0,0, max_x, max_y)
    other = TorPosition.new(0,1, max_x, max_y)
    assert_equal 1, tp.distance(other)
    other.move!(:south)
    assert_equal 2, tp.distance(other)
    other.move!(:south)
    assert_equal 2, tp.distance(other)
    other.move!(:south)
    assert_equal 1, tp.distance(other)

    tp    = TorPosition.new(0,0, max_x, max_y)
    other = TorPosition.new(1,0, max_x, max_y)
    assert_equal 1, tp.distance(other)
    other.move!(:east)
    assert_equal 2, tp.distance(other)
    other.move!(:east)
    assert_equal 1, tp.distance(other)

    tp    = TorPosition.new(0,0, max_x, max_y)
    other = TorPosition.new(1,1, max_x, max_y)
    assert_equal 1.5, tp.distance(other).ceil(1)
    other = TorPosition.new(3,4, max_x, max_y)
    assert_equal 1.5, tp.distance(other).ceil(1)
  end
end
