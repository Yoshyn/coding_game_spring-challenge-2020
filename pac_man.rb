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
  attr_reader :turn_visible_pellets

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
    @turn_visible_pellets = []
  end

  def reset!;
    @visible = false
    targetable.reset!
    @turn_visible_pellets = []
  end

  def update(position, type_id, speed_turns_left, ability_cooldown)
    self.visible = true
    self.position = position
    self.type_id = type_id
    self.speed_turns_left = speed_turns_left
    self.ability_cooldown = ability_cooldown
    self.turn_number = game.turn_number
    game.grid_turn[position].data = self
  end

  # HELPERS
  def type; Shifumi.new(type_id); end
  def speed_enabled?(); (self.speed_turns_left.to_i > 0); end
  def current_speed;    speed_enabled? ? 2 : 1;           end
  def blocked?
    !position_changed? && (_positions.count > 1)
  end

  def action_switch
    if ability_cooldown <= 0 && (blocked? || targetable.must_switch?)
      "SWITCH #{uid} #{type.weakness} B#{blocked?}-S#{!!targetable.must_switch?}"
    end
  end

  # ACTIONS GENERATIONS
  def action_speed
    if ability_cooldown <= 0 && !blocked? &&
      (
       (
          targetable.target_enemy || # We can kill
          player.score < game.player(nil).score+20 # Emergency need scoring
        ) && !targetable.must_switch? # Not near to a killer
       )
      "SPEED #{uid} T#{!!targetable.target_enemy}S#{player.score<(game.player(nil).score+20)}"
    end
  end

  def action_move
    if to = targetable.next
      targetable.path.take(5).each do |pos|
        game.turn_targeted_pos << pos
      end
      STDERR.puts "PacMan(#{self}) Move(#{targetable.kind}) for(#{targetable.value}) at #{targetable.next}"
      STDERR.puts "PATH(#{targetable.path.map(&:to_s)})"
      @previous_order = to
      "MOVE #{uid} #{to.x} #{to.y} #{targetable.kind}-#{ability_cooldown}"
    else
      STDERR.puts "No possible actions for #{self}"
      raise "No possible action for #{self} !"
    end
  end

  def next_action
    action_switch || action_speed || action_move
  end

  # DELEGATOR
  def ==(other); type == other.type; end
  def alive?;    type.alive?         end
  def <(other);  type < other.type;  end
  def <=(other); type <= other.type; end
  def >(other);  type > other.type;  end
  def >=(other); type >= other.type; end
  def weakness;  type.weakness;      end
  def strength;  type.strength;      end

  # OPERATORS
  def hash;        uid.hash;         end
  def eql?(other); self == other;    end

  def to_s; "pm[#{@uid}-#{position}%#{ability_cooldown}|#{targetable.visible_enemies.count}|#{!!targetable.targetable_enemy}]"; end
  def to_i; 0; end

  def update_visible_things
    if blocked? && ability_cooldown >= 1 && @previous_order
      STDERR.puts "BLOCKED DETECTED for #{self} go to #{@previous_order}"
      game.grid_turn[@previous_order].data = '#'
      STDERR.puts "#{game.grid_turn}"
    end
    @previous_order = nil
    Position::DIRECTIONS.each do |dir|
      dir_pos = self.position.clone
      loop do
        dir_pos.move!(dir)
        cell = game.grid_turn[dir_pos]
        break if !cell.accessible_for? || dir_pos == self.position
        if game.visible_pellets[dir_pos]
          if !game.turn_visible_pellets[dir_pos]
            game.remove_pellet!(dir_pos)
          else
            @turn_visible_pellets << dir_pos.clone
          end
        elsif cell.data.is_a?(PacMan) &&
          player.uid != cell.data.player.uid
          targetable.set_visible_enemy(cell.data)
        end
      end
    end
    STDERR.puts "Pacman #{self} see bullets at #{@turn_visible_pellets.map(&:to_s)}"
    STDERR.puts "Pacman #{self} see enemies at #{@targetable.visible_enemies.map(&:position)}"
  end

  private
  def game; Game.instance; end
end
