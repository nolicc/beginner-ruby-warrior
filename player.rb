require "pry"

class WarriorProxy
  MAX_HEALTH = 20
  REST_HEALTH_INC = MAX_HEALTH * 0.1

  attr_accessor :warrior

  def initialize
    @previous_health = MAX_HEALTH
  end

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
      -> { @player.warrior.rescue!(:backward) }
    else
      ->{ @player.warrior.pivot! }
    end
  end

  def wall_behind_actions
    if @player.warrior.feel(:backward).stairs?
      -> { @player.warrior.walk!(:backward) }
    else
      -> { @player.warrior.pivot! }
    end
  end

  def something_behind_actions
    behind_view = @player.warrior.look(:backward)
    action ||= captive_behind_actions if behind_view.any?(&:captive?)
    action ||= wall_behind_actions if behind_view.any?(&:stairs?)
    action
  end
end

module EnemyActions
  def next_to_an_enemy_situation
    -> { @player.warrior.attack! } if @player.warrior.feel.enemy?
  end

  def surrounded_situation
    -> { @player.warrior.walk! } if @player.warrior.surrounded?
  end

  def enemy_far_ahead_with_clear_view_situation
    if @player.warrior.enemy_far_ahead_with_clear_view?
      -> { @player.warrior.shoot! }
    end
  end

  def enemy_actions
    action ||= next_to_an_enemy_situation
    action ||= surrounded_situation
    action ||= enemy_far_ahead_with_clear_view_situation
  end
end

class Action
  include SomethingBehindActions
  include EnemyActions

  def initialize(player)
    @player = player
  end

  def take
    action ||= something_behind_actions
    action ||= -> { @player.warrior.rescue! } if @player.warrior.feel.captive?
    action ||= -> { @player.warrior.pivot! } if @player.warrior.feel.wall?
    action ||= enemy_actions
    action ||= -> { @player.warrior.walk! }
    action.call
  end
end

class Player
  attr_reader :warrior

  def play_turn(warrior)
    @warrior ||= WarriorProxy.new
    @warrior.warrior = warrior
    Action.new(self).take
  end
end
