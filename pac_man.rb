require_relative 'core_ext/attr_history'
require_relative 'core_ext/bool'
require_relative 'core_ext/hash'
require_relative 'shifumi'
require_relative 'game'
require_relative 'targetable'
require_relative 'path_finder'

class PacMan
  extend AttrHistory
  attr_reader :uid
  attr_reader :player
  attr_reader :targetable
  attr_accessor :visible

  GUESS_PATH_TURN_DIFF = 5

  attr_historized(
    :position,         # position in the grid
    :type_id,          # ROCK, SCISSORS, PAPER
    :speed_turns_left, # 0 => speed(1), 1..5 => speed(2)
    :ability_cooldown, # 0..8, usable at 0
    :turn_number       # turn number of the update
  )

  def initialize(player, uid);
    @player, @uid, @visible = player, uid, false;
    @targetable = TargetableCell.new(self)
  end

  def reset!;
    @visible = {}
    @targetable.clear_cache!
  end

  def update(position, type_id, speed_turns_left, ability_cooldown)
    self.visible = true
    self.position = position
    self.type_id = type_id
    self.speed_turns_left = speed_turns_left
    self.ability_cooldown = ability_cooldown
    self.turn_number = game.turn_number
    game.grid_turn[position].data = self
    remove_bullet_positions!
  end

  # HELPERS
  def type; Shifumi.new(type_id); end
  def speed_enabled?(); (self.speed_turns_left.to_i > 0); end
  def current_speed;    speed_enabled? ? 2 : 1;           end
  def blocked?
    !(position_changed? && (_positions.count < 2))
  end

  def action_switch
    if ability_cooldown <= 0 && (blocked? || @targetable.must_switch?)
      "SWITCH #{uid} #{type.weakness} B#{blocked?}-S#{@targetable.must_switch?}"
    end
  end

  # ACTIONS GENERATIONS
  def action_speed
    if ability_cooldown <= 0 && !blocked? &&
      (
        (
          @targetable.target_enemy || # We can kill
          pacman.player.score <= player(nil).score # Emergency need scoring
        ) && !must_switch? # Not near to a killer
      )
      "SPEED #{uid} T#{!!@targetable.target_enemy}S#{pacman.player.score <= player(nil).score}"
    end
  end

  def action_move
    kind = "0" if @targetable.target_enemy
    kind = (!kind && @targetable.target_bullet) ? "B" : "D"
    # TODO : Remove only the X first from the path
    # Exemple : longest path will block everything overwise
    @targetable.path.each do
      # TODO : is turn_targeted_pos still use ?
      game.turn_targeted_pos << pos
      game.grid_turn[pos].data = '#'
    end
    to = @targetable.next
    target_path_data && "MOVE #{uid} #{to.x} #{to.y} #{kind}#{ability_cooldown}#{to.x}#{to.y}"
  end

  def next_action
    action_switch || action_speed || action_move
  end

  # DELEGATOR
  def ==(other); type == other.type; end
  def <(other);  type < other.type;  end
  def <=(other); type <= other.type; end
  def >(other);  type > other.type;  end
  def >=(other); type >= other.type; end
  def weakness;  type.weakness;      end
  def strength;  type.strength;      end

  # OPERATORS
  def hash;        uid.hash;         end
  def eql?(other); self == other;    end

  def to_s; "pm[#{@uid}-#{position}%#{ability_cooldown}]"; end
  # def to_i; 0; end

  private
  def game; Game.instance; end

  def remove_bullet_positions!
    visited_pos = [position]
    if position_changed? && (turn_number - previous_turn_number) <= GUESS_PATH_TURN_DIFF
      pf = PathFinder.new(game.grid, self.previous_position)
      if (result = pf.shortest_path(position))
        visited_pos += result[:path]
      end
    end
    visited_pos.each do |pos|
      value = game.visible_pellets.delete(pos)
    end
  end
end
