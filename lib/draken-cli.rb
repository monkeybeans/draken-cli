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

  opts.on("--search-title", "Perform search") do |o|
    options[:title] = o
  end

  opts.on("--search-director", "Perform search") do |o|
    options[:directors] = o
  end

  opts.on("-r", "--random", "Random film for you") do |o|
    options[:random] = o
  end
end.parse!

DRAKEN_HOST="https://www.drakenfilm.se/"

api = Net::HTTP.new('cms.drakenfilm.se', 443)
api.use_ssl = true

def print_movie(movie, verbose)
    puts "# #{movie['title']}"
    if verbose
        puts "\n#{movie['synopsis']}\n\n" unless movie['synopsis'].nil?
        puts "directors: #{movie['directors'].join(', ')}" unless movie['directors'].nil?
        puts "cast:      #{movie['cast'].join(', ')}" unless movie['cast'].nil?
        puts "genres:    #{movie['genres'].join(', ')}" unless movie['genres'].nil?
        puts "country:   #{movie['countriesOfOrigin'].join(', ')}" unless movie['countriesOfOrigin'].nil?
        puts "length:    #{movie['duration']/60}min" unless movie['duration'].nil?
        puts
    end
    puts "#{DRAKEN_HOST}film/#{movie['slug']}"
end

#ttps://cms.drakenfilm.se/movies/count?_limit=42&_start=0&_sort=title:ASC&directors_contains=charlie chaplin
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
        #"title_contains=#{URI.escape(search)}"
        "directors_contains=#{URI.escape(search)}"
    ].join('&')

    res = api.get("/movies?#{query}")

    if res.is_a?(Net::HTTPSuccess)
        movies = JSON.parse(res.body)
        movies.each do |movie|
            print_movie(movie, options[:verbose])
        end
    else
        puts "[err] msg: #{res}"
    end
end

if options[:random]
    rnd_letter = ('a'..'z').to_a.shuffle[0,1].join

    query = [
        "_limit=100",
        "_start=0",
        #"_sort=title:ASC",
        "title_contains=#{URI.escape(rnd_letter)}"
    ].join('&')

    res = api.get("/movies?#{query}")

    if res.is_a?(Net::HTTPSuccess)
        movies = JSON.parse(res.body)
        rnd_movie_indx = rand(movies.length)
        movie = movies[rnd_movie_indx]

        print_movie(movie, options[:verbose])
    else
        puts "[err] msg: #{res}"
    end
end