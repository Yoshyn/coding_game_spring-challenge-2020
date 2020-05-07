require_relative 'position'

class Grid2D
  include Enumerable

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

  def clone;
    copy = Grid2D.new(@width, @height)
    copy.instance_variable_set(:@_data, @_data.clone)
    return copy
  end

  def size();   @width * @height; end
  def width();  @width;           end
  def height(); @height;          end

  def [](position);         get(position.x,position.y);         end
  def []=(position, value); set(position.x, position.y, value); end

  def each
    return enum_for(:each) unless block_given?
    @_data.each_with_index do |value, index|
      yield(to_position(index), value)
    end
  end

  def slice(*positions); positions.map { |pos| self[pos] }.compact; end

  def include?(x,y); !!to_index(x,y); end

  def to_s
    cell_to_s = -> (pos, value) { "#{pos} => #{value}" }
    max_cell_size = map { |pos, value| cell_to_s.call(pos, value).length }.max
    row_separator=nil
    out = "\n"
    (0...@height).each do |col|
      row_line=(0...@width).map do |row|
        pos, value = Position.new(row,col), get(row, col)
        cell_to_s.call(pos, value).center(max_cell_size)
      end.join(" | ")
      row_separator ||= "| "+"-"*row_line.size + " |\n"
      out+=row_separator
      out+="| #{row_line} |\n"
    end
    out+=row_separator+"\n"
    out
  end

  private
  def to_position(index);
    Position.new(index % width, index/@width)
  end

  def to_index(x,y)
    index = (x + y * @width)
    return index if x >= 0 && y >= 0 && y < @height && x < @width
    return nil
  end
end
