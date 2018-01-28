# encoding:utf-8
# frozen_string_literal: true

module RedisVoteable
  module Voteable
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def voteable?
        true
      end

      # private
      # def build_voter(voter)
      #   tmp = voter.split(':')
      #   tmp[0, tmp.length - 1].constantize.find(tmp.last)
      # end
    end

    def up_votes
      RedisVoteable.redis.scard prefixed("#{class_key(self)}:#{UP_VOTERS}")
    end

    def down_votes
      RedisVoteable.redis.scard prefixed("#{class_key(self)}:#{DOWN_VOTERS}")
    end

    def total_votes
      up_votes + down_votes
    end

    # Return the difference between up and and votes.
    # May be negative if there are more down than up votes.
    def tally
      up_votes - down_votes
    end

    def up_percentage
      return nil if total_votes.zero?
      (up_votes.to_f * 100 / total_votes)
    end

    def down_percentage
      return nil if total_votes.zero?
      (down_votes.to_f * 100 / total_votes)
    end

    # Returns true if the voter voted on the +voteable+.
    def voted_by?(voter)
      up_voted?(voter) || down_voted?(voter)
    end

    # Returns :up, :down, or nil.
    def vote_value?(voter)
      return :up   if up_voted?(voter)
      return :down if down_voted?(voter)
      nil
    end

    # Returns true if the voter up voted the +voteable+.
    def up_voted?(voter)
      RedisVoteable.redis.sismember prefixed("#{class_key(voter)}:#{UP_VOTES}"), class_key(self).to_s
    end

    # Returns true if the voter down voted the +voteable+.
    def down_voted?(voter)
      RedisVoteable.redis.sismember prefixed("#{class_key(voter)}:#{DOWN_VOTES}"), class_key(self).to_s
    end

    # Calculates the (lower) bound of the Wilson confidence interval
    # See: http://en.wikipedia.org/wiki/Binomial_proportion_confidence_interval#Wilson_score_interval
    # and: http://www.evanmiller.org/how-not-to-sort-by-average-rating.html
    def confidence(bound = :lower)
      # include Math
      epsilon = 0.5 # Used for Lidstone smoothing
      up   = up_votes + epsilon
      down = down_votes + epsilon
      n = up + down
      return 0 if n.zero?
      z = 1.4395314800662002 # Determines confidence to estimate.
      #    1.0364333771448913 = 70%
      #    1.2815515594600038 = 80%
      #    1.4395314800662002 = 85%
      #    1.644853646608357  = 90%
      #    1.9599639715843482 = 95%
      #    2.2414027073522136 = 97.5%
      p_hat = 1.0 * up / n
      left  = p_hat + z * z / (2 * n)
      right = z * Math.sqrt((p_hat * (1 - p_hat) + z * z / (4 * n)) / n)
      under = 1 + z * z / n
      return (left - right) / under unless bound == :upper
      (left + right) / under
      # return Math.sqrt( p_hat + z * z / ( 2 * n ) - z * ( ( p_hat * ( 1 - p_hat ) + z * z / ( 4 * n ) ) / n ) ) / ( 1 + z * z / n )
    end
  end
end
