require "pry"

module AdvancedWarrior
  MAX_HEALTH = 20
  REST_HEALTH_INC = MAX_HEALTH * 0.1

  def optimal_health?
    (health + REST_HEALTH_INC).floor >= MAX_HEALTH
  end

  def enemy_far_ahead_with_clear_view?(direction = :forward)
    @eye_direction = direction
    enemy_distance.to_i >=1 && captive_before_enemy?
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

  def captive_before_enemy?
    (!captive_distance || enemy_distance < captive_distance)
  end
  
  def enemy_distance
    look(@eye_direction).index(&:enemy?)
  end

  def captive_distance
    look(@eye_direction).index(&:captive?)
  end
end

module SomethingBehindActions
  def captive_behind_actions
    if @warrior.captive_behind?
      if @warrior.feel(:backward).captive?
        -> { @warrior.rescue!(:backward) }
      else
        ->{ @warrior.pivot! }
      end
    end
  end

  def stairs_behind_actions
    if @warrior.stairs_behind?
      if @warrior.feel(:backward).stairs?
        -> { @warrior.walk!(:backward) }
      else
        -> { @warrior.pivot! }
      end
    end
  end

  def something_behind_actions
    action ||= captive_behind_actions
    action ||= stairs_behind_actions
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
    action.call
  end

  def captive_action
    -> { @warrior.rescue! } if @warrior.feel.captive?
  end

  def wall_action
    -> { @warrior.pivot! } if @warrior.feel.wall?
  end

  def action
    action ||= something_behind_actions
    action ||= captive_action
    action ||= wall_action
    action ||= enemy_actions
    action ||= -> { @warrior.walk! }
  end
end
