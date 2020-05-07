require_relative 'core_ext/attr_history'

class Player
  extend AttrHistory

  attr_reader :uid

  def initialize(uid)
    @uid = uid
  end

  def ==(other);   x == other.uid && y == other.uid; end
  def !=(other);   !(self == other);                 end
  def hash;        uid.hash;                         end
  def eql?(other); self == other;                    end
end

