#!/opt/puppetlabs/puppet/bin/ruby
#
# This task sets the state of a pool member to enabled or disabled, using the f5
# iControl REST API.
#
# This task requires several parameters to do its job.
#
# device_name:
#   The resolvable name of the f5 that you want to manage.
#
# device_port:
#  The port to connect to the API on.  Defaults to '443' if you omit it.
#
# api_user:
#   The username to authenticate to the API as.  Defaults to 'admin' if omitted.
#
# api_password:
#   The password to authenticate to the API with.  Defaults to 'admin'.
#
# pool_name:
#   The name of the pool to modify.
#
# partition_name:
#  Optional partition name to work on.  Defaults to "Common".
#
# member_name:
#   The name of the pool member to modify.
#
# member_state:
#   What state to put the pool member in, enabled, disabled, or offline

require 'net/http'
require 'openssl'
require 'json'

# Parse the task's parameters from JSON on STDIN.
# You must pass in device_name, node_name, and node_state.
# The api_user and api_password default to 'admin' if you don't supply them.
#
params = JSON.parse(STDIN.read)
device_name        = params['device_name']
device_port        = params['device_port']    || '443'
api_user           = params['api_user']       || 'admin'
api_password       = params['api_password']   || 'admin'
pool_name          = params['pool_name']
partition_name     = params['partition_name'] || 'Common'
member_name        = params['member_name']
member_state       = params['member_state']
member_api_session = ''
member_api_state   = ''

# Take the node_state and turn it into the corresponding session and state
# settings that the API wants to see.
case member_state
when 'enabled'
  member_api_session = 'user-enabled'
  member_api_state   = 'user-up'
when 'disabled'
  member_api_session = 'user-disabled'
  member_api_state   = 'user-up'
when 'offline'
  member_api_session = 'user-disabled'
  member_api_state   = 'user-down'
end

# Make an HTTP object that's aimed at the f5 device we want to interact with
#
http = Net::HTTP.new(device_name, device_port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

# Craft a request to the API endpoint with proper credentials
#
request = Net::HTTP::Put.new("/mgmt/tm/ltm/pool/#{pool_name}/members/~#{partition_name}~#{member_name}")
request.basic_auth(api_user, api_password)

# Prepare to send JSON to the endpoint, to update the node's state
#
request['Content-Type'] = 'application/json'
request.body = "{\"session\":\"#{member_api_session}\",\"state\":\"#{member_api_state}\"}"

# Make the request and populate 'response' with the result
#
response = http.request(request)

# See what we've got here
#
if response.code == '401'     # Outputs ugly html, not a pretty JSON object
  puts '{"code":401,"message":"Authentication required"}'
  exit 1
elsif response.code != '200'  # Outputs properly-formed JSON
  puts response.body
  exit 1
else                          # It all worked
  puts response.body
  exit
end
