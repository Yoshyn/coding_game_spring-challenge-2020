require 'singleton'
require_relative 'player'
require_relative 'core_ext/object'
require_relative 'grid2D'
require_relative 'cell'
require_relative 'path_finder'
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
    # STDERR.puts "Players : #{@players}"
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
      # value: amount of points this pellet is worth
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
