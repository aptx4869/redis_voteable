# spec/lib/redis_voteable_spec.rb
# frozen_string_literal: true

require File.expand_path('../../spec_helper', __FILE__)

describe 'Redis Voteable' do
  before(:each) do
    @voteable = VoteableModel.create(name: 'Votable 1')
    @voter = VoterModel.create(name: 'Voter 1')
  end

  it 'create a voteable instance' do
    expect(@voteable.class).to eql VoteableModel
    expect(@voteable.class.voteable?).to eql true
  end

  it 'create a voter instance' do
    expect(@voter.class).to eql VoterModel
    expect(@voter.class.voter?).to eql true
  end

  it 'get correct vote summary' do
    expect(@voter.up_vote(@voteable)).to eql true
    expect(@voteable.total_votes).to eql 1
    expect(@voteable.tally).to eql 1
    expect(@voter.down_vote(@voteable)).to eql true
    expect(@voteable.total_votes).to eql 1
    expect(@voteable.tally).to eql(-1)
    expect(@voter.clear_vote(@voteable)).to eql true
    expect(@voteable.total_votes).to eql 0
    expect(@voteable.tally).to eql 0
  end

  it 'voteable has up vote votings' do
    expect(@voteable.up_votes).to eql 0
    @voter.up_vote(@voteable)
    expect(@voteable.up_votes).to eql 1
    expect(@voter.up_voted?(@voteable)).to be true
  end

  it 'voter has up vote votings' do
    expect(@voter.up_votes).to be 0
    @voter.up_vote(@voteable)
    expect(@voter.up_votes).to be 1
  end

  it 'voteable has down vote votings' do
    expect(@voteable.down_votes).to eql 0
    @voter.down_vote(@voteable)
    expect(@voteable.down_votes).to eql 1
    expect(@voter.up_voted?(@voteable)).to be false
    expect(@voter.down_voted?(@voteable)).to be true
  end

  it 'voter has down vote votings' do
    expect(@voter.down_votes).to eql 0
    @voter.down_vote(@voteable)
    expect(@voter.down_votes).to eql 1
  end

  it 'voteable calculates correct percentages' do
    @voter.up_vote(@voteable)
    expect(@voteable.up_percentage).to eql 100.0
    expect(@voteable.down_percentage).to eql 0.0
    @voter2 = VoterModel.create(name: 'Voter 2')
    @voter2.down_vote(@voteable)
    expect(@voteable.up_percentage).to eql 50.0
    expect(@voteable.down_percentage).to eql 50.0
  end

  it 'voteable calculates lower Wilson confidence bound' do
    @voter2 = VoterModel.create(name: 'Voter 2')
    @voter3 = VoterModel.create(name: 'Voter 3')
    @voter4 = VoterModel.create(name: 'Voter 4')
    @voter.up_vote(@voteable)
    score1 = @voteable.confidence
    @voter2.down_vote(@voteable)
    score2 = @voteable.confidence
    @voter3.down_vote(@voteable)
    score3 = @voteable.confidence
    @voter3.up_vote(@voteable)
    score4 = @voteable.confidence
    @voter4.up_vote(@voteable)
    score5 = @voteable.confidence
  end

  describe 'up vote' do
    it 'increase up votes of voteable by one' do
      expect(@voteable.up_votes).to eql 0
      @voter.up_vote(@voteable)
      expect(@voteable.up_votes).to eql 1
    end

    it 'increase up votes of voter by one' do
      expect(@voter.up_votes).to eql 0
      @voter.up_vote(@voteable)
      expect(@voter.up_votes).to eql 1
    end

    it 'only allow a voter to up vote a voteable once' do
      expect(@voteable.up_votes).to eql 0
      @voter.up_vote(@voteable)
      expect do
        @voter.up_vote(@voteable)
      end.to raise_error(RedisVoteable::Exceptions::AlreadyVotedError)
      expect(@voteable.up_votes).to eql 1
    end

    it 'only allow a voter to up vote a voteable once without raising an error' do
      expect(@voteable.up_votes).to eql 0
      @voter.up_vote!(@voteable)
      expect(@voteable.up_votes).to eql 1
      expect do
        expect(@voter.up_vote!(@voteable)).to eql false
      end.not_to raise_error
      expect(@voteable.total_votes).to eql 1
    end

    it 'change a down vote to an up vote' do
      @voter.down_vote(@voteable)
      expect(@voteable.up_votes).to eql 0
      expect(@voteable.down_votes).to eql 1
      expect(@voteable.tally).to eql(-1)
      expect(@voter.up_votes).to eql 0
      expect(@voter.down_votes).to eql 1

      @voter.up_vote(@voteable)
      expect(@voteable.up_votes).to eql 1
      expect(@voteable.down_votes).to eql 0
      expect(@voteable.tally).to eql 1
      expect(@voter.up_votes).to eql 1
      expect(@voter.down_votes).to eql 0
    end

    it 'allow up votes from different voters' do
      @voter2 = VoterModel.create(name: 'Voter 2')
      @voter.up_vote(@voteable)
      @voter2.up_vote(@voteable)
      expect(@voteable.up_votes).to eql 2
      expect(@voteable.tally).to eql 2
    end

    it 'raise an error for an invalid voteable' do
      invalid_voteable = InvalidVoteableModel.create
      expect do
        @voter.up_vote(invalid_voteable)
      end.to raise_error(RedisVoteable::Exceptions::InvalidVoteableError)
    end

    it 'check if voter up voted voteable' do
      @voter.up_vote(@voteable)
      expect(@voter.voted?(@voteable)).to be true
      expect(@voter.up_voted?(@voteable)).to be true
      expect(@voter.down_voted?(@voteable)).to be false
    end

    it 'have up votings' do
      @voter.up_vote(@voteable)
      expect(@voteable.up_voted?(@voter)).to be true
      expect(@voteable.down_voted?(@voter)).to be false
    end
  end

  describe 'down vote' do
    it 'decrease down votes of voteable by one' do
      expect(@voteable.down_votes).to eql 0
      @voter.down_vote(@voteable)
      expect(@voteable.down_votes).to eql 1
    end

    it 'decrease down votes of voter by one' do
      expect(@voter.down_votes).to eql 0
      @voter.down_vote(@voteable)
      expect(@voter.down_votes).to eql 1
    end

    it 'only allow a voter to down vote a voteable once' do
      expect(@voteable.down_votes).to eql 0
      @voter.down_vote(@voteable)
      expect do
        @voter.down_vote(@voteable)
      end.to raise_error(RedisVoteable::Exceptions::AlreadyVotedError)
      expect(@voteable.down_votes).to eql 1
    end

    it 'only allow a voter to down vote a voteable once without raising an error' do
      expect(@voteable.down_votes).to eql 0
      @voter.down_vote!(@voteable)
      expect(@voteable.down_votes).to eql 1
      expect do
        expect(@voter.down_vote!(@voteable)).to eql false
      end.not_to raise_error
      expect(@voteable.total_votes).to eql 1
    end

    it 'change an up vote to a down vote' do
      @voter.up_vote(@voteable)
      expect(@voteable.up_votes).to eql 1
      expect(@voteable.down_votes).to eql 0
      expect(@voteable.tally).to eql 1
      expect(@voter.up_votes).to eql 1
      expect(@voter.down_votes).to eql 0

      @voter.down_vote(@voteable)
      expect(@voteable.up_votes).to eql 0
      expect(@voteable.down_votes).to eql 1
      expect(@voteable.tally).to eql(-1)
      expect(@voter.up_votes).to eql 0
      expect(@voter.down_votes).to eql 1
    end

    it 'allow down votes from different voters' do
      @voter2 = VoterModel.create(name: 'Voter 2')
      @voter.down_vote(@voteable)
      @voter2.down_vote(@voteable)
      expect(@voteable.down_votes).to eql 2
      expect(@voteable.tally).to eql(-2)
    end

    it 'raise an error for an invalid voteable' do
      invalid_voteable = InvalidVoteableModel.create
      expect do
        @voter.down_vote(invalid_voteable)
      end.to raise_error(RedisVoteable::Exceptions::InvalidVoteableError)
    end

    it 'check if voter down voted voteable' do
      @voter.down_vote(@voteable)
      expect(@voter.voted?(@voteable)).to be true
      expect(@voter.up_voted?(@voteable)).to be false
      expect(@voter.down_voted?(@voteable)).to be true
    end

    it 'have down votings' do
      @voter.down_vote(@voteable)
      expect(@voteable.up_voted?(@voter)).to be false
      expect(@voteable.down_voted?(@voter)).to be true
    end
  end

  describe 'clear_vote' do
    it 'decrease the up votes if up voted before' do
      @voter.up_vote(@voteable)
      expect(@voteable.up_votes).to eql 1
      expect(@voter.up_votes).to eql 1
      @voter.clear_vote(@voteable)
      expect(@voteable.up_votes).to eql 0
      expect(@voter.up_votes).to eql 0
    end

    it 'have working aliases' do
      @voter.up_vote(@voteable)
      expect(@voteable.up_votes).to eql 1
      expect(@voter.up_votes).to eql 1
      @voter.unvote(@voteable)
      expect(@voteable.up_votes).to eql 0
      expect(@voter.up_votes).to eql 0
    end

    it "raise an error if voter didn't vote for the voteable" do
      expect do
        @voter.clear_vote(@voteable)
      end.to raise_error(RedisVoteable::Exceptions::NotVotedError)
    end

    it "not raise error if voter didn't vote for the voteable and clear_vote! is called" do
      expect do
        expect(@voter.clear_vote!(@voteable)).to eql false
      end.not_to raise_error
    end

    it 'raise an error for an invalid voteable' do
      invalid_voteable = InvalidVoteableModel.create
      expect do
        @voter.clear_vote(invalid_voteable)
      end.to raise_error(RedisVoteable::Exceptions::InvalidVoteableError)
    end
  end
end
