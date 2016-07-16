
raise 'This needs JRuby to run' unless RUBY_PLATFORM == 'java'
raise 'This needs JRuby version 9.1' unless JRUBY_VERSION >= "9.1.2"

source 'https://rubygems.org'

gem 'jrubyfx', :require => true

# gem 'hawkular-client', :require => true, path: '/h/ruby-client-heiko'
gem 'hawkular-client', :require => true, :git => 'https://github.com/pilhuhn/hawkular-client-ruby.git', :branch => 'complete-ops-definitions'
# gem 'hawkular-client', '~> 2.2.1', :require => true
gem 'addressable'

gem 'rest-client'
gem 'websocket-client-simple', '~> 0.3.0'
gem 'shoulda'
gem 'rspec-rails', '~> 3.0'
gem 'rake', '< 11'
gem 'simple-websocket-vcr', '= 0.0.4'
gem 'yard'
gem 'webmock'
gem 'vcr'
gem 'rubocop', '= 0.34.2'
