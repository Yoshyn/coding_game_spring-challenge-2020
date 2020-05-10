class Shifumi
  VALUES = ["PAPER", "ROCK", "SCISSORS"]
  attr_reader :type

  def self.can_win(type_id)
    VALUES[(VALUES.index(type_id.to_s) + 2) % 3]
  end

  def self.can_loose(type_id)
    VALUES[(VALUES.index(type_id.to_s) - 2) % 3]
  end

  def initialize(type); @type = type.to_s; end

  def weakness; Shifumi.new(Shifumi.can_win(type));   end
  def strength; Shifumi.new(Shifumi.can_loose(type)); end

  def ==(other); type == other.type;                  end
  def <(other);  Shifumi.can_win(type) == other.type; end
  def <=(other); self == other || self < other;       end
  def >(other);  self != other && !(self < other);    end
  def >=(other); self == other || self > other;       end

  def to_s; type; end
end

# Shifumi.can_kill("PAPER")
# Shifumi.can_kill("ROCK")
# Shifumi.can_kill("SCISSORS")
# paper = Shifumi.new("PAPER")
# rock = Shifumi.new("ROCK")
# rock == paper # false
# rock < paper # true
# rock > rock # false
# rock >= rock
