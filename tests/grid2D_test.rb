require "minitest/autorun"
require "pry-byebug"
require_relative "./helper"

class Grid2DTest < Minitest::Test

  def test_size_grid
    grid = init_grid();
    assert_equal 4*3, grid.size()
    assert_equal 4,   grid.width()
    assert_equal 3,   grid.height()
  end

  def test_set_get;
    grid = init_grid();
    assert_equal '(x0,y0)', grid.get(0,0).data
    assert_equal '(x0,y1)', grid.get(0,1).data
    assert_equal '(x0,y2)', grid.get(0,2).data
    assert_equal '(x1,y0)', grid.get(1,0).data
    assert_equal '(x1,y1)', grid.get(1,1).data
    assert_equal '(x1,y2)', grid.get(1,2).data
    assert_equal '(x2,y2)', grid.get(2,2).data
    assert_nil grid.get(2,3)
    assert_nil grid.get(-1,0)
  end

  def test_neighbors;
    grid = init_grid();
    neighbors_data = ->(x,y) {
      positions = grid.get(x,y).neighbors.keys
      grid.slice(*positions).map(&:data).sort
    }

    assert_equal ['(x1,y0)', '(x0,y1)'].sort, neighbors_data.call(0,0)
    assert_equal ['(x1,y2)', '(x0,y1)'].sort, neighbors_data.call(0,2)
    assert_equal ['(x1,y0)', '(x0,y1)', '(x2,y1)', '(x1,y2)'].sort, neighbors_data.call(1,1)
    assert_equal ['(x0,y2)','(x1,y1)','(x2,y2)'].sort, neighbors_data.call(1,2)
    assert_equal ['(x1,y1)', '(x2,y0)', '(x2,y2)', '(x3,y1)'].sort, neighbors_data.call(2,1)
    assert_equal ['(x2,y0)', '(x3,y1)'].sort, neighbors_data.call(3,0)
  end
end
