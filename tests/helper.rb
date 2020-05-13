require_relative "../grid2D"
require_relative "../position"
require_relative "../cell"

def init_grid(data = nil, cell_klass = nil)
  data ||= [
    ['(x0,y0)', '(x1,y0)', '(x2,y0)', '(x3,y0)'],
    ['(x0,y1)', '(x1,y1)', '(x2,y1)', '(x3,y1)'],
    ['(x0,y2)', '(x1,y2)', '(x2,y2)', '(x3,y2)'],
  ]

  width = data.map(){ |row| row.length }.max
  height = data.length
  grid = Grid2D.new(width, height)

  data.each_with_index do |row, row_index|
    row.each_with_index.each do |value, col_index|
      c_pos = Position.new(col_index, row_index)
      cell = (cell_klass || Cell).new(c_pos, value)
      Position::DIRECTIONS.each do |dir|
        dir_pos = c_pos.move(dir)
        cell.set_neighbor(dir_pos, 1, dir) if grid.include?(dir_pos.x, dir_pos.y)
      end
      grid[c_pos] = cell
    end
  end
  grid
end

def init_tor_grid(data = nil, cell_klass = nil)
  data ||= [
    ['X', 'X', '.', '.'],
    ['.', '.', '.', '.'],
    ['X', 'X', '.', 'X'],
  ]

  width = data.map(){ |row| row.length }.max
  height = data.length
  grid = Grid2D.new(width, height)

  data.each_with_index do |row, row_index|
    row.each_with_index.each do |value, col_index|
      c_pos = TorPosition.new(col_index, row_index, width, height)
      cell = (cell_klass || Cell).new(c_pos, value)
      Position::DIRECTIONS.each do |dir|
        dir_pos = c_pos.move(dir)
        cell.set_neighbor(dir_pos, 1, dir) if grid.include?(dir_pos.x, dir_pos.y)
      end
      grid[c_pos] = cell
    end
  end
  grid
end
