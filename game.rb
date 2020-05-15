require 'singleton'
require_relative 'player'
require_relative 'core_ext/object'
require_relative 'core_ext/hash'
require_relative 'grid2D'
require_relative 'cell'
require_relative 'path_finder'
require 'set'

class Game
  include Singleton

  attr_reader :grid
  attr_accessor :grid_turn
  attr_reader :turn_number
  attr_reader :turn_targeted_pos
  attr_reader :turn_visible_pellets
  attr_reader :my_player, :opp_player


  def initialize()
    @my_player  = Player.new(:ME)
    @opp_player = Player.new(:OPP)
    @visible_pellets, @turn_visible_pellets = {}, {}
    @grid = nil
    @grid_turn = nil
    @turn_number = 0
    @turn_targeted_pos = Set.new
  end

  def game_init()
    width, height = gets.split(" ").collect {|x| x.to_i}
    @grid = Grid2D.new(width, height)
    height.times do |row_index|
      row = gets.chomp
      row.split('').each_with_index do |value, col_index|
        c_pos = TorPosition.new(col_index, row_index, @grid.width, @grid.height)
        @grid[c_pos] = GameCell.new(c_pos, value)
      end
    end
    @grid.each do |cell|
      if cell.accessible_for?
        @visible_pellets[cell.uid] = 1
        Position::DIRECTIONS.each do |dir|
          dir_pos = cell.uid.move(dir)
          cell.set_neighbor(dir_pos, 1, dir) if grid[dir_pos].accessible_for?
        end
      end
    end
    STDERR.puts "Init Grid[#{@grid.width}, #{@grid.height}] Size[#{@grid.size()}] with #{@visible_pellets.length()} Pellets"
    # STDERR.puts "---------"
    # STDERR.puts @grid.to_s
    # STDERR.puts "---------"
    @grid.freeze
  end

  def run_loop
    STDERR.puts "Game start infinite loop !"
    loop do
      @turn_number += 1
      STDERR.puts "Start TURN ##{@turn_number}"
      turn_update()
      ms0 = Benchmark.realtime {
        STDERR.puts "<actions turn_number=##{@turn_number}>"
        actions = []
        my_player.pacmans.each do |pacman|
          STDERR.puts "<action for=#{pacman}>"
          ms = Benchmark.realtime {
            actions << pacman.next_action
          } * 1000
          STDERR.puts "</action take=#{ms}ms for=#{pacman} result=#{actions.last}>"
        end
        puts actions.reject(&:nil?).join(' | ')
      } * 1000
      STDERR.puts "</actions take=#{ms0}ms>"
      STDERR.puts "----------------------------"
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

  def visible_pellets
    @visible_pellets.except(*turn_targeted_pos)
  end

  private
  def turn_update()
    readed_data = nil
    # RESET Everything before wait for get.
    @grid_turn = @grid.deep_clone
    all_pacmans.each { |pc| pc.reset! }
    @turn_targeted_pos = []
    @turn_visible_pellets = {}

    ms = Benchmark.realtime {
      STDERR.puts "<fetch_data (reading stdin)>"
      readed_data = fetch_data()
    } * 1000
    STDERR.puts "</fetch_data take #{ms}ms>"
    my_score, opponent_score, to_update_pacmans, to_update_pellets = readed_data

    ms = Benchmark.realtime {
      STDERR.puts "<turn_update_real (after reading stdin)>"

      to_update_pellets.each do |x, y, value|
        p_pos = TorPosition.new(x, y, @grid.width, @grid.height)
        @visible_pellets[p_pos] = value
        @turn_visible_pellets[p_pos] = value
      end

      to_update_pacmans.each do |uid, player_id, x, y, type, speed_turns_left, ability_cooldown|
        pac_pos = TorPosition.new(x, y, @grid.width, @grid.height)
        pac_man = get_pac_man(player_id, uid)
        pac_man.update(pac_pos, type, speed_turns_left, ability_cooldown)
        @visible_pellets.delete(pac_pos)
      end
      my_player.pacmans.each(&:update_visible_things)
      @visible_pellets.each { |pos, pts| @grid_turn[pos].data = pts }
      STDERR.puts "T#{turn_number} Total/visible Pellet => #{visible_pellets.length()}/#{turn_visible_pellets.count}"

      Game.instance.visible_pellets.each do |pos, v|
        STDERR.puts " * Remain Super Bullet at #{pos}" if v > 1
      end

      my_player.score = my_score
      opp_player.score = opponent_score
    } * 1000
    STDERR.puts "</turn_update_real take #{ms}ms>"
  end


  def fetch_data()
    my_score, opponent_score = gets.split(" ").collect {|x| x.to_i}

    visible_pac_count = gets.to_i
    to_update_pacmans = visible_pac_count.times.map do
      uid, player_id, x, y, type, stl, ac = gets.split(" ")
      [uid.to_i, player_id, x.to_i, y.to_i, type, stl.to_i, ac.to_i]
    end

    visible_pellets_count = gets.to_i # all pellets in sight
    to_update_pellets = visible_pellets_count.times.map do
      x, y, value = gets.split(" ").collect {|x| x.to_i}
      [x, y, value]
    end
    [my_score, opponent_score, to_update_pacmans, to_update_pellets]
  end
end
