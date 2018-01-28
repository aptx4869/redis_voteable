# encoding:utf-8
# frozen_string_literal: true

require 'active_support/dependencies'
require 'redis'
require 'redis_voteable/version'
require 'redis_voteable/voteable'
require 'redis_voteable/voter'
require 'redis_voteable/exceptions'

module RedisVoteable
  extend ActiveSupport::Concern

  UP_VOTERS   = 'up_voters'
  DOWN_VOTERS = 'dn_voters'
  UP_VOTES    = 'up_votes'
  DOWN_VOTES  = 'dn_votes'

  mattr_accessor :redis_voteable_settings
  @@redis_voteable_settings = {
    host: 'localhost',
    port: '6379',
    db: 0,
    key_prefix: 'vote:'
  }

  def redis_voteable_settings=(new_settings)
    @@redis_voteable_settings.update(new_settings)
    RedisVoteable.redis = Redis.new(RedisVoteable.redis_voteable_settings)
  end

  mattr_accessor :redis

  def prefixed(sid)
    "#{@@redis_voteable_settings[:key_prefix]}#{sid}"
  end

  def class_key(v)
    "#{v.class.name}:#{v.id}"
  end

  module ClassMethods
    def voteable?
      false
    end

    def voter?
      false
    end

    # Specify a model as voteable.
    #
    # Example:
    # class Question < ActiveRecord::Base
    #   acts_as_voteable
    # end
    def acts_as_voteable
      RedisVoteable.redis ||= Redis.new(RedisVoteable.redis_voteable_settings)
      include Voteable
    end

    # Specify a model as voter.
    #
    # Example:
    # class User < ActiveRecord::Base
    #   acts_as_voter
    # end
    def acts_as_voter
      RedisVoteable.redis ||= Redis.new(RedisVoteable.redis_voteable_settings)
      include Voter
    end
  end
end
