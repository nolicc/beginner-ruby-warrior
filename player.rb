module AdvancedWarrior
  MAX_HEALTH = 20
  REST_HEALTH_INC = MAX_HEALTH * 0.1

  def optimal_health?
    (health + REST_HEALTH_INC).floor >= MAX_HEALTH
  end

  def enemy_far_ahead_with_clear_view?(direction = :forward)
    enemy_distance(direction).to_i >= 1 && captive_before_enemy?(direction)
  end

  def surrounded?
    enemy_far_ahead_with_clear_view?(:forward) &&
      enemy_far_ahead_with_clear_view?(:backward)
  end

  def captive_behind?
    look(:backward).any?(&:captive?)
  end

  def stairs_behind?
    look(:backward).any?(&:stairs?)
  end

  private

  def captive_before_enemy?(direction)
    !captive_distance(direction) ||
      enemy_distance(direction) < captive_distance(direction)
  end

  def enemy_distance(direction)
    look(direction).index(&:enemy?)
  end

  def captive_distance(direction)
    look(direction).index(&:captive?)
  end
end

module SomethingBehindActions
  def captive_behind_actions
    return unless @warrior.captive_behind?
    if @warrior.feel(:backward).captive?
      -> { @warrior.rescue!(:backward) }
    else
      -> { @warrior.pivot! }
    end
  end

  def stairs_behind_actions
    return unless @warrior.stairs_behind?
    if @warrior.feel(:backward).stairs?
      -> { @warrior.walk!(:backward) }
    else
      -> { @warrior.pivot! }
    end
  end

  def something_behind_actions
    action ||= captive_behind_actions
    action || stairs_behind_actions
  end
end

module EnemyActions
  def next_to_an_enemy_action
    -> { @warrior.attack! } if @warrior.feel.enemy?
  end

  def surrounded_action
    -> { @warrior.walk! } if @warrior.surrounded?
  end

  def enemy_far_ahead_with_clear_view_action
    -> { @warrior.shoot! } if @warrior.enemy_far_ahead_with_clear_view?
  end

  def enemy_actions
    action ||= next_to_an_enemy_action
    action ||= surrounded_action
    action || enemy_far_ahead_with_clear_view_action
  end
end

class Action
  include EnemyActions
  include SomethingBehindActions

  def wall_actions
    -> { @warrior.pivot! } if @warrior.feel.wall?
  end

  def captive_actions
    -> { @warrior.rescue! } if @warrior.feel.captive?
  end

  def initialize(warrior)
    @warrior = warrior
    @action ||= something_behind_actions
    @action ||= captive_actions
    @action ||= wall_actions
    @action ||= enemy_actions
    @action ||= -> { @warrior.walk! }
  end

  def take
    @action.call
  end
end

class Player
  attr_reader :warrior

  def play_turn(warrior)
    @warrior = warrior
    @warrior.extend(AdvancedWarrior)
    Action.new(@warrior).take
  end
end
