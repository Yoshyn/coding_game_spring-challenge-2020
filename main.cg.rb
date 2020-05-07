class Cell
  Neighbor = Struct.new(:distance, :direction) do
    def <=>(other); self.distance <=> other.distance; end
  end

  attr_accessor :uid, :data, :neighbors

  def initialize(uid, data);
    @uid, @data, @neighbors = uid, data, {}
  end

  def set_neighbor(uid, distance, direction)
    @neighbors[uid] = Neighbor.new(distance, direction)
  end

  def accessible?(); true;                end
  def <=>(other);    data <=> other.data; end
  def to_s;          data.to_s;           end
end

class GameCell < Cell
  def accessible?(); data != 'X'; end
end
class Position

  DIRECTIONS= %i(north east south west)

  class Radius
    include Enumerable
    def initialize(value); @value =value; end
    def each
      (-@value..@value).each do |i|
        (-@value..@value).each do |j|
          yield(Position.new(i,j))
        end
      end
    end
  end

  attr_accessor :x, :y

  def initialize(x,y); @x,@y=x,y; end

  def self.opposed(direction);
    DIRECTIONS[(DIRECTIONS.index(direction) + 2) % 4]
  end

  def move_north!(cell=1); @y-=cell; self; end
  def move_east! (cell=1); @x+=cell; self; end
  def move_south!(cell=1); @y+=cell; self; end
  def move_west! (cell=1); @x-=cell; self; end

  def move!(direction, cell=1)
    __send__("move_#{direction}!", cell);
  end

  def move(direction, cell=1)
    Position.new(x,y).move!(direction, cell)
  end

  def +(other)
    self.x = x + other.x; self.y = y + other.y; self
  end
  def -(other)
    self.x = x - other.x; self.y = y - other.y; self
  end

  def ==(other);    x == other.x && y == other.y; end
  def !=(other);    !(self == other);             end

  def hash;         to_a.hash;                    end
  def eql?(other);  self == other;                end

  def <(other); x < other.x || (x == other.x && y < other.y); end
  def >(other); x > other.x || (x == other.x && y > other.y); end

  def circle_area(radius);
    Radius.new(radius).map do |pos|
      pos + self if (pos.x.abs + pos.y.abs) <= radius
    end.compact
  end

  def square_area(radius);
    Radius.new(radius).map { |pos| pos + self }
  end

  def to_s; "(#{x},#{y})";  end
  def to_a; [x,y];          end
end

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

  def to_s;
    to_display = @grid.clone
    @visited.each do |distance, origin|
      to_display[distance] = origin
    end
    to_display.to_s
  end
end
require 'singleton'
class Array
  def self.wrap(object)
    if object.nil?
      []
    elsif object.respond_to?(:to_ary)
      object.to_ary || [object]
    else
      [object]
    end
  end
end

module AttrHistory
  def attr_historized(*attributes)
    Array.wrap(attributes).each do |attribute|
      method_key = "_#{attribute}s"
      store_key  = "@_#{method_key}"

      define_method(method_key) do
        attrs = instance_variable_get(store_key)
        attrs || instance_variable_set(store_key, [])
      end

      define_method(attribute) do
        __send__(method_key).last
      end

      define_method("#{attribute}=") do |value|
        __send__(method_key) << value
      end

      define_method("#{attribute}_changed?") do
        values = __send__(method_key)
        return false if values.count < 2
        return values[-1] != values[-2]
      end

      define_method("#{attribute}_decreased?") do
        values = __send__(method_key)
        !!(values[-1] && values[-2] && values[-1] < values[-2])
      end

      define_method("#{attribute}_increased?") do
        values = __send__(method_key)
        !!(values[-1] && values[-2] && values[-1] > values[-2])
      end

      define_method("#{attribute}_already_changed?") do
        __send__(method_key).uniq.count > 1
      end
    end
  end
end

class Player
  extend AttrHistory

  attr_reader :uid

  def initialize(uid)
    @uid = uid
  end

  def ==(other);   x == other.uid && y == other.uid; end
  def !=(other);   !(self == other);                 end
  def hash;        uid.hash;                         end
  def eql?(other); self == other;                    end
end


class Game
  include Singleton
  attr_accessor :players

  def initialize()
    @players = []
  end

  def self.game_init()
    instance.players << Player.new("Yosh")
    instance.players << Player.new("Aga")
  end


  def self.run_loop
    puts "Game start infinite loop !"
    loop do
      self.fetch_data();
      actions = self.generate_action();
      self.send_action(actions);
    end
  end

  private
  def self.fetch_data();;end
  def self.generate_action(); ""; end
  def self.send_action(actions);; end
end

def main()
  Game.game_init()
  Game.run_loop()
end

main()
