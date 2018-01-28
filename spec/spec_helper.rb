# spec/spec_helper.rb
#
require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]
)
SimpleCov.start

require 'rubygems'
require 'bundler'
require 'logger'
require 'rspec'
require 'active_record'
require 'database_cleaner'
require 'pry'
pwd = File.dirname(__FILE__).freeze
$LOAD_PATH.unshift(pwd + '/../lib')
require 'redis_voteable'

RedisVoteable.redis_voteable_settings = {
  'host'               => 'localhost',
  'port'               => 9736,
  'reconnect_attempts' => 1,
  'scheme'             => 'redis',
  'tcp_keepalive'      => 0,
  'timeout'            => 0.3,
  'key_prefix'         => 'v:'
}

ActiveRecord::Base.logger = Logger.new(pwd + '/debug.log')
ActiveRecord::Base.configurations = YAML.load_file(pwd + '/database.yml')
ActiveRecord::Base.establish_connection(ENV['DB'] || :sqlite3)

ActiveRecord::Migration.verbose = false
load(pwd + '/schema.rb')
load(pwd + '/models.rb')

tmp = pwd + '/../tmp'
REDIS_PID = File.join(tmp, 'redis-test.pid')
REDIS_CACHE_PATH = File.join(tmp).to_s + '/'

redis_options = {
  'daemonize'     => 'yes',
  'pidfile'       => REDIS_PID,
  'port'          => 9736,
  'timeout'       => 300,
  'save 900'      => 1,
  'save 300'      => 1,
  'save 60'       => 10_000,
  'dbfilename'    => 'dump.rdb',
  'dir'           => REDIS_CACHE_PATH,
  'loglevel'      => 'debug',
  'logfile'       => 'stdout',
  'databases'     => 16
}.map { |k, v| "#{k} #{v}" }.join("\n")

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.filter_run_excluding exclude: true

  config.mock_with :rspec

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean
    `echo '#{redis_options}' | redis-server -`
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.after(:suite) do
    `
      cat #{REDIS_PID} | xargs kill -QUIT
      rm -f #{REDIS_CACHE_PATH}dump.rdb
    `
  end
end
