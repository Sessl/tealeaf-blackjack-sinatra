require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

get '/' do 
  if session[:p_name]
    redirect '/bet'
  else
    redirect '/set_name'
  end
end

get '/set_name' do
  if session[:check]
    @error = "Name can't be empty. Please enter a valid name"
    erb :player_name
  else
    erb :player_name
  end
end

post '/set_name' do
  if params[:p_name] == ""
    session[:check] = 1
    redirect '/set_name'
  else
    session[:p_name] = params[:p_name]
  end
  redirect '/bet'
end

get '/bet' do
  erb :bet
end