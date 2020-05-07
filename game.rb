require 'singleton'
require_relative 'player'

class Game
  include Singleton
  attr_accessor :players

  def initialize()
    @players = []
  end

  def self.game_init()
    # Puts here what we get from stdin to init the game
    instance.players << Player.new("Yosh")
    instance.players << Player.new("Aga")
    # Display data of the game here
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
