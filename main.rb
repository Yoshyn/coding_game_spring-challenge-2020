require_relative 'game'

def main()
  Game.instance.game_init()
  Game.instance.run_loop()
end

main();
