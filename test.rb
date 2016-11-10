


credentials = {:token => 'XXX',
:user => 'jdoe',
:password => 'password'}
url = 'https://localhost:8443'
tenant = 'hawkular'
file = 'CA.crt'

# -------------

require 'openssl'
require 'hawkular/hawkular_client'


hash = {}
hash[:entrypoint] = url
hash[:credentials] = credentials
hash[:options] = { :tenant => tenant,
                   :verify_ssl => OpenSSL::SSL::VERIFY_NONE
}

metrics_client = ::Hawkular::Client.new(hash)
puts metrics_client.fetch_version_and_status