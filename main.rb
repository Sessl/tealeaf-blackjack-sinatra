require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do
 def total(cards)
    face_values = cards.map{|card| card[1]}

    sum1 = 0
    sum2 = 0

    face_values.each do |val|
      if val == "Ace"
        sum1 += 1
      else
        sum1 += (val.to_i == 0 ? 10 : val.to_i)    
      end
    end

    if face_values.include? "Ace"
       sum2 = sum1 + 10
    end

    return sum1, sum2
  end
end

get '/' do 
  if session[:p_name]
    redirect '/game'
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
  redirect '/game'
end

get '/game' do
  # create a deck in the session
  suits = ['H', 'D', 'C', 'S']
  values = ['2','3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King', 'Ace']
  session[:deck] = suits.product(values).shuffle!
  
  # initialize the hand arrays
  session[:d_cards] = []
  session[:p_cards] = []

  # deal the cards
  session[:d_cards] << session[:deck].pop
  session[:p_cards] << session[:deck].pop
  session[:d_cards] << session[:deck].pop
  session[:p_cards] << session[:deck].pop
  
  erb :game
end