require_relative 'core_ext/attr_history'

class Player
  extend AttrHistory
  attr_reader :uid
  attr_historized(:score)

  def initialize(uid)
    @uid = uid
    @pacmans = {}
  end

  def update_pac_man(uid, position, type_id, speed_turns_left, ability_cooldown)
    @pacmans[uid] ||= PacMan.new(uid)
    @pacmans[uid].position = position
    @pacmans[uid].type_id = type_id
    @pacmans[uid].speed_turns_left = speed_turns_left
    @pacmans[uid].ability_cooldown = ability_cooldown
  end

  def pacmans; @pacmans.values; end

  def to_s; "pl[#{@uid} - Sco(#{score}) - pacmans(#{@pacmans})]"; end
end

class PacMan
  extend AttrHistory

  attr_reader :uid
  attr_historized(
    :position, # position in the grid
    :type_id,  # unused in wood leagues
    :speed_turns_left, # unused in wood leagues
    :ability_cooldown  # unused in wood leagues
  )

  def initialize(uid); @uid = uid; end

  def ==(other);   x == other.uid && y == other.uid; end
  def !=(other);   !(self == other);                 end
  def hash;        uid.hash;                         end
  def eql?(other); self == other;                    end

  def to_s; "pm[#{@uid} - pos(#{position})]"; end
end
