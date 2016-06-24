require 'sinatra'

$stdout.sync = true

get '/' do
end

post '/:id' do
  puts "send #{params[:message]} to #{params[:id]}"
end
