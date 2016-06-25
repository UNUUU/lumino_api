# coding: utf-8
require 'sinatra'
require 'mongo'

$stdout.sync = true

before do
  @database = Mongo::Client.new(ENV['MONGO_URL'])
end

get '/' do
  begin
    pushNotification(findNotificationToken('123456'), 'Hello, world')
    status 202
  rescue => e
    puts e.message
    status 400
  end
end

put '/:user_id/notification' do
  user_id = params[:id]
  token = params[:token]
  upsertNotificationToken(user_id, token)
end

post '/:user_id/display' do
  user_id = params[:user_id]
  message = params[:message]
  pushNotification(findNotificationToken(user_id), message)
end

def upsertNotificationToken(user_id, token)
  @database[:notifications].find_one_and_replace({:user_id => user_id},
                                                 {'$set' => {:token => token}},
                                                 {:upsert => true})
end

def findNotificationToken(user_id)
  doc = @database[:notifications].find(:user_id => user_id).first
  if doc.nil? then
    return nil
  end
  doc[:token]
end

def pushNotification(token, message)
  if token.nil? then
    raise 'not found notification token'
  end
    puts "token: #{token}, message: #{message}"
  # TODO プッシュ通知を送る
end
