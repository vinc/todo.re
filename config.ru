require './app'
require 'rack/parser'

use Rack::Parser
run Sinatra::Application
