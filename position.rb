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
    Position.new(x,y).move!(direction, cell)
  end

  def +(other)
    self.x = x + other.x; self.y = y + other.y; self
  end
  def -(other)
    self.x = x - other.x; self.y = y - other.y; self
  end

  def ==(other);    x == other.x && y == other.y; end
  def !=(other);    !(self == other);             end

  def hash;         to_a.hash;                    end
  def eql?(other);  self == other;                end

  def <(other); x < other.x || (x == other.x && y < other.y); end
  def >(other); x > other.x || (x == other.x && y > other.y); end

  def circle_area(radius);
    Radius.new(radius).map do |pos|
      pos + self if (pos.x.abs + pos.y.abs) <= radius
    end.compact
  end

  def square_area(radius);
    Radius.new(radius).map { |pos| pos + self }
  end

  def to_s; "(#{x},#{y})";  end
  def to_a; [x,y];          end
end
