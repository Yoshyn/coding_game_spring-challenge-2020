require_relative 'pac_man'

class TargetableCell
  def initialize(pacman)
    @pacman = pacman
    @game = Game.instance
    @_cached = {}
  end

  def enemies; player(nil).pacmans;   end
  def allies;  pacman.player.pacmans; end

  def reachable_enemies;
    enemies.select { |enemy| pacman.can_reach?(enemy) }
  end

  def target_enemy
    reachable_enemies.detect { |enemy| pacman > enemy }
  end

  def must_switch?
    reachable_enemies && target_enemy.nil?
  end

  def target_scoring
    # @_cached[__method__] ||= begin
    # end
  end

  def target_bullet
    @_cached[__method__] ||= begin
      already_used_pos = game.turn_targeted_pos.to_a
      bullets = game.visible_pellets.except(*already_used_pos)
      bullet_pos, pts = bullets.sort_by { |pos, pts|
        pos.distance(pacman.position) - pts
      }.shift
    end
  end

  def target
    # TODO : target_enemy, target_scoring..
    # does not return the same things...
    @_cached[__method__] ||= begin
      kind, position, value = if target_enemy
        [:pacman, target_enemy.position ,target_enemy.uid]
      elsif target_scoring
        [:bullet, nil, nil]
      else
        [:default, target_bullet, nil]
      end
      pf = PathFinder.new(game.grid_turn, pacman.position, pacman)
      result = pf.shortest_path(position)
      { kind: kind, next: position, path: result[:path], value: value }
    end
  end

  def next; target[:next];   end
  def path; target[:path];   end
  def value; target[:value]; end
  def kind; target[:kind];   end
  def clear_cache!; @_cached={};end

  private
  def can_instant_reach?(position)
    cir_pos = pacman.position.circle_area(current_speed)
    cir_pos.include?(position)
  end
end
