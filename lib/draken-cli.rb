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

  opts.on("-s", "--search-title", "Perform search") do |o|
    options[:search_title] = o
  end

  opts.on("--search-director", "Perform search") do |o|
    options[:search_director] = o
  end

  opts.on("-r", "--random", "Random film for you") do |o|
    options[:random] = o
  end
end.parse!

DRAKEN_HOST="https://www.drakenfilm.se/"

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

def search_movies(match, option)
    api = Net::HTTP.new('cms.drakenfilm.se', 443)
    api.use_ssl = true
    
    if option[:search_for] == "title"
        search_for="title_contains"
    elsif option[:search_for] == "director"
        search_for="directors_contains"
    else
        raise "Unknown search_for: #{option[:search_for]}"
    end

    query = [
        "_limit=100",
        "_start=0",
        "_sort=title:ASC",
        "#{search_for}=#{URI.escape(match)}"
    ].join('&')

    res = api.get("/movies?#{query}")

    if res.is_a?(Net::HTTPSuccess)
        return JSON.parse(res.body)
    else
        puts "[err] msg: #{res}"
        return {}
    end
end

#ttps://cms.drakenfilm.se/movies/count?_limit=42&_start=0&_sort=title:ASC&directors_contains=charlie chaplin
if options[:search_title]
    search = ARGV.join(' ')
    movies = search_movies(search, { search_for: "title"})

    movies.each do |movie|
        print_movie(movie, options[:verbose])
    end
end

if options[:search_director]
    search = ARGV.join(' ')
    movies = search_movies(search, { search_for: "director"})

    movies.each do |movie|
        print_movie(movie, options[:verbose])
    end
end

if options[:random]
    rnd_letter = ('a'..'z').to_a.shuffle[0,1].join

    movies = search_movies(rnd_letter, {})

    rnd_movie_indx = rand(movies.length)
    movie = movies[rnd_movie_indx]

    print_movie(movie, options[:verbose])
end