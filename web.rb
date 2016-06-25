# coding: utf-8
require 'sinatra'
require 'json'
require 'mongo'
require 'net/https'

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
end

put '/:user_id/notification' do
  user_id = params[:user_id]
  token = params[:token]
  upsertNotificationToken(user_id, token)
  status 201
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
  status 200
  content_type :json
  messageList.to_json
end

post '/:user_id/display' do
  user_id = params[:user_id]
  message = params[:message]

  begin
    pushNotification(user_id, message)
    status 202
  rescue => e
    puts e.message
    status 400
  end
end

def upsertNotificationToken(user_id, token)
  @database[:notification].find_one_and_update({:user_id => user_id},
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

  uri = URI.parse('https://fcm.googleapis.com/fcm/send')
  header = {
    'Content-Type' => 'application/json',
    'Authorization' => "key=#{ENV['FIREBASE_SERVER_KEY']}"
  }
  request = Net::HTTP::Post.new(uri.request_uri, initheader = header)
  request.body = {
    to: token,
    notification: {
      body: message,
      title: 'lumino'
    }
  }.to_json
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  http.set_debug_output $stderr

  response = nil
  http.start do |h|
    response = h.request(request)
  end
  return response
end
