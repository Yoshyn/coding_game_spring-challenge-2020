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

  GUESS_PATH_TURN_DIFF = 3

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
    @visible = false
    targetable.reset!
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
    res = nil
    STDERR.puts "<action_switch for=#{self}>"
    ms = Benchmark.realtime {
      if ability_cooldown <= 0 && (blocked? || targetable.must_switch?)
        res ="SWITCH #{uid} #{type.weakness} B#{blocked?}-S#{targetable.must_switch?}"
      end
    } * 1000
    STDERR.puts "<action_switch take=#{ms}ms res=#{res} B(#{blocked?}) S(#{targetable.must_switch?})>"
    res
  end

  # ACTIONS GENERATIONS
  def action_speed
    res = nil
    STDERR.puts "<action_speed for=#{self}>"
    ms = Benchmark.realtime {
      if ability_cooldown <= 0 && !blocked? &&
        (
         (
            targetable.target_enemy || # We can kill
            player.score <= game.player(nil).score # Emergency need scoring
          ) && !targetable.must_switch? # Not near to a killer
         )
        res = "SPEED #{uid} T#{!!targetable.target_enemy}S#{player.score}<=#{game.player(nil).score}}"
      end
    } * 1000
    STDERR.puts "<action_speed take=#{ms}ms res=#{res}>"
    res
  end

  def action_move
    res = nil
    STDERR.puts "<action_move for=#{self}>"
    ms = Benchmark.realtime {
      if to = targetable.next
        (targetable.path.take(GUESS_PATH_TURN_DIFF) - [to]).each do |pos|
          game.turn_targeted_pos << pos
          game.grid_turn[pos].data = '#'
        end
        res = "MOVE #{uid} #{to.x} #{to.y} #{targetable.kind}-#{ability_cooldown}"
      else
        STDERR.puts "No possible actions for #{self}"
        raise "No possible action for #{self} !"
      end
    } * 1000
    STDERR.puts "</action_move take #{ms}ms>"
    res
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

  def to_s; "pm[#{@uid}-#{position}%#{ability_cooldown}|#{targetable.visible_enemies.count}|#{!!targetable.targetable_enemy}]"; end
  def to_i; 0; end

  def update_visible_things
    # ms = Benchmark.realtime {
      Position::DIRECTIONS.each do |dir|
        dir_pos = self.position.clone
        loop do
          dir_pos.move!(dir)
          cell = game.grid_turn[dir_pos]
          break if !cell.accessible_for? || dir_pos == self.position
          if game.visible_pellets[dir_pos] && !game.turn_visible_pellets[dir_pos]
            STDERR.puts "Remove bullet at #{dir_pos} for #{self} (#{dir})"
            game.visible_pellets.delete(dir_pos)
          end
          if cell.data.is_a?(PacMan)
            if player.uid != cell.data.player.uid
              STDERR.puts "SetVisibleEnemy at #{cell.uid}(#{cell.data.uid}) for #{self}"
              targetable.set_visible_enemy(cell.data)
            else
              STDERR.puts "FIND COPAIN at #{cell.uid}"
            end
          end
        end
      end
    # } * 1000
    # STDERR.puts "update_visible_things DONE in #{ms}ms for #{self}"
  end

  private
  def game; Game.instance; end
end
