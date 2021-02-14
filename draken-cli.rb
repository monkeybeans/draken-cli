#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |o|
    options[:verbose] = o
  end

  opts.on("-s", "--search", "Perform search") do |o|
    options[:search] = o
  end
end.parse!

#p options
#p ARGV

#https://cms.drakenfilm.se/movies?_limit=42&_start=0&_sort=title:ASC&title_contains=a
#https://cms.drakenfilm.se/movies?_start=0&_sort=title:ASC"
DRAKEN_HOST="https://www.drakenfilm.se/"

api = Net::HTTP.new('cms.drakenfilm.se', 443)
api.use_ssl = true

#args = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]args = Hash[ ARGV.join(' ')]

#puts args

if options[:search]
    if ARGV.length == 0
        puts "Missing search query"
        return
    end
    search = ARGV.join(' ')
    query = [
        "_limit=100",
        "_start=0",
        "_sort=title:ASC",
        "title_contains=#{URI.escape(search)}"
    ].join('&')

    res = api.get("/movies?#{query}")

    if res.is_a?(Net::HTTPSuccess)
        movies = JSON.parse(res.body)
        movies.each do |movie|
            puts "# #{movie['title']}"
            if options[:verbose]
                puts movie['synopsis']
                puts "#{DRAKEN_HOST}film/#{movie['slug']}"
                puts
            end
        end

        puts "#{}"
    else
        puts "[err] msg: #{res}"
    end
end
