class WarriorProxy
  MAX_HEALTH = 20
  REST_HEALTH_INC = MAX_HEALTH * 0.1

  attr_accessor :warrior

  def method_missing(method_name, *args, &block)
    if @warrior.respond_to? method_name
      @warrior.send(method_name, *args, &block)
    else
      super
    end
  end

  def optimal_health?
    (health + REST_HEALTH_INC).floor >= MAX_HEALTH
  end

  def retreat!(direction = :foward)
    if direction == :backward
      walk! :forward
    else
      walk! :backward
    end
  end

  def enemy_far_ahead_with_clear_view?(direction = :forward)
    captive_index = look(direction).index(&:captive?)
    enemy_index   = look(direction).index(&:enemy?)
    if !enemy_index.nil? && enemy_index >= 1
      if !captive_index.nil? && captive_index < enemy_index
        return false
      else
        return true
      end
    end
    false
  end

  def surrounded?
    if enemy_far_ahead_with_clear_view?(:forward) &&
       enemy_far_ahead_with_clear_view?(:backward)
      true
    else
      false
    end
  end
end

module SomethingBehindActions
  def captive_behind_actions
    if @player.warrior.feel(:backward).captive?
      @player.warrior.rescue!(:backward)
    else
      @player.warrior.pivot!
    end
    true
  end

  def wall_behind_actions
    if @player.warrior.feel(:backward).stairs?
      @player.warrior.walk!(:backward)
    else
      @player.warrior.pivot!
    end
    true
  end

  def something_behind_actions
    behind_view = @player.warrior.look(:backward)
    return captive_behind_actions if behind_view.any?(&:captive?)
    return wall_behind_actions if behind_view.any?(&:stairs?)
    false
  end
end

module BadlyWoundedActions
  def can_rest_situation
    if !@player.warrior_taking_damage?
      @player.warrior.rest!
      true
    else
      false
    end
  end

  def badly_wounded_actions
    unless @player.warrior.optimal_health?
      return true if enemy_far_ahead_with_clear_view_situation
      # return true if must_rest_situation
      return true if can_rest_situation
    end
    false
  end
end

module EnemyActions
  def next_to_an_enemy_situation
    if @player.warrior.feel.enemy?
      @player.warrior.attack!
      return true
    end
    false
  end

  def surrounded_situation
    if @player.warrior.surrounded?
      @player.warrior.walk!
      return true
    end
    false
  end

  def enemy_far_ahead_with_clear_view_situation
    if @player.warrior.enemy_far_ahead_with_clear_view?
      @player.warrior.shoot!
      return true
    end
    false
  end

  def enemy_actions
    return true if next_to_an_enemy_situation
    return true if surrounded_situation
    return true if enemy_far_ahead_with_clear_view_situation
    false
  end
end

class Action
  include SomethingBehindActions
  include BadlyWoundedActions
  include EnemyActions

  def initialize(player)
    @player = player
  end

  def wall_actions
    if @player.warrior.feel.wall?
      @player.warrior.pivot!
      return true
    end
    false
  end

  def captive_actions
    if @player.warrior.feel.captive?
      @player.warrior.rescue!
      return true
    end
    false
  end

  def take
    return if something_behind_actions
    return if captive_actions
    return if badly_wounded_actions
    return if wall_actions
    return if enemy_actions
    default_actions
  end

  def default_actions
    @player.warrior.walk!
  end
end

class Player
  attr_reader :warrior, :previous_health

  def play_turn(warrior)
    @warrior ||= WarriorProxy.new
    @warrior.warrior = warrior
    @previous_health ||= @warrior.health
    Action.new(self).take
    @previous_health = @warrior.health
  end

  def warrior_taking_damage?
    [0, @previous_health - @warrior.health].max != 0
  end
end
