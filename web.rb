# coding: utf-8
require 'sinatra'

$stdout.sync = true

get '/' do
end

put '/:id/notification' do
  notification_token = params[:token:]
  # TODO IDと紐づけてデータベースに保存する
end

post '/:id/display' do
  puts "send #{params[:message]} to #{params[:id]}"
  # TODO IDから通知トークンをひいてきてプッシュ通知を送る
end

