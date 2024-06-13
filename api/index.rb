require 'victor'
require 'net/http'
require 'json'
require 'uri'

Handler = Proc.new do |req, res|
  if req.query.has_key?("username")
    username = req.query["username"]
    gist_count = fetch_gist_count(username)
    message = "#{username}'s gist count is: #{gist_count}"
    status = 200
  else
    message = "Username not found"
    status = 404
  end

  theme = req.query["theme"] || "dark"
  width = calculate_width(message)
  colors = get_colors(theme)

  svg = Victor::SVG.new viewBox: "0 0 #{width} 20", height: '20'
  svg.rect x: 0, y: 0, width: width, height: 20, rx: 5, ry: 5, fill: colors[:background]
  svg.build do
    g font_size: 10, font_family: 'arial', fill: colors[:text] do
      text message, x: width / 2, y: 13.5, text_anchor: 'middle'
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
  text.length * 4.4 + 10
end

def get_colors(theme)
  if theme == "light"
    { background: '#FFFFFF', text: '#000000' }
  else
    { background: '#30363C', text: '#FFFFFF' }
  end
end
