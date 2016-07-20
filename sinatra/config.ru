# config.ru
require 'bundler'
Bundler.require

opal = Opal::Server.new {|s|
  s.append_path 'app'
  s.main = 'example'
}

sprockets   = opal.sprockets
prefix      = '/assets'
maps_prefix = '/__OPAL_SOURCE_MAPS__'
maps_app    = Opal::SourceMapServer.new(sprockets, maps_prefix)

# Monkeypatch sourcemap header support into sprockets
::Opal::Sprockets::SourceMapHeaderPatch.inject!(maps_prefix)

map maps_prefix do
  run maps_app
end

map prefix do
  run sprockets
end

get '/comments.json' do
  comments = JSON.parse(open("./_comments.json").read)
  JSON.generate(comments)
end

get '/comments.js' do
  content_type "application/javascript"
  comments = JSON.parse(open("./_comments.json").read)
  "window.initial_comments = #{JSON.generate(comments)}"
end

post "/comments.json" do
  comments = JSON.parse(open("./_comments.json").read)
  comments << JSON.parse(request.body.read)
  File.write('./_comments.json', JSON.pretty_generate(comments, :indent => '    '))
  JSON.generate(comments)
end

get '/' do
  <<-HTML
    <!doctype html>
    <html>
      <head>
        <title>Hello React</title>
        <link rel="stylesheet" href="base.css" />
        <script src="http://cdnjs.cloudflare.com/ajax/libs/showdown/0.3.1/showdown.min.js"></script>
        <script src="/comments.js"></script>
        #{::Opal::Sprockets.javascript_include_tag('example', sprockets: sprockets, prefix: prefix, debug: true)}
      </head>
      <body>
        <div id="content"></div>
      </body>
    </html>
  HTML
end

run Sinatra::Application
