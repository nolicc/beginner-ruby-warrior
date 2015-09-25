require "pry"

module AdvancedWarrior
  MAX_HEALTH = 20
  REST_HEALTH_INC = MAX_HEALTH * 0.1

  def optimal_health?
    (health + REST_HEALTH_INC).floor >= MAX_HEALTH
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
    if @warrior.feel(:backward).captive?
      -> { @warrior.rescue!(:backward) }
    else
      ->{ @warrior.pivot! }
    end
  end

  def wall_behind_actions
    if @warrior.feel(:backward).stairs?
      -> { @warrior.walk!(:backward) }
    else
      -> { @warrior.pivot! }
    end
  end

  def something_behind_actions
    behind_view = @warrior.look(:backward)
    action ||= captive_behind_actions if behind_view.any?(&:captive?)
    action ||= wall_behind_actions if behind_view.any?(&:stairs?)
    action
  end
end

module EnemyActions
  def next_to_an_enemy_situation
    -> { @warrior.attack! } if @warrior.feel.enemy?
  end

  def surrounded_situation
    -> { @warrior.walk! } if @warrior.surrounded?
  end

  def enemy_far_ahead_with_clear_view_situation
    if @warrior.enemy_far_ahead_with_clear_view?
      -> { @warrior.shoot! }
    end
  end

  def enemy_actions
    action ||= next_to_an_enemy_situation
    action ||= surrounded_situation
    action ||= enemy_far_ahead_with_clear_view_situation
  end
end

class Player
  include SomethingBehindActions
  include EnemyActions

  attr_reader :warrior

  def play_turn(warrior)
    @warrior = warrior
    @warrior.extend(AdvancedWarrior)
    action!
  end

  def action!
    action ||= something_behind_actions
    action ||= -> { @warrior.rescue! } if @warrior.feel.captive?
    action ||= -> { @warrior.pivot! } if @warrior.feel.wall?
    action ||= enemy_actions
    action ||= -> { @warrior.walk! }
    action.call
  end
end
