class Cell
  Neighbor = Struct.new(:distance, :direction) do
    def <=>(other); self.distance <=> other.distance; end
  end

  attr_accessor :uid, :data, :neighbors

  def initialize(uid, data);
    @uid, @data, @neighbors = uid, data, {}
  end

  def set_neighbor(uid, distance, direction)
    @neighbors[uid] = Neighbor.new(distance, direction)
  end

  def accessible?(); true;                end
  def <=>(other);    data <=> other.data; end
  def to_s;          "#{data.to_s}";      end
end

class GameCell < Cell
  def accessible?(); data != '#'; end
end
