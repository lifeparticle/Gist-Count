require 'victor'
require 'net/http'
require 'json'

Handler = Proc.new do |req, res|
	svg = Victor::SVG.new width: 200, height: 200, style: { background: '#ddd' }
	if req.query.has_key?(:username)
		username = req.query["username"]
		gist_count = 0;
		page = 1;
		# per_page = 100; # not working with page number, it's returing 30 per per page when used with page param
		BASE_URL = "https://api.github.com"

		begin
			while true
				params = "/users/#{username}/gists?page=#{page}"
				url = URI.parse(URI.escape(("#{BASE_URL}#{params}")))
				result = Net::HTTP.get_response(url)
				puts "#{url}"
				if result.is_a?(Net::HTTPSuccess)
					parsed = JSON.parse(result.body)
					break if parsed.count == 0
					gist_count += parsed.count
					page = page + 1
					puts "#{page}"
					puts "#{parsed.count}"
				else
					gist_count = "#{result}"
					break
				end
				sleep 5
			end
		rescue Exception => e
			puts "#{"something bad happened"} #{e}"
		end

		svg.build do
			g font_size: 20, font_family: 'arial', fill: 'black' do
				text gist_count, x: 20, y: 20
			end
		end

		puts "#{parsed.count}"

		res.status = 200
		res['Content-Type'] = 'image/svg+xml'
		res.body = svg.render
	else

		svg.build do
			g font_size: 20, font_family: 'arial', fill: 'black' do
				text "username name not found", x: 20, y: 20
			end
		end

		res.status = 404
		res['Content-Type'] = 'image/svg+xml'
		res.body = svg.render
	end
end

Handler.call