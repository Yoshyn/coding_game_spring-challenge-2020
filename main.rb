require_relative 'cell'
require_relative 'grid2D'
require_relative 'path_finder'
require_relative 'position'
require_relative 'game'

def main()
  Game.game_init()
  Game.run_loop()
end

main()
