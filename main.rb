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

  def dealer_total(arr)
    if arr[1] != 0
      if arr[1] > 21
        sum = arr[0]
      elsif arr[1] == 21
        sum = 21
      else
        sum = arr[1]
      end
    else
      sum = arr[0]
    end
    
    return sum
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image' >"
  end
end

before do
  @show_hit_or_stay_buttons = true
  @show_dealer_button = false
  @show_continue_button = false
end

get '/' do 
  if session[:p_name]
    redirect '/game'
  else
    redirect '/set_name'
  end
end

get '/set_name' do
  erb :player_name
end

post '/set_name' do
  if params[:p_name] == ""
    @error = "Name can't be empty. Please enter a valid name"
     erb :player_name
  else
    session[:p_name] = params[:p_name]
    redirect '/game'
  end
end

get '/game' do
  session[:turn] = session[:player_name]
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

  @p_totals = total(session[:p_cards])  
  @d_totals = total(session[:d_cards])

  
  session[:dealer_sum] = dealer_total(@d_totals)

  if @p_totals[1] != 0
    if @p_totals[0] > 21 && @p_totals[1] > 21
      @show_hit_or_stay_buttons = false
      @show_continue_button = true
      @error = "You are busted!"
      session[:player_sum] = @p_totals[0]
      erb :game
    elsif @p_totals[1] == 21
      @show_hit_or_stay_buttons = false
      session[:player_sum] = 21
      redirect '/game/dealer/goes'
    else
      erb :game
    end
  else
      session[:player_sum] = @p_totals[0]
      erb :game
  end
 
end

post '/game/player/hit' do
  session[:p_cards] << session[:deck].pop

  @p_totals = total(session[:p_cards])

  if @p_totals[1] != 0
    if @p_totals[0] > 21 && @p_totals[1] > 21
      @show_hit_or_stay_buttons = false
      @show_continue_button = true
      @error = "You are busted!"
      session[:player_sum] = @p_totals[0]
      erb :game
    elsif @p_totals[0] == 21 || @p_totals[1] == 21
      @show_hit_or_stay_buttons = false
      session[:player_sum] = 21
      redirect '/game/dealer/goes'
    else
      erb :game
    end
  else
    if @p_totals[0] > 21
      @show_hit_or_stay_buttons = false
      @show_continue_button = true
      @error = "You are busted!"
      session[:player_sum] = @p_totals[0]
      erb :game
    elsif @p_totals[0] == 21
      @show_hit_or_stay_buttons = false
      session[:player_sum] = 21
      redirect '/game/dealer/goes'
    else
      erb :game
    end
  end
  
end

post '/game/player/stay' do
  @show_hit_or_stay_buttons = false

  @p_totals = total(session[:p_cards])

  if (@p_totals[1] > @p_totals[0]) && (@p_totals[1] <= 21)
      session[:player_sum] = @p_totals[1]
  else
      session[:player_sum] = @p_totals[0]
  end
  
  redirect '/game/player/stay'
  
end

get '/game/player/stay' do
  redirect '/game/dealer/goes'

end

get '/game/dealer/goes' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false
  @show_continue_button = true
  if session[:dealer_sum] > 21
    @success = "Dealer bust you win"
    erb :game
  elsif session[:dealer_sum] == 21 
    redirect '/game/who_won'
  elsif session[:dealer_sum] < 17
    redirect '/game/dealer/hit'
  else
    redirect '/game/dealer/stays'
  end
end

get '/game/dealer/hit' do
  @show_dealer_button = true
  @show_hit_or_stay_buttons = false
  erb :game
end

post '/game/dealer/hit' do
 session[:d_cards] << session[:deck].pop 
 @d_totals = total(session[:d_cards])
 session[:dealer_sum] = dealer_total(@d_totals)
 redirect '/game/dealer/goes'
end

get '/game/dealer/stays' do
  redirect '/game/who_won'
end

get '/game/who_won' do
  @show_dealer_button = false
  @show_hit_or_stay_buttons = false
  @show_continue_button = true
  if session[:dealer_sum] == session[:player_sum]
    @error = "It's a push"
  elsif session[:dealer_sum] > session[:player_sum]
    @error = "Sorry dealer wins"
  else
    @success = "Congratulations you win"
  end
  erb :game
end

post '/game/continue' do
  redirect '/game'
end

post '/game/quit' do
  erb :quit
end