class Position

  DIRECTIONS= %i(north east south west)

  class Radius
    include Enumerable
    def initialize(value, position_klass=nil);
      @value =value;
      @position_klass = position_klass
    end

    def each
      (-@value..@value).each do |i|
        (-@value..@value).each do |j|
          yield(@position_klass.new(i,j))
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

  def ==(other);    x == other.x && y == other.y; end
  def !=(other);    !(self == other);             end

  def hash;         to_a.hash;                    end
  def eql?(other);  self == other;                end

  def <(other); x < other.x || (x == other.x && y < other.y); end
  def >(other); x > other.x || (x == other.x && y > other.y); end

  def circle_area(radius);
    Radius.new(radius, self.class).map do |pos|
      pos + self if (pos.x.abs + pos.y.abs) <= radius
    end.compact
  end

  def distance(other)
    return Math.sqrt((other.x - x) ** 2 + (other.y - y) ** 2);
  end

  def square_area(radius);
    Radius.new(radius, self.class).map { |pos| pos + self }
  end

  def to_s; "(#{x},#{y})";  end
  def to_a; [x,y];          end
end

class TorPosition < Position
  def initialize(x,y, max_x, max_y);
    super(x,y)
    @max_x,@max_y=max_x,max_y;
  end

  def y;
    @y=0 if @y > @max_y
    @y=@max_y if @y < 0
    return @y
  end
  def x;
    @x=0 if @x > @max_x
    @x=@max_x if @x < 0
    return @x
  end
end
