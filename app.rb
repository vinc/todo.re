require 'json'
require 'yaml'

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

  #set :ttl, 60 * 30
  set :static_cache_control, [:public, :max_age => 60 * 60 * 24 * 30]

end

before do
  #expires settings.ttl, :public, :must_revalidate
  headers 'X-UA-Compatible' => 'IE=edge,chrome=1'
end

get '/' do
  if session[:uid]
    redirect to('/lists')
  else
    redirect to('/welcome')
  end
end

get '/lists' do
  slim :index
end

get '/settings' do
  slim :index
end

get '/welcome' do
  slim :welcome
end

get '/login' do # FIXME: Duplicate with '/'
  if session[:uid]
    redirect to('/lists')
  else
    redirect to('/welcome')
  end
end

get '/logout' do
  session.clear
  redirect to('/')
end

post '/login' do
  p params
  begin
    token = Token.create(params)
  rescue Mongoid::Errors::UnknownAttribute
    halt 406
  end
  Mail.deliver do
    to token.email
    from 'noreply@todo.re'
    subject 'Log in to TODO.re'
    body "http://todo.re:31337/login/#{token.id}"
  end
  slim :login
end

get '/login/:id' do |id|
  begin
    token = Token.find(id)
  rescue BSON::InvalidObjectId
    halt 406
  end
  @user = User.find_or_create_by(email: token.email)
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

get '/lists/?.json' do
  @user.lists.all.to_json
end

post '/lists/?.json' do
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
