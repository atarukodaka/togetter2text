# -*- coding: utf-8 -*-
require 'sinatra/base'
require 'sinatra/reloader'

require './togetter2text'

module Togetter2Text
  class Application < Sinatra::Application
    register Sinatra::Reloader
    enable :inline_templates
    include ERB::Util

    get '/' do
      erb :index
    end
    get '/li/:togetter_id' do
      raise "invalid togetter id" unless params["togetter_id"] =~ /^\d+$/
      tg2t = Togetter2Text::Extractor.new(params['togetter_id'])
      url = "http://togetter.com/li/#{params['togetter_id']}"
      erb tg2t.get_texts(url).join("<br>")
    end
    post '/extract' do
      #url = "http://togetter.com/li/782106"
      tg2t = Togetter2Text::Extractor.new(params['url_or_id'])
      text = tg2t.get_texts.join("\n")
      date = Time.now.strftime("%Y/%m/%d")
      title = tg2t.title
      erb :text, locals: {date: date, title: title, content: text}
    end
  end # class
end # module

__END__
@@layout
<html>
<head>
 <title>Togetter2Text</title>
</head>
<body>
<%= yield %>
</body>
</html>
@@index
<h1>Togetter2Text</h1>
<hr>
<form action="extract" method="post">
Togetter ID or URL: <input type="text" name="url_or_id" size=80>
<input type="submit">
</form>
</hr>
@@text
<pre>
title: <%= title %>
date: <%= date %>
category: 

<%= content %>
</pre>

