require 'victor'
require 'net/http'
require 'json'
require 'uri'

Handler = Proc.new do |req, res|
  if req.query.has_key?("username")
    username = req.query["username"]
    gist_count = fetch_gist_count(username)
    message = gist_count.to_s
    status = 200
  else
    message = "Username not found"
    status = 404
  end

  theme = req.query["theme"] || "dark"
  left_width = 75
  right_width = calculate_width(message)
  colors = get_colors(theme)

  svg = Victor::SVG.new viewBox: "0 0 #{left_width + right_width} 20", height: '20'
  add_gradient(svg) if theme == "light"
  svg.rect x: 0, y: 0, width: left_width, height: 20, fill: '#595959'
  svg.rect x: left_width, y: 0, width: right_width, height: 20, fill: colors[:background]
  svg.build do
    g font_size: 10, font_family: 'Verdana, Arial, sans-serif', fill: colors[:left_text] do
      text 'Gist count', x: left_width / 2, y: 13.5, text_anchor: 'middle'
    end
    g font_size: 10, font_family: 'Verdana, Arial, sans-serif', fill: colors[:text], text_shadow: colors[:shadow] do
      text message, x: left_width + right_width / 2, y: 13.5, text_anchor: 'middle'
    end
  end

  res.status = status
  res['Cache-Control'] = "public, max-age=#{86_400}"
  res['Content-Type'] = 'image/svg+xml'
  res.body = svg.render
end

def fetch_gist_count(username)
  gist_count = 0
  page = 1
  base_url = "https://api.github.com"

  loop do
    params = "/users/#{URI.encode_www_form_component(username)}/gists?page=#{page}"
    url = URI("#{base_url}#{params}")
    result = Net::HTTP.get_response(url)
    break unless result.is_a?(Net::HTTPSuccess)

    parsed = JSON.parse(result.body)
    break if parsed.empty?

    gist_count += parsed.count
    page += 1
  end

  gist_count
rescue => e
  puts "Error fetching gist count: #{e}"
  "Error"
end

def calculate_width(text)
  text.length * 7 + 20
end

def get_colors(theme)
  if theme == "light"
    { background: 'url(#grad1)', text: '#9B9B9B', shadow: '0.5px 0.5px 1px #CCC', left_text: '#FFFFFF' }
  else
    { background: '#30363C', text: '#FFFFFF', shadow: '', left_text: '#FFFFFF' }
  end
end

def add_gradient(svg)
  svg.build do
    defs do
      linearGradient id: "grad1", x1: "0%", y1: "0%", x2: "0%", y2: "100%" do
        stop offset: "0%", style: "stop-color:rgb(255,255,255);stop-opacity:1" 
        stop offset: "100%", style: "stop-color:rgb(200,200,200);stop-opacity:1" 
      end
    end
  end
end
