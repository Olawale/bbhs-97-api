require 'sinatra'
require 'sinatra/namespace'
require 'mongoid'
require 'pry'

# DB setup
Mongoid.load!("mongoid.yml", :development)

class Member
  include Mongoid::Document

  field :first_name, type: String
  field :last_name, type: String
  field :nick_name, type: String
  field :occupation, type: String
  field :residence_country, type: String
  field :address, type: String
  field :image, type: String
  field :mobile_number, type: String
  field :day_of_birth, type: String
  field :month_of_birth, type: String
  field :email_address, type: String
  field :excoId, type: Boolean
  field :role, type: String

  validates :first_name, presence: true
  validates :last_name, presence: true
  # validates :occupation, presence: true
  validates :residence_country, presence: true

  index({first_name: 'text'})
  index({last_name: 'text'})
  index({index_name: 'text'})

  scope :first_name, -> (first_name) { where(first_name: first_name.downcase)}
  scope :last_name, -> (last_name) { where(last_name: last_name.downcase)}
  scope :nick_name, -> (nick_name) { where(nick_name: nick_name.downcase)}
  scope :residence_country, -> (residence_country) { where(residence_country: residence_country.downcase)}
end

class MemberSerializer
  def initialize(member)
    @member = member
  end

  def as_json(*)
    data = {
        id:@member.id.to_s,
        first_name:@member.first_name,
        last_name:@member.last_name,
        mobile_number:@member.mobile_number,
        nick_name:@member.nick_name,
        occupation:@member.occupation,
        address:@member.address,
        residence_country:@member.residence_country,
        day_of_birth:@member.day_of_birth,
        month_of_birth:@member.month_of_birth,
        image:@member.image,
        email_address:@member.email_address,
        excoId:@member.excoId,
        role:@member.role
    }
    data[:errors] = @member.errors if @member.errors.any?
    data
  end
end

namespace '/api/v1' do

  before do
    content_type 'application/json'
    # error 401 unless params[:key] == ENV['API_KEY']
  end

  helpers do
    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
    end

    def json_params
      begin
        JSON.parse(request.body.read)
      rescue
        halt 400, { message:'Invalid JSON' }.to_json
      end
    end

    def member
      @member ||= Member.where(id: params[:id]).first
    end

    def halt_if_not_found!
      halt(404, { message: 'Member Not Found'}.to_json) unless member
    end

    def serialize(member)
      MemberSerializer.new(member).to_json
    end
  end

  get '/members' do
    members = Member.all


    [:first_name, :last_name, :nick_name, :residence_country].each do |filter|
      members = members.send(filter, params[filter]) if params[filter]
    end

    members.map { |member| MemberSerializer.new(member) }.to_json
  end

  get '/members/:id' do |id|
    halt_if_not_found!
    serialize(member)
  end

  post '/members' do
    member = Member.new(json_params)
    halt 422, serialize(member) unless member.save
    response.headers['Location'] = "#{base_url}/api/v1/members/#{member.id}"
    status 201
  end

  patch '/members/:id' do |id|
    halt_if_not_found!
    halt 422, serialize(member) unless member.update_attributes(json_params)
    serialize(member)
  end

  delete '/members/id' do |id|
    # member = Member.where(id: id).first
    member.destroy if member
    status 204
  end
end

