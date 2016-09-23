
fail 'This needs JRuby to run' unless RUBY_PLATFORM == 'java'
fail 'This needs JRuby version 9.1' unless JRUBY_VERSION >= '9.1.2'

source 'https://rubygems.org'

gem 'jrubyfx', :require => true

# gem 'hawkular-client', :require => true, path: '/h/ruby-client-heiko'
gem 'hawkular-client',
    :require => true,
    :git => 'https://github.com/pilhuhn/hawkular-client-ruby.git',
    :branch => 'string_metrics'
# gem 'hawkular-client', '~> 2.7.0', :require => true
gem 'addressable'

gem 'rest-client'
gem 'websocket-client-simple', '~> 0.3.0'
gem 'shoulda'
gem 'rspec'
gem 'rspec-mocks'
gem 'rake', '< 11'
gem 'simple-websocket-vcr', '= 0.0.4'
gem 'yard'
gem 'webmock'
gem 'vcr'
gem 'rubocop', '= 0.41.2'

gem 'treetop'
