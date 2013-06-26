require 'json'
require 'securerandom'
require 'yaml'

require 'dalli'
require 'mail'
require 'mongoid'
require 'sass'
require 'slim'
require 'sinatra'
require 'sinatra/partial'
require 'sinatra/reloader' if development?

require './models'

module Mongoid
  module Errors
    class UnknownAttribute < MongoidError
    end
  end
end

configure :development do
  set :slim, :pretty => true
  set :css_style => :expanded
end

configure :production do
  set :css_style => :compressed
end

configure do
  Mongoid.load!('mongoid.yml') # FIXME
  Mail.defaults do
    delivery_method :sendmail
  end

  enable :sessions
  set :partial_template_engine, :slim

  set :cache, Dalli::Client.new
  #set :ttl, 60 * 30
  set :static_cache_control, [:public, :max_age => 60 * 60 * 24 * 30]

end

before do
  #expires settings.ttl, :public, :must_revalidate
  headers 'X-UA-Compatible' => 'IE=edge,chrome=1'
end

get '/' do
  if session.key?(:uid)
    redirect to('/lists')
  else
    redirect to('/welcome')
  end
end

get '/lists' do
  if session.key?(:uid)
    slim :index
  else
    redirect to('/login')
  end
end

get '/settings' do
  slim :index
end

get '/welcome' do
  slim :welcome
end

get '/logout' do
  session.clear
  redirect to('/')
end

get '/login' do # FIXME: Duplicate with '/'
  p session
  if session.key?(:uid)
    puts 'user is auth'
    redirect to('/lists')
  else
    slim :login, locals: {
      emailed: false
    }
  end
end

post '/login' do
  halt 406 unless params.has_key?('email')

  email = params['email']
  token = SecureRandom.uuid

  # Create a one-time password valid 24 hours
  key = "token:#{token}"
  val = email
  ttl = 60 * 60 * 24
  settings.cache.set(key, val, ttl)

  Mail.deliver do
    to email
    from 'TODO.re <noreply@todo.re>'
    subject 'Log in to TODO.re'
    body "http://todo.re:31337/login/#{token}"
  end

  slim :login, locals: {
    emailed: true
  }
end

get '/login/:token' do |token|
  key = "token:#{token}"
  email = settings.cache.get(key)

  # Token should exists
  halt 406 if email.nil?

  # Token should be destroyed after use
  settings.cache.delete(key)

  @user = User.find_or_create_by(email: email)
  session[:uid] = @user.id
  redirect to('/')
end

before '*.json' do
  content_type :json
  if session.include?(:uid)
    @user = User.find(session[:uid])
  elsif request.get?
    @user = User.where(email: 'alice@example.com').first
  else
    halt 403
  end
end

get '/settings.json' do
  settings = @user.attributes.select { |k| ['email'].include?(k) }
  settings.to_json
end

get '/lists.json' do
  @user.lists.all.to_json
end

post '/lists.json' do
  status 201
  params['tasks'] ||= [Task.new]
  begin
    @user.lists.create(params).to_json
  rescue Mongoid::Errors::UnknownAttribute
    halt 406
  end
end

get '/lists/:id.json' do |id|
  begin
    @user.lists.find(id).to_json
  rescue Mongoid::Errors::DocumentNotFound
    halt 404
  end
end

put '/lists/:id.json' do |id|
  status 204
  params.delete('splat')
  params.delete('captures')
  begin
    @user.lists.find(id).update_attributes!(params)
  rescue Mongoid::Errors::UnknownAttribute
    halt 406
  rescue Mongoid::Errors::DocumentNotFound
    halt 404
  end
  ''
end

delete '/lists/:id.json' do |id|
  status 204
  begin
    @user.lists.find(id).delete
  rescue Mongoid::Errors::DocumentNotFound
    halt 404
  end
end

get '/partials/*.html' do |template|
  slim :"partials/#{template}"
end

get '/styles/*.css' do |style|
  expires 60 * 60 * 24 * 31, :public, :must_revalidate
  scss :"styles/#{style}", :style => settings.css_style
end

error 400..599 do
  unless response.body[0] =~ /<html>/
    slim :error, locals: {
      message: response.body[0],
      status: status
    }
  end
end

error do
  case env['sinatra.error']
  when 'error' # FIXME
  else
    message = 'Looks like some kind of internal server error.'
    status 500
  end
  slim :error, locals: {
    message: message,
    status: status
  }
end

not_found do
  slim :error, locals: {
    message: 'You requested something that cannot be found.',
    status: status
  }
end
