#!/usr/bin/env ruby
#
# A simple Webserver that can be run to process requests
# for the Linguist library.
#
require 'json'
require 'webrick'
require 'webrick/https'
require 'linguist'

class MemoryBlob
	include Linguist::BlobHelper
	attr_reader :path
	attr_reader :name
	attr_reader :data
	attr_reader :size

	def initialize (path, data)
		@path = path
		@name = path
		@data = data
		@size = data.length
	end
end

#
# turn a Linguist::Language instance into a nice object
# that can be turned into JSON
#
def languageToJSON (language)
	if language
		{
			:name => language.name,
			:type => language.type,
			#:color => language.color,
			#:aliases => language.aliases,
			#:wrap => language.wrap,
			:group => language.group,
			:ace_mode => language.ace_mode,
			#:extensions => language.extensions,
			:is_popular => language.popular?,
			:is_unpopular => language.unpopular?,
			#:is_searchable => language.searchable?
		}
	end
end

#
# turn a Linguist::FileBlob instance into a nice object
# that can be turned into JSON
#
def detailsToJSON (langDetails)
	type = if langDetails.text?
		'text'
	elsif langDetails.image?
		'image'
	else
		'binary'
	end

	generated = if langDetails.generated?
		true
	else
		false
	end

	{
		:path => langDetails.path,
		:loc => langDetails.loc,
		:sloc => langDetails.sloc,
		:type => type,
		:extname => langDetails.extname,
		:mime_type => langDetails.mime_type,
		:content_type => langDetails.content_type,
		:disposition => langDetails.disposition,
		:is_documentation => langDetails.documentation?,
		:is_large => langDetails.large?,
		:is_generated => generated,
		:is_text => langDetails.text?,
		:is_image => langDetails.image?,
		:is_binary => langDetails.binary?,
		:is_vendored => langDetails.vendored?,
		:is_high_ratio_of_long_lines => langDetails.high_ratio_of_long_lines?,
		:is_viewable => langDetails.viewable?,
		:is_safe_to_colorize => langDetails.safe_to_colorize?,
		:language => languageToJSON(langDetails.language)
	}
end

#
# given an object with path and body, return an Object which can
# easily be turned into JSON
#
def process (entry)
	detailsToJSON(MemoryBlob.new(entry["name"], entry["body"]))
end

#
# check our request header for the appropriate auth token
#
def checkheader (req, auth)
	value = req.header["authorization"]
	if value && value[0] == auth
		return true
	end
	return false
end

#
# run the main webserver
#
def main (auth = '1234', port = 25032)
	puts "Auth token is #{auth}"
	puts "Listening on port #{port}"
	STDOUT.flush

	cert_name = [
		%w[CN localhost],
		%w[CN linguist],
	]

	devnull = WEBrick::Log::new("/dev/null", 7)

	access_log = [
		[$stdout, WEBrick::AccessLog::COMMON_LOG_FORMAT],
	]

	#
	# create a server
	#
	server = WEBrick::HTTPServer.new(
		:BindAddress => '0.0.0.0',
		:SSLEnable => true,
		:SSLCertName => cert_name,
		:Port => port,
		:DoNotReverseLookup => true,
		:Logger => devnull,
		:AccessLog => access_log)

	#
	# handle detection of one or more files
	#
	server.mount_proc '/check-status' do |req, res|
		res.content_type = 'text/plain'
		res.status = 200
		res.body = 'OK'
	end

	#
	# handle detection of one or more files
	#
	server.mount_proc '/detect' do |req, res|
		res.content_type = 'application/json'
		if checkheader(req, auth) == false
			res.status = 401
			res.body = {
				:success => false,
				:message => 'unauthorized'
			}.to_json
		else
			if req.request_method == 'POST'
				begin
					res.body = {
						:success => true,
						:results => JSON.parse(req.body).collect { |entry| process(entry) }
					}.to_json
				rescue => e
					puts e.backtrace
					res.status = 500
					res.body = {
						:success => false,
						:message => e
					}.to_json
				end
			else
				res.status = 400
				res.body = {
					:success => false,
					:message => 'invalid request'
				}.to_json
			end
		end
	end

	#
	# handle returning all the currently known languages we support
	#
	server.mount_proc '/languages' do |req, res|
		res.content_type = 'application/json'
		if checkheader(req, auth) == false
			res.status = 401
			res.body = {
				:success => false,
				:message => 'unauthorized'
			}.to_json
		else
			results = {}
			results = Linguist::Language.all.map do |lang|
				results[lang.name] = languageToJSON(lang)
			end
			res.body = {
				:success => true,
				:results => results
			}.to_json
		end
	end

	# start the server and handle graceful shutdown requests
	trap 'INT' do server.shutdown end
	server.start

	server
end

main(ARGV[0] || ENV['PP_LINGUIST_AUTH'] || '1234', ARGV[1] || ENV['PP_LINGUIST_PORT'] || 25032)
