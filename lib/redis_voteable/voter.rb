# encoding:utf-8
# frozen_string_literal: true

module RedisVoteable
  module Voter
    extend ActiveSupport::Concern

    included do
      # TODO: add scope
      # scope :up_voted_for, lambda { |votee| where(_id: { '$in' =>  votee.up_voter_ids }) }
      # scope :down_voted_for, lambda { |votee| where(_id: { '$in' =>  votee.down_voter_ids }) }
      # scope :voted_for, lambda { |votee| where(_id: { '$in' =>  votee.voter_ids }) }
    end

    module ClassMethods
      def voter?
        true
      end
    end

    # Up vote a +voteable+.
    # Raises an AlreadyVotedError if the voter already up voted the voteable.
    # Changes a down vote to an up vote if the the voter already down voted the voteable.
    def up_vote(voteable)
      check_voteable(voteable)
      # Up/Down vote a +voteable+.
      # Raises an AlreadyVotedError if the voter already up/down voted the voteable.
      # Changes an up vote to a down vote if the the voter already up voted the voteable.
      # Changes an down vote to a up vote if the the voter already down voted the voteable.

      r = RedisVoteable.redis.multi do
        RedisVoteable.redis.srem prefixed("#{class_key(voteable)}:#{DOWN_VOTERS}"), class_key(self).to_s
        RedisVoteable.redis.srem prefixed("#{class_key(self)}:#{DOWN_VOTES}"), class_key(voteable).to_s
        RedisVoteable.redis.sadd prefixed("#{class_key(voteable)}:#{UP_VOTERS}"), class_key(self).to_s
        RedisVoteable.redis.sadd prefixed("#{class_key(self)}:#{UP_VOTES}"), class_key(voteable).to_s
      end
      raise Exceptions::AlreadyVotedError, true unless r[2]
      true
    end

    # Down vote a +voteable+.
    # Raises an AlreadyVotedError if the voter already down voted the voteable.
    # Changes an up vote to a down vote if the the voter already up voted the voteable.
    def down_vote(voteable)
      check_voteable(voteable)

      r = RedisVoteable.redis.multi do
        RedisVoteable.redis.srem prefixed("#{class_key(voteable)}:#{UP_VOTERS}"), class_key(self).to_s
        RedisVoteable.redis.srem prefixed("#{class_key(self)}:#{UP_VOTES}"), class_key(voteable).to_s
        RedisVoteable.redis.sadd prefixed("#{class_key(voteable)}:#{DOWN_VOTERS}"), class_key(self).to_s
        RedisVoteable.redis.sadd prefixed("#{class_key(self)}:#{DOWN_VOTES}"), class_key(voteable).to_s
      end
      raise Exceptions::AlreadyVotedError, false unless r[2]
      true
    end

    %i[up_vote down_vote].each do |_method|
      # Up/Down votes the +voteable+, but doesn't raise an error if the votelable was already up/down voted.
      # The vote is simply ignored then.

      define_method "#{_method}!".to_sym do |voteable|
        begin
          send _method, voteable
          return true
        rescue Exceptions::AlreadyVotedError
          return false
        end
      end
    end

    # Clears an already done vote on a +voteable+.
    # Raises a NotVotedError if the voter didn't voted for the voteable.
    def clear_vote(voteable)
      check_voteable(voteable)

      r = RedisVoteable.redis.multi do
        RedisVoteable.redis.srem prefixed("#{class_key(voteable)}:#{DOWN_VOTERS}"), class_key(self).to_s
        RedisVoteable.redis.srem prefixed("#{class_key(self)}:#{DOWN_VOTES}"), class_key(voteable).to_s
        RedisVoteable.redis.srem prefixed("#{class_key(voteable)}:#{UP_VOTERS}"), class_key(self).to_s
        RedisVoteable.redis.srem prefixed("#{class_key(self)}:#{UP_VOTES}"), class_key(voteable).to_s
      end
      raise Exceptions::NotVotedError unless r[0] || r[2]
      true
    end
    alias unvote clear_vote

    # Clears an already done vote on a +voteable+, but doesn't raise an error if
    # the voteable was not voted. It ignores the unvote then.
    def clear_vote!(voteable)
      clear_vote(voteable)
      return true
    rescue
      return false
    end
    alias unvote! clear_vote!

    # Return the total number of votes a voter has cast.
    def total_votes
      up_votes + down_votes
    end

    # Returns the number of upvotes a voter has cast.
    def up_votes
      RedisVoteable.redis.scard prefixed("#{class_key(self)}:#{UP_VOTES}")
    end

    # Returns the number of downvotes a voter has cast.
    def down_votes
      RedisVoteable.redis.scard prefixed("#{class_key(self)}:#{DOWN_VOTES}")
    end

    # Returns true if the voter voted for the +voteable+.
    def voted?(voteable)
      up_voted?(voteable) || down_voted?(voteable)
    end

    # Returns :up, :down, or nil.
    def vote_value?(voteable)
      return :up   if up_voted?(voteable)
      return :down if down_voted?(voteable)
      nil
    end

    # Returns true if the voter up voted the +voteable+.
    def up_voted?(voteable)
      RedisVoteable.redis.sismember prefixed("#{class_key(voteable)}:#{UP_VOTERS}"), class_key(self).to_s
    end

    # Returns true if the voter down voted the +voteable+.
    def down_voted?(voteable)
      RedisVoteable.redis.sismember prefixed("#{class_key(voteable)}:#{DOWN_VOTERS}"), class_key(self).to_s
    end

    private

    def check_voteable(voteable)
      raise Exceptions::InvalidVoteableError unless voteable.class.respond_to?('voteable?') && voteable.class.voteable?
    end
  end
end
