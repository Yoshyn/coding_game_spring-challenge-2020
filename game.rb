require 'singleton'
require_relative 'player'
require_relative 'core_ext/object'
require_relative 'grid2D'
require_relative 'cell'
require_relative 'path_finder'
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
    STDERR.puts "Init Grid with #{@visible_pellets.length()} Pellets"
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
    STDERR.puts "T#{turn_number} Total/visible Pellet => #{@visible_pellets.length()}/#{visible_pellets_count}"
    @visible_pellets.each { |pos, pts| @grid_turn[pos].data = pts }

    my_player.score = my_score
    opp_player.score = opponent_score
  end
end
