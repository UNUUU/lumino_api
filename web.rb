require 'sinatra'

get '/' do
end

post '/:id' do
    "send #{params[:message]} to #{params[:id]}"
end
