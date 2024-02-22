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

  width = calculate_width(message)

  svg = Victor::SVG.new width: width, height: 30, style: { background: '#30363C' }
  svg.rect x: 0, y: 0, width: width, height: 30, rx: 5, fill: '#30363C'
  svg.build do
    g font_size: 12, font_family: 'arial', fill: 'white' do
      text message, x: 10, y: 20
    end
  end

  res.status = status
  # res['Cache-Control'] = "public, max-age=#{86_400}"
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
  text.length * 6
end
