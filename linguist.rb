#!/usr/bin/env puma

require 'json'
require 'linguist'

environment 'production'
#quiet
bind 'ssl://0.0.0.0:25032?key=/app/server.key&cert=/app/server.crt&verify_mode=none'

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
def checkheader (env, auth)
	value = env['HTTP_AUTHORIZATION']
   return value == auth
end

auth = ENV['PP_LINGUIST_AUTH'] || '1234'

app do |env|
   case env['REQUEST_PATH']
   when /check-status/
      [200, { 'Content-Type' => 'text/plain' }, ['OK']]
   when /detect/
      begin
         if checkheader(env, auth) == false
            body = { :success => false, :message => 'unauthorized' }.to_json
            [401, { 'Content-Type' => 'application/json' }, [body]]
         else
            msg = JSON.parse env['rack.input'].read
            body = { :success => true, :results => msg.collect { |entry| process(entry) } }.to_json
            [200, { 'Content-Type' => 'application/json' }, [body]]
         end
      rescue => e
         puts e.backtrace
         body = { :success => false, :message => e }.to_json
         [500, { 'Content-Type' => 'application/json' }, [body]]
      end
   when /languages/
      if checkheader(env, auth) == false
         body = {
            :success => false,
            :message => 'unauthorized'
         }.to_json
         [401, { 'Content-Type' => 'application/json' }, [body]]
		else
			results = {}
			results = Linguist::Language.all.map do |lang|
				results[lang.name] = languageToJSON(lang)
			end
			body = { :success => true, :results => results }.to_json
         [200, { 'Content-Type' => 'application/json' }, [body]]
		end
   else
      [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
   end
end

puts "Linguist is running version #{ENV['LINGUIST_VERSION']}"
