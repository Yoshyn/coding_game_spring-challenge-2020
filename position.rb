class Position

  DIRECTIONS= %i(north east south west)

  class Radius
    include Enumerable
    def initialize(value); @value =value; end

    def each
      (-@value..@value).each do |i|
        (-@value..@value).each do |j|
          yield(Position.new(i,j))
        end
      end
    end
  end

  attr_accessor :x, :y

  def initialize(x,y); @x,@y=x,y; end

  def self.opposed(direction);
    DIRECTIONS[(DIRECTIONS.index(direction) + 2) % 4]
  end

  def move_north!(cell=1); @y-=cell; self; end
  def move_east! (cell=1); @x+=cell; self; end
  def move_south!(cell=1); @y+=cell; self; end
  def move_west! (cell=1); @x-=cell; self; end

  def move!(direction, cell=1)
    __send__("move_#{direction}!", cell);
  end

  def move(direction, cell=1)
    clone.move!(direction, cell)
  end

  def +(other)
    self.x = x + other.x; self.y = y + other.y; self
  end
  def -(other)
    self.x = x - other.x; self.y = y - other.y; self
  end

  def ==(other);  x == other&.x && y == other&.y; end
  def !=(other);  !(self == other);               end

  def hash;         to_a.hash;                    end
  def eql?(other);  self == other;                end

  def <(other); x < other.x || (x == other.x && y < other.y); end
  def >(other); x > other.x || (x == other.x && y > other.y); end

  def circle_area(radius);
    Radius.new(radius).map do |pos|
      pos + self if (pos.x.abs + pos.y.abs) <= radius
    end.compact
  end

  def distance(other)
    return Math.sqrt((other.x - x) ** 2 + (other.y - y) ** 2);
  end

  def square_area(radius);
    Radius.new(radius).map { |pos| pos + self }
  end

  def to_s; "(#{x},#{y})";  end
  def to_a; [x,y];          end
end

class TorPosition < Position
  def initialize(x,y, max_x, max_y);
    @max_x,@max_y=max_x,max_y;
    clamp!(x,y)
  end

  def circle_area(radius);
    super(radius).map do |pos|
      TorPosition.new(pos.x, pos.y, @max_x, @max_y)
    end
  end

  def square_area(radius);
    super(radius).map do |pos|
      TorPosition.new(pos.x, pos.y, @max_x, @max_y)
    end
  end

  def move_north!(cell=1); clamp_y!(y-cell); self; end
  def move_east! (cell=1); clamp_x!(x+cell); self; end
  def move_south!(cell=1); clamp_y!(y+cell); self; end
  def move_west! (cell=1); clamp_x!(x-cell); self;  end

  def distance(other)
    dist_x = (other.x - x).abs
    dists_x = [dist_x ** 2]
    dists_x << (dist_x - @max_x).abs ** 2 if dist_x > @max_x.to_f / 2
    dist_y = (other.y - y).abs
    dists_y = [dist_y ** 2]
    dists_y << (dist_y - @max_y).abs ** 2 if dist_y > @max_y.to_f / 2
    Math.sqrt(dists_x.min + dists_y.min)
  end

  private
  def clamp!(x,y)
    clamp_x!(x); clamp_y!(y)
  end
  def clamp_x!(x)
    @x = x.between?(0, @max_x) ? x : @max_x - x.abs
  end
  def clamp_y!(y)
    @y = y.between?(0, @max_y) ? y : @max_y - y.abs
  end
end
