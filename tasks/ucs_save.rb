#!/opt/puppetlabs/puppet/bin/ruby
#
# This task triggers a backup of the current configuration to a file named after
# today's date.
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
# file_path:
#   Optional, a full path to the location to store the backup in.  Defaults to
#   a file in /var/local/ucs named after the current date.

require 'net/http'
require 'openssl'
require 'json'
require 'date'

# Parse the task's parameters from JSON on STDIN.
# You must pass in device_name, node_name, and node_state.
# The api_user and api_password default to 'admin' if you don't supply them.
#
params = JSON.parse(STDIN.read)
device_name      = params['device_name']
device_port      = params['device_port']  || '443'
api_user         = params['api_user']     || 'admin'
api_password     = params['api_password'] || 'admin'
file_path        = params['file_path']    || '/var/local/ucs/backup-' + Date.today.strftime('%Y%m%d') + '.ucs'

# Make an HTTP object that's aimed at the f5 device we want to interact with
#
http = Net::HTTP.new(device_name, device_port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

# Craft a request to the API endpoint with proper credentials
#
request = Net::HTTP::Post.new('/mgmt/tm/sys/ucs')
request.basic_auth(api_user, api_password)

# Prepare to send JSON to the endpoint, to trigger a backup to the given
# file path.
#
request['Content-Type'] = 'application/json'
request.body = "{\"command\":\"save\",\"name\":\"#{file_path}\"}"

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
