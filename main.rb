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
      if val == "ace"
        sum1 += 1
      else
        sum1 += (val.to_i == 0 ? 10 : val.to_i)    
      end
    end

    if face_values.include? "ace"
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

  def loser!(msg)
    @loser = "<strong>#{session[:p_name]} loses!</strong> \n #{msg}"
    session[:bet_total] -= session[:bet].to_f
    @show_hit_or_stay_buttons = false
    @show_continue_button = true
  end

  def winner!(msg)
    @winner = "<strong>#{session[:p_name]} Wins!</strong> \n #{msg}"
    session[:bet_total] += session[:bet].to_f
    @show_hit_or_stay_buttons = false
    @show_continue_button = true
  end

  def tie!(msg)
    @winner = "<strong>It's a tie!</strong> \n #{msg}"
    @show_hit_or_stay_buttons = false
    @show_continue_button = true
  end
  
  def busted!(msg)
    if session[:player_sum] > 21
     @loser = "<strong>#{session[:p_name]} Busted!</strong> \n #{msg}"
     session[:bet_total] -= session[:bet].to_f
    else
      @winner = "<strong>#{session[:p_name]} Wins!</strong> \n #{msg}"
      session[:bet_total] += session[:bet].to_f
    end
    @show_hit_or_stay_buttons = false
    @show_continue_button = true
  end

  def blackjack!
    if session[:player_sum] == 21
      @winner = "<strong>#{session[:p_name]} hit Blackjack!</strong> \n #{session[:p_name]} wins bet and a half"
      session[:bet_total] += session[:bet].to_f*1.5
    else
      @loser = "<strong>Dealer hit Blackjack! #{session[:p_name]} loses"
      session[:bet_total] -= session[:bet].to_f
    end
    @show_hit_or_stay_buttons = false
    @show_continue_button = true
  end

  def integer?(str)
    /\A[+]?\d+\z/ === str
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
    @error = "<h3>Name can't be empty. Please enter a valid name.</h3>"
     erb :player_name
  else
    session[:p_name] = params[:p_name]
    session[:bet_total] = 500.00
    redirect '/bet'
  end
end

get '/bet' do
  if session[:bet_total] != 0.0
    erb :bet
  else
    @error = "<h3>#{session[:p_name]} has no money left.</h3>"
    @show_continue_button = true
    erb :bet
  end
end

post '/bet'do
  if params[:bet].to_f > session[:bet_total]
    @error = "<h3><strong>Insufficient credit #{session[:p_name]}</strong>, lower your bet.</h3>"
    halt erb(:bet)
  elsif !integer?(params[:bet])
    @error = "<h3><strong>Be Serious, enter a positive whole number as your bet.</strong></h3>"
    halt erb(:bet)
  elsif params[:bet].to_f == 0.0
    @error = "<h3><strong>#{session[:p_name]}, You've got to bet some to win some!</strong></h3>"
    halt erb(:bet)
  end

  session[:bet] = params[:bet]
  redirect '/game'
end

get '/game' do
  session[:turn] = session[:player_name]
  # create a deck in the session
  suits = ['H', 'D', 'C', 'S']
  values = ['2','3', '4', '5', '6', '7', '8', '9', '10', 'jack', 'queen', 'king', 'ace']
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

  # adding code to capture Blackjack 

  if @p_totals[1] == 21 && @d_totals[1] != 21
    session[:player_sum] = @p_totals[1]
    blackjack!
    erb :game
  elsif @p_totals[1] != 21 && @d_totals[1] == 21
  #  session[:dealer_sum] = @d_totals[1]
    session[:player_sum] = @p_totals[0]
    blackjack!
    erb :game
  elsif @p_totals[1] == 21 && @d_totals[1] == 21
    tie!("Both #{session[:p_name]} and the dealer tied at #{session[:player_sum]}")
    erb :game
  else  
    if @p_totals[1] != 0
      if @p_totals[0] > 21 && @p_totals[1] > 21
        session[:player_sum] = @p_totals[0]
        busted!("#{session[:p_name]} busted at #{session[:player_sum]}")
        erb :game
      else
        erb :game
      end
    else
      session[:player_sum] = @p_totals[0]
      erb :game
    end
  end
end

post '/game/player/hit' do
  session[:p_cards] << session[:deck].pop

  @p_totals = total(session[:p_cards])

  if @p_totals[1] != 0
    if @p_totals[0] > 21 && @p_totals[1] > 21
      session[:player_sum] = @p_totals[0]
      busted!("#{session[:p_name]} busted at #{session[:player_sum]}")
      erb :game, layout: false
      
    elsif @p_totals[0] == 21 || @p_totals[1] == 21
      @show_hit_or_stay_buttons = false
      session[:player_sum] = 21
      redirect '/game/dealer/goes'
    else
      erb :game, layout: false
    end
  else
    if @p_totals[0] > 21
      session[:player_sum] = @p_totals[0]
      busted!("#{session[:p_name]} busted at #{session[:player_sum]}")
      erb :game, layout: false
    elsif @p_totals[0] == 21
      @show_hit_or_stay_buttons = false
      session[:player_sum] = 21
      redirect '/game/dealer/goes'
    else
      erb :game,  layout: false
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
    busted!("Dealer busted at #{session[:dealer_sum]}")
    erb :game, layout: false
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
  erb :game, layout: false
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
  if session[:dealer_sum] == session[:player_sum]
    tie!("Both #{session[:p_name]} and the dealer tied at #{session[:player_sum]}")
  elsif session[:dealer_sum] > session[:player_sum]
    loser!("#{session[:p_name]} has a total of #{session[:player_sum]}, and the dealer has #{session[:dealer_sum]}")
  else
    winner!("#{session[:p_name]} has a total of #{session[:player_sum]}, and the dealer has #{session[:dealer_sum]}")
  end
  erb :game, layout: false
end

post '/game/continue' do
  redirect '/bet'
end

post '/game/quit' do
  erb :quit
end