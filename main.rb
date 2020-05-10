# frozen_string_literal: true

STDOUT.sync = true # DO NOT REMOVE

require_relative 'game'
require_relative 'position'

def main()
  Game.instance.game_init()
  Game.instance.run_loop()
end

main();
