require 'rubygems'
require 'sinatra'

set :sessions, true

get '/' do 
	code = "My name is Suchitra"
  erb code
  
end



get '/profile' do
  erb :profile
end

get '/subtest/login' do
  erb :'subtest/login'
end

get '/foo' do
  redirect to('/profile'), 303

end




