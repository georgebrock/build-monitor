require 'rubygems'
require 'sinatra'
require 'erb'

set :public, File.dirname(__FILE__) + '/public'

get '/' do
  erb :index
end
