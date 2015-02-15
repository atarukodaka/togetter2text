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
    post '/extract' do
      #url = "http://togetter.com/li/782106"
      url = h(params['url'])
      tg2t = Togetter2Text::Extractor.new
      erb tg2t.get_texts(url).join("<br>")
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
<h1>Togetter2Text</h1>
<hr>
<%= yield %>
</hr>
</body>
</html>

@@index
<form action="extract" method="post">
<input type="text" name="url" size=80>
<input type="submit">
</form>

