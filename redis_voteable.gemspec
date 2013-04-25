# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "redis_voteable"
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Chris Brauchli"]
  s.date = "2011-09-30"
  s.description = "A Redis-backed voting extension for Rails applications. "
  s.email = ["cbrauchli@gmail.com"]
  s.files = [".gitignore", "Gemfile", "MIT-LICENSE", "README.md", "Rakefile", "lib/redis_voteable.rb", "lib/redis_voteable/exceptions.rb", "lib/redis_voteable/version.rb", "lib/redis_voteable/voteable.rb", "lib/redis_voteable/voter.rb", "redis_voteable.gemspec", "spec/database.yml", "spec/lib/redis_voteable_spec.rb", "spec/models.rb", "spec/schema.rb", "spec/spec_helper.rb"]
  s.homepage = "http://github.com/cbrauchli/redis_voteable"
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.3"
  s.summary = "Simple vote management with Redis used as the backend."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<redis>, [">= 2.2.0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_development_dependency(%q<activerecord>, ["~> 3.0.0"])
      s.add_development_dependency(%q<sqlite3>, ["~> 1.3.0"])
      s.add_development_dependency(%q<bundler>, [">= 1.0.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.0.0"])
      s.add_development_dependency(%q<database_cleaner>, ["~> 0.6.7"])
    else
      s.add_dependency(%q<redis>, [">= 2.2.0"])
      s.add_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_dependency(%q<activerecord>, ["~> 3.0.0"])
      s.add_dependency(%q<sqlite3>, ["~> 1.3.0"])
      s.add_dependency(%q<bundler>, [">= 1.0.0"])
      s.add_dependency(%q<rspec>, ["~> 2.0.0"])
      s.add_dependency(%q<database_cleaner>, ["~> 0.6.7"])
    end
  else
    s.add_dependency(%q<redis>, [">= 2.2.0"])
    s.add_dependency(%q<activesupport>, [">= 3.0.0"])
    s.add_dependency(%q<activerecord>, ["~> 3.0.0"])
    s.add_dependency(%q<sqlite3>, ["~> 1.3.0"])
    s.add_dependency(%q<bundler>, [">= 1.0.0"])
    s.add_dependency(%q<rspec>, ["~> 2.0.0"])
    s.add_dependency(%q<database_cleaner>, ["~> 0.6.7"])
  end
end
