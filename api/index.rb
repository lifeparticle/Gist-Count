require 'victor'
require 'net/http'
require 'json'

Handler = Proc.new do |req, res|
	puts "#{request.query}"
	username = "lifeparticle"
	param = "/users/#{username}/gists"
	BASE_URL = "https://api.github.com"
	gist_count = 0;
	begin
		#gist_ids.each do |gist_id|
		url = URI.parse(URI.escape(("#{BASE_URL}#{param}")))
		result = Net::HTTP.get_response(url)
		if result.is_a?(Net::HTTPSuccess)
			parsed = JSON.parse(result.body)
			gist_count += parsed.count
			puts "#{parsed.count}"
		end
		#end
	rescue Exception => e
		puts "#{"something bad happened"} #{e}"
	end

	svg = Victor::SVG.new width: 140, height: 100, style: { background: '#ddd' }

	svg.build do
		g font_size: 20, font_family: 'arial', fill: 'black' do
			text gist_count, x: 40, y: 50
		end
	end

	res.status = 200
	res['Content-Type'] = 'image/svg+xml'
	res.body = svg.render
end