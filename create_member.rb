require 'json'
require 'faraday'
require 'faraday_middleware'

file = File.open("./bbhs_97.json")
members = JSON.parse(File.read(file))


conn = Faraday.new(:url => 'http://localhost:4567') do |faraday|
  faraday.request  :json
  faraday.response :json, content_type: /\bjson$/
  faraday.adapter  Faraday.default_adapter
end

members.each do |member|
  conn.post do |req|
    req.url '/api/v1/members'
    req.headers['Content-Type'] = 'application/json'
    req.body = member.to_json
  end
  sleep 5
end

# conn.post do |req|
#   req.url '/api/v1/members'
#   req.headers['Content-Type'] = 'application/json'
#   req.body = members.first.to_json
# end

# https://bbhs-97-api.herokuapp.com