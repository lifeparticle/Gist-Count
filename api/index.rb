require 'victor'
require 'net/http'
require 'json'

Handler = Proc.new do |req, res|
	svg = Victor::SVG.new width: 200, height: 200, style: { background: '#ddd' }

	if req.query["username"]
		username = req.query["username"]
		page = 1;
		param = "/users/#{username}/gists?per_page=100?page=#{page}"
		BASE_URL = "https://api.github.com"
		gist_count = 0;

		begin
			while true
				url = URI.parse(URI.escape(("#{BASE_URL}#{param}")))
				result = Net::HTTP.get_response(url)
				if result.is_a?(Net::HTTPSuccess)
					parsed = JSON.parse(result.body)
					break if parsed.count == 0
					gist_count += parsed.count
					page += 1
					puts "#{parsed.count}"
				end
			end
		rescue Exception => e
			puts "#{"something bad happened"} #{e}"
		end

		svg.build do
			g font_size: 20, font_family: 'arial', fill: 'black' do
				text gist_count, x: 10, y: 10
			end
		end

		res.status = 200
		res['Content-Type'] = 'image/svg+xml'
		res.body = svg.render
	else

		svg.build do
			g font_size: 20, font_family: 'arial', fill: 'black' do
				text "username name not found", x: 10, y: 10
			end
		end

		res.status = 404
		res['Content-Type'] = 'image/svg+xml'
		res.body = svg.render
	end
end