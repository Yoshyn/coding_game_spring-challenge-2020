require_relative 'core_ext/attr_history'
require_relative 'pac_man'

class Player
  extend AttrHistory
  attr_reader :uid
  attr_historized(:score)

  def initialize(uid)
    @uid = uid
    @pacmans = {}
  end

  def get_pac_man(uid); @pacmans[uid] ||= PacMan.new(self, uid); end

  def include_pm?(pac_id); @pacmans.keys.include?(pac_id); end

  def raw_pacmans; @pacmans.values; end
  def pacmans; raw_pacmans.select { |pc| pc.visible }; end

  def to_s; "player[#{@uid} - Score(#{score}) - pacmans(#{@pacmans.map(&:to_s)})]"; end
end
