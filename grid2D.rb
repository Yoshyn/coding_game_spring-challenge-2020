require_relative 'position'

class Grid2D
  include Enumerable

  attr_reader :width, :height

  def initialize(width, height)
    @width, @height = width, height
    @_data = Array.new(size())
  end

  def set(x,y, value)
    if (index = to_index(x,y))
      @_data[index]= value
    end
  end

  def get(x,y)
    to_index(x,y) && @_data[to_index(x,y)]
  end

  def size(); width * height; end

  def ensure_sorted!; @_data.sort!; end

  def [](position);         get(position.x,position.y);         end
  def []=(position, value); set(position.x, position.y, value); end

  def each
    return enum_for(:each) unless block_given?
    @_data.each do |value| yield(value); end
  end

  def slice(*positions); positions.map { |pos| self[pos] }.compact; end

  def include?(x,y); !!to_index(x,y); end

  def to_s(separator: false)
    cell_to_s = -> (pos, value) { "#{pos}=>#{value}" }
    max_cell_size = map { |pos, value| cell_to_s.call(pos, value).length }.max
    row_separator=""
    out = "\n"
    (0...height).each do |col|
      row_line=(0...width).map do |row|
        pos, value = Position.new(row,col), get(row, col)
        cell_to_s.call(pos, value).center(max_cell_size)
      end.join(separator ? " | " : " ")
      if separator
        row_separator ||= "| "+"-"*row_line.length + " |\n"
        out+=row_separator
        out+="| #{row_line} |\n"
      else
        out+="#{row_line}\n"
      end
    end
    out+=row_separator+"\n"
  end

  private
  def to_position(index);
    Position.new(index % width, index/width)
  end

  def to_index(x,y)
    index = (x + y * width)
    return index if x >= 0 && y >= 0 && y < height && x < width
    return nil
  end
end
