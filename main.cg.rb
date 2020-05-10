
STDOUT.sync = true # DO NOT REMOVE

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

      define_method("previous_#{attribute}") do
        __send__(method_key)[-2]
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
class TrueClass
  def to_s; 'T' end
end

class FalseClass
  def to_s; 'F' end
end
class Hash
  def except(*keys)
    dup.except!(*keys)
  end

  def except!(*keys)
    keys.each { |key| delete(key) }
    self
  end
end
class Object
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

class PathFinder

  def initialize(grid, from, unit_context = nil);
    @grid = grid;
    @current_uid = nil
    @visited = {};
    @from = from
    @unit_context = unit_context
  end

  def shortest_path(to, move_size: 1);
    return nil unless @grid[to]&.accessible?(@unit_context)
    @to_visit = [[0, @from, to]]

    while(!@to_visit.empty? && @current_uid != to)
      @to_visit.sort_by! { |dist, _| dist }
      distance, @current_uid, previous_uid = @to_visit.shift
      @visited[@current_uid] ||= begin
        @grid[@current_uid].neighbors.each do |ngh_uid, ngh_data|
          next unless @grid[ngh_uid].accessible?(@unit_context)
          @to_visit << [
            distance + ngh_data.distance,
            ngh_uid, @current_uid ]
        end
        [distance, previous_uid]
      end
    end

    positions = [to]
    distance, res_to = @visited[to]
    return nil unless res_to
    loop do
      break if res_to == @from
      positions << res_to
      res_to = @visited[res_to].last
    end

    fetch_key = (move_size <= positions.size) ? -move_size : -1
    {
      next: positions[fetch_key],
      dir: @grid[@from].neighbors[positions.last].direction,
      dist: (distance / move_size.to_f).round,
      path: positions.reverse()
    }
  end

  def maximise(move_size: 1);
  end

  def to_s(separator: false);
    to_display = @grid.deep_clone
    @visited.each do |distance, origin|
      to_display[distance] = origin.join('-')
    end
    to_display.to_s(separator: separator)
  end
end
class Shifumi
  VALUES = ["PAPER", "ROCK", "SCISSORS"]
  attr_reader :type

  def self.can_win(type_id)
    VALUES[(VALUES.index(type_id.to_s) + 2) % 3]
  end

  def self.can_loose(type_id)
    VALUES[(VALUES.index(type_id.to_s) - 2) % 3]
  end

  def initialize(type); @type = type.to_s; end

  def weakness; Shifumi.new(Shifumi.can_win(type));   end
  def strength; Shifumi.new(Shifumi.can_loose(type)); end

  def ==(other); @type == other.type;                  end
  def <(other);  Shifumi.can_win(@type) == other.type; end
  def <=(other); self == other || self < other;        end
  def >(other);  self != other && !(self < other);     end
  def >=(other); self == other || self > other;        end

  def to_s; type; end
end


class PacMan
  extend AttrHistory
  attr_reader :uid
  attr_reader :player
  attr_accessor :visible

  attr_historized(
    :position,         # position in the grid
    :type_id,          # ROCK, SCISSORS, PAPER
    :speed_turns_left, # 0 => speed(1), 1..5 => speed(2)
    :ability_cooldown, # 0..8, usable at 0
    :turn_number       # turn number of the update
  )

  def initialize(player, uid);
    @player, @uid = player, uid;
    @visible = false;
    @_cached = {}
  end

  def game; Game.instance; end

  def reset!; @_cached, @visible = {}, false; end

  def update(position, type_id, speed_turns_left, ability_cooldown)
    self.visible = true
    self.position = position
    self.type_id = type_id
    self.speed_turns_left = speed_turns_left
    self.ability_cooldown = ability_cooldown
    self.turn_number = game.turn_number
    game.grid_turn[position].data = self
    update_visible_bullets
  end

  def update_visible_bullets
    visited_pos = [position]
    if position_changed? && (turn_number - previous_turn_number) <= 5
      pf = PathFinder.new(game.grid, self.previous_position)
      if (result = pf.shortest_path(position))
        visited_pos += result[:path]
      end
    end
    visited_pos.each do |pos|
      value = game.visible_pellets.delete(pos)
    end
  end

  def type; Shifumi.new(type_id); end

  def can_reach?(position)
    self.position.circle_area(current_speed).include?(position)
  end

  def an_opp_can_instant_kill_me?
    @_cached[__method__] ||= begin
      game.opp_player.pacmans.any? { |opc|
        opc.can_reach?(position) && opc.type > type
      }
    end
  end

  def speed_enabled?(); (self.speed_turns_left.to_i > 0); end
  def current_speed;    speed_enabled? ? 2 : 1;           end

  def targetable_opp;
    @_cached[__method__] ||= begin
      pacman = game.opp_player.pacmans.find { |opc|
        can_reach?(opc.position) && type > opc.type
      }
      if pacman
        STDERR.puts "pm #{uid} target #{pacman} at #{pacman.position}"
        pf = PathFinder.new(game.grid_turn, self.position, self)
        pf.shortest_path(pacman.position)
      end
    end
  end

  def targetable_bullet;
    @_cached[:targetable_bullet] ||= begin
      already_used_pos = game.turn_targeted_pos.to_a
      bullet_pos, pts = game.visible_pellets.except(*already_used_pos).sort_by { |pos, pts|
        pos.distance(self.position) - pts
      }.shift
      { next: bullet_pos, path: [bullet_pos] }
    end
  end

  def targetable_scoring;
    @_cached[__method__] ||= begin
      t_bullet = targetable_bullet()[:next]
      pf = PathFinder.new(game.grid_turn, self.position, self)
      result = t_bullet && pf.shortest_path(t_bullet, move_size: current_speed)
      if result
        result
      else
        STDERR.puts "#{uid} unable to reach #{t_bullet}. Target another location"
        @_cached[:targetable_bullet] = nil
        game.turn_targeted_pos << t_bullet
        nil
      end
    end
  end

  def target_path_data
    @_cached[__method__] ||= begin
      (targetable_opp || targetable_scoring || targetable_bullet)
    end
  end

  def action_speed
    if ability_cooldown <= 0 && position_changed?() &&
      (
        (
          targetable_opp || # We can kill
          _positions.count < 5 || # Begin of game
          game.my_player.score < game.opp_player.score # Emergency need scoring
        ) && !an_opp_can_instant_kill_me? # Not near to a killer
      )
      "SPEED #{uid} T#{!!targetable_opp}P#{_positions.count < 5}S#{game.my_player.score < game.opp_player.score}"
    end
  end

  def action_switch
    if ability_cooldown <= 0 && (!position_changed?() || an_opp_can_instant_kill_me?)
      "SWITCH #{uid} #{type.weakness} P#{!position_changed?()}K#{an_opp_can_instant_kill_me?}"
    end
  end

  def action_move
    kind = "0" if targetable_opp
    kind = (!kind && targetable_scoring) ? "S" : "B"
    target_path_data[:path].each do |pos|
      game.turn_targeted_pos << pos
      game.grid_turn[pos].data = '#'
    end
    to = target_path_data[:next]
    target_path_data && "MOVE #{uid} #{to.x} #{to.y} #{kind}#{ability_cooldown}#{to.x}#{to.y}"
  end

  def next_action
    action_speed || action_switch || action_move
  end

  def ==(other);   uid == other.uid;                 end
  def !=(other);   !(self == other);                 end
  def hash;        uid.hash;                         end
  def eql?(other); self == other;                    end

  def to_s; "pm[#{@uid}-#{position}%#{ability_cooldown}]"; end
end

class Player
  extend AttrHistory
  attr_reader :uid
  attr_historized(:score)

  def initialize(uid)
    @uid = uid
    @pacmans = {}
  end

  def get_pac_man(uid); @pacmans[uid] ||= PacMan.new(self, uid); end

  def include_pm?(pac_id); @pacmans.keys.include?(pac_id); end

  def raw_pacmans; @pacmans.values; end
  def pacmans; raw_pacmans.select { |pc| pc.visible }; end

  def to_s; "player[#{@uid} - Score(#{score}) - pacmans(#{@pacmans.map(&:to_s)})]"; end
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
    Radius.new(radius).map do |pos|
      pos + self if (pos.x.abs + pos.y.abs) <= radius
    end.compact
  end

  def distance(other)
    return Math.sqrt((other.x - x) ** 2 + (other.y - y) ** 2);
  end

  def square_area(radius);
    Radius.new(radius).map { |pos| pos + self }
  end

  def to_s; "(#{x},#{y})";  end
  def to_a; [x,y];          end
end

class TorPosition < Position
  def initialize(x,y, max_x, max_y);
    super(x,y)
    @max_x,@max_y=max_x,max_y;
  end

  def circle_area(radius);
    super(radius).map do |pos|
      TorPosition.new(pos.x, pos.y, @max_x, @max_y)
    end
  end

  def square_area(radius);
    super(radius).map do |pos|
      TorPosition.new(pos.x, pos.y, @max_x, @max_y)
    end
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
    @game = Game.instance
  end

  def set_neighbor(uid, distance, direction)
    @neighbors[uid] = Neighbor.new(distance, direction)
  end

  def accessible?(cell_context=nil); true; end
  def <=>(other); data <=> other.data; end
  def to_s;       "#{data.to_s}";      end
end

class GameCell < Cell
  def accessible?(unit_context=nil)
    if unit_context && data.is_a?(PacMan)
      if data.player.include_pm?(data.uid)
        return false
      else
        return data.can_beat?(unit_context.type_id)
      end
    end
    return data != '#' if data.is_a?(String)
    return true if data.is_a?(Integer)
    raise "Unexpected data : #{data.class} - #{data}"
  end
end
require 'set'

class Game
  include Singleton

  attr_reader :grid, :grid_turn
  attr_reader :turn_number
  attr_reader :visible_pellets, :turn_targeted_pos
  attr_reader :my_player, :opp_player

  def initialize()
    @my_player  = Player.new(:ME)
    @opp_player = Player.new(:OPP)
    @visible_pellets   = {}
    @turn_number = 0
    @grid = @grid_turn = nil
    @turn_targeted_pos = Set.new
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
        @visible_pellets[cell_pos] = 1
        Position::DIRECTIONS.each do |dir|
          dir_pos = cell_pos.move(dir)
          cell.set_neighbor(dir_pos, 1, dir) if grid[dir_pos].accessible?
        end
      end
    end
    STDERR.puts "Init Grid with #{@visible_pellets.size()} Pellets"
    @grid.freeze
  end

  def run_loop
    STDERR.puts "Game start infinite loop !"
    loop do
      @turn_number += 1
      fetch_data()
      actions = my_player.pacmans.map do |pacman|
        pacman.next_action
      end
      puts actions.reject(&:nil?).join(' | ')
    end
  end

  def all_pacmans;
    (my_player.pacmans + opp_player.pacmans);
  end

  def player(player_id);
    (player_id.to_i == 1) ? my_player : opp_player;
  end

  def get_pac_man(player_id, pac_id);
    player(player_id).get_pac_man(pac_id.to_i)
  end

  private
  def fetch_data()
    @grid_turn = @grid.deep_clone
    @turn_targeted_pos = []
    my_score, opponent_score = gets.split(" ").collect {|x| x.to_i}
    all_pacmans.each { |pc| pc.reset! }

    visible_pac_count = gets.to_i
    visible_pac_count.times do
      pac_id, player_id, x, y, type_id, speed_turns_left, ability_cooldown = gets.split(" ")
      pac_pos = TorPosition.new(x.to_i, y.to_i, @grid.width-1, @grid.height-1)
      pac_man = get_pac_man(player_id, pac_id.to_i)
      pac_man.update(
        TorPosition.new(x.to_i, y.to_i, @grid.width-1, @grid.height-1),
        type_id,
        speed_turns_left.to_i,
        ability_cooldown.to_i)
    end

    visible_pellets_count = gets.to_i # all pellets in sight
    visible_pellets_count.times do
      x, y, value = gets.split(" ").collect {|x| x.to_i}
      b_pos = TorPosition.new(x, y, @grid.width-1, @grid.height-1)
      @visible_pellets[b_pos] = value
    end
    STDERR.puts "T#{turn_number} Total/visible Pellet => #{@visible_pellets.size()}/#{visible_pellets_count}"
    @visible_pellets.each { |pos, pts| @grid_turn[pos].data = pts }

    my_player.score = my_score
    opp_player.score = opponent_score
  end
end

def main()
  Game.instance.game_init()
  Game.instance.run_loop()
end

main();
