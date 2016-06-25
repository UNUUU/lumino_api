# coding: utf-8
require 'sinatra'
require 'json'
require 'mongo'

$stdout.sync = true

class Time
  def timezone(timezone = 'UTC')
    old = ENV['TZ']
    utc = self.dup.utc
    ENV['TZ'] = timezone
    output = utc.localtime
    ENV['TZ'] = old
    output
  end
end

before do
  @database = Mongo::Client.new(ENV['MONGO_URL'])
end

get '/' do
  # begin
  #   pushNotification('123456', 'Hello, world')
  #   status 202
  # rescue => e
  #   puts e.message
  #   status 400
  # end
  # upsertNotificationToken('123456', 'abcdefg')
end

put '/:user_id/notification' do
  user_id = params[:user_id]
  token = params[:token]
  upsertNotificationToken(user_id, token)
end

get '/:user_id/notification/history' do
  user_id = params[:user_id]
  messageList = findNotificationHistory(user_id).map {|history|
    if history[:created_at].nil? then
      created_at = ""
    else
      created_at = history[:created_at].timezone('Asia/Tokyo').strftime("%Y-%m-%d %H:%M:%S")
    end
    "#{history[:message]} #{created_at}"
  }.sort {|a, b| b <=> a }
  content_type :json
  messageList.to_json
end

post '/:user_id/display' do
  user_id = params[:user_id]
  message = params[:message]
  pushNotification(user_id, message)
end

def upsertNotificationToken(user_id, token)
  @database[:notification].find_one_and_replace({:user_id => user_id},
                                                 {'$set' => {:token => token}},
                                                 {:upsert => true})
end

def findNotificationToken(user_id)
  doc = @database[:notification].find(:user_id => user_id).first
  if doc.nil? then
    return nil
  end
  doc[:token]
end

def insertNotificationHistory(user_id, message)
  @database[:notification_history].insert_one({:user_id => user_id, :message => message, :created_at => Time.now()})
end

def findNotificationHistory(user_id)
  @database[:notification_history].find({:user_id => user_id})
end

def pushNotification(user_id, message)
  token = findNotificationToken(user_id)
  if token.nil? then
    raise 'not found notification token'
  end
  insertNotificationHistory(user_id, message)
  # TODO プッシュ通知を送る
  puts "token: #{token}, message: #{message}"
end
