require_relative 'game'

class Cell
  class NeighborInfo
    attr_accessor :to, :cost
    def initialize(to, cost, **nhg_data)
      @to, @cost = to, cost
      @nhg_data = nhg_data
      nhg_data.each_key do |method|
        self.class.define_method(method) { @nhg_data[method] }
      end
    end
    def <=>(other); self.cost <=> other.cost; end
  end

  attr_accessor :uid, :data

  def initialize(uid, data);
    @uid, @data, @neighbors = uid, data, {}
    @game = Game.instance
  end

  def set_neighbor(uid, cost, direction)
    @neighbors[uid] = NeighborInfo.new(uid, cost,
      direction: direction
    )
  end

  def get_neighbor(uid); @neighbors[uid];   end
  def neighbors;         @neighbors.values; end

  def accessible?(cell_context=nil); true; end
  def <=>(other); data <=> other.data;     end
  def to_s;       "#{data.to_s}";          end
end

class GameCell < Cell
  def accessible_for?(unit=nil)
    if unit && data.is_a?(PacMan)
      if unit.player.uid == data.player.uid
        return false
      else
        return unit.type > data.type
      end
    end
    return data != '#' if data.is_a?(String)
    return true
  end
end
