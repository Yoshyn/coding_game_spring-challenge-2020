require_relative 'game'

class Cell
  Neighbor = Struct.new(:cost, :direction) do
    def <=>(other); self.cost <=> other.cost; end
  end

  attr_accessor :uid, :data, :neighbors

  def initialize(uid, data);
    @uid, @data, @neighbors = uid, data, {}
    @game = Game.instance
  end

  def set_neighbor(uid, cost, direction)
    @neighbors[uid] = Neighbor.new(cost, direction)
  end

  def accessible?(cell_context=nil); true; end
  def <=>(other); data <=> other.data; end
  def to_s;       "#{data.to_s}";      end
end

class GameCell < Cell
  def accessible?(unit_context=nil)
    if unit_context && data.is_a?(PacMan)
      if data.player.include_pm?(data.uid)
        return false
      else
        return data.can_beat?(unit_context.type_id)
      end
    end
    return data != '#' if data.is_a?(String)
    return true if data.is_a?(Integer)
    raise "Unexpected data : #{data.class} - #{data}"
  end
end
