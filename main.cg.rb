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
  attr_historized(:score)

  def initialize(uid)
    @uid = uid
    @pacmans = {}
  end

  def update_pac_man(uid, position, type_id, speed_turns_left, ability_cooldown)
    @pacmans[uid] ||= PacMan.new(uid)
    @pacmans[uid].position = position
    @pacmans[uid].type_id = type_id
    @pacmans[uid].speed_turns_left = speed_turns_left
    @pacmans[uid].ability_cooldown = ability_cooldown
  end

  def pacmans; @pacmans.values; end

  def to_s; "pl[#{@uid} - Sco(#{score}) - pacmans(#{@pacmans})]"; end
end

class PacMan
  extend AttrHistory

  attr_reader :uid
  attr_historized(
    :position, # position in the grid
    :type_id,  # unused in wood leagues
    :speed_turns_left, # unused in wood leagues
    :ability_cooldown  # unused in wood leagues
  )

  def initialize(uid); @uid = uid; end

  def ==(other);   x == other.uid && y == other.uid; end
  def !=(other);   !(self == other);                 end
  def hash;        uid.hash;                         end
  def eql?(other); self == other;                    end

  def to_s; "pm[#{@uid} - pos(#{position})]"; end
end
class Object
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end
class Position

  DIRECTIONS= %i(north east south west)

  class Radius
    include Enumerable
    def initialize(value, position_klass=nil);
      @value =value;
      @position_klass = position_klass
    end

    def each
      (-@value..@value).each do |i|
        (-@value..@value).each do |j|
          yield(@position_klass.new(i,j))
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
    clone.move!(direction, cell)
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
    Radius.new(radius, self.class).map do |pos|
      pos + self if (pos.x.abs + pos.y.abs) <= radius
    end.compact
  end

  def distance(other)
    return Math.sqrt((other.x - x) ** 2 + (other.y - y) ** 2);
  end

  def square_area(radius);
    Radius.new(radius, self.class).map { |pos| pos + self }
  end

  def to_s; "(#{x},#{y})";  end
  def to_a; [x,y];          end
end

class TorPosition < Position
  def initialize(x,y, max_x, max_y);
    super(x,y)
    @max_x,@max_y=max_x,max_y;
  end

  def y;
    @y=0 if @y > @max_y
    @y=@max_y if @y < 0
    return @y
  end
  def x;
    @x=0 if @x > @max_x
    @x=@max_x if @x < 0
    return @x
  end
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

  def size();   @width * @height; end
  def width();  @width;           end
  def height(); @height;          end

  def [](position);         get(position.x,position.y);         end
  def []=(position, value); set(position.x, position.y, value); end

  def each
    return enum_for(:each) unless block_given?
    @_data.each_with_index do |value, index|
      yield(value)
    end
  end

  def slice(*positions); positions.map { |pos| self[pos] }.compact; end

  def include?(x,y); !!to_index(x,y); end

  def to_s(separator: false)
    cell_to_s = -> (pos, value) { "#{pos}=>#{value}" }
    max_cell_size = map { |pos, value| cell_to_s.call(pos, value).length }.max
    row_separator=""
    out = "\n"
    (0...@height).each do |col|
      row_line=(0...@width).map do |row|
        pos, value = Position.new(row,col), get(row, col)
        cell_to_s.call(pos, value).center(max_cell_size)
      end.join(separator ? " | " : " ")
      if separator
        row_separator ||= "| "+"-"*row_line.size + " |\n"
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
    Position.new(index % width, index/@width)
  end

  def to_index(x,y)
    index = (x + y * @width)
    return index if x >= 0 && y >= 0 && y < @height && x < @width
    return nil
  end
end
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
  def to_s;          "#{data.to_s}";      end
end

class GameCell < Cell
  def accessible?(); data != '#'; end
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

  def to_s(separator: false);
    to_display = @grid.deep_clone
    @visited.each do |distance, origin|
      to_display[distance] = origin.join('-')
    end
    to_display.to_s(separator: separator)
  end
end
require 'benchmark'

STDOUT.sync = true # DO NOT REMOVE

class Game
  include Singleton
  attr_accessor :players
  attr_reader :grid
  attr_reader :grid_turn
  attr_reader :visible_pellets

  MY_ID = true
  OPP_ID = false

  def initialize()
    @players = {
      MY_ID => Player.new(:me),
      OPP_ID => Player.new(:opp)
    }
    @visible_pac_count    = 0
    @visible_pellets = {}
    @grid = @grid_turn = nil
  end

  def game_init()
    width, height = gets.split(" ").collect {|x| x.to_i}
    @grid = Grid2D.new(width, height)
    height.times do |row_index|
      row = gets.chomp
      row.split('').each_with_index do |value, col_index|
        c_pos = TorPosition.new(col_index, row_index, width - 1 , height - 1)
        @grid[c_pos] = GameCell.new(c_pos, value)
      end
    end
    @grid.each do |cell|
      cell_pos = cell.uid
      if grid[cell_pos].accessible?
        Position::DIRECTIONS.each do |dir|
          dir_pos = cell_pos.move(dir)
          cell.set_neighbor(dir_pos, 1, dir) if grid[dir_pos].accessible?
        end
      end
    end
    @grid.freeze
  end

  def run_loop
    STDERR.puts "Game start infinite loop !"
    loop do
      actions = []
      fetch_data()
      send_action_ms = 1000 * Benchmark.realtime {
        @players[MY_ID].pacmans.each do |pacman|
          actions << generate_actions_for(pacman);
        end
      }
      STDERR.puts "Genetate actions in #{send_action_ms}ms"
      puts actions.join(' | ')
    end
  end

  def mine?(id) id.to_i == 1; end

  private
  def fetch_data()
    @grid_turn = @grid.deep_clone
    @visible_pellets = {}
    my_score, opponent_score = gets.split(" ").collect {|x| x.to_i}
    @visible_pac_count = gets.to_i
    @visible_pac_count.times do
        pac_id, player_id, x, y, type_id, speed_turns_left, ability_cooldown = gets.split(" ")
        pac_pos = TorPosition.new(x.to_i, y.to_i, @grid.width-1, @grid.height-1)
        @players[mine?(player_id)].update_pac_man(
          pac_id.to_i, pac_pos,
          type_id, speed_turns_left.to_i, ability_cooldown.to_i
        )
        @grid_turn[pac_pos].data = -5
    end
    @visible_pellets_count = gets.to_i # all pellets in sight
    @visible_pellets_count.times do
      x, y, value = gets.split(" ").collect {|x| x.to_i}
      b_pos = TorPosition.new(x, y, @grid.width-1, @grid.height-1)
      @visible_pellets[b_pos] = value
      @grid_turn[b_pos].data = value
    end
    @players[MY_ID].score = my_score
    @players[OPP_ID].score = opponent_score
  end

  def generate_actions_for(pacman)
    targeted, pts = @visible_pellets.max_by { |pos, pts|
      pts * 2 + pos.distance(pacman.position)
    }

    "MOVE #{pacman.uid} #{targeted.x} #{targeted.y} T#{targeted}P#{pts}"
  end
end

def main()
  Game.instance.game_init()
  Game.instance.run_loop()
end

main();
