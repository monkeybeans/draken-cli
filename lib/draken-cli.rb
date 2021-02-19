#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: draken-cli [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |o|
    options[:verbose] = o
  end

  opts.on("-s", "--search-title", "Perform search") do |o|
    options[:search_title] = o
  end

  opts.on("--search-director", "Perform search") do |o|
    options[:search_director] = o
  end

  opts.on("--list-by-genre", "List for: action,animation,biografi,dokumentär,drama,fantasy,komedi,musik,mystik,science fiction,skräck,thriller,äventyr") do |o|
    options[:list_by_genre] = o
  end

  opts.on("-r", "--random", "Random film for you") do |o|
    options[:random] = o
  end
end.parse!

DRAKEN_HOST="https://www.drakenfilm.se/"

def fmt_text(text, width=65)
    fmt_text=""
    current_width=0

    if text.nil?
        return fmt_text
    end

    text.each_char do |c|
        current_width += 1
        if c == "\n"
            fmt_text+=c
            current_width = 0
            next
        end

        if current_width >= width && c == " "
            fmt_text+="\n"
            current_width = 0
        else 
            fmt_text+=c
        end
    end

    return fmt_text
end

def print_movie(movie, verbose)
    title=movie['title']
    url="#{DRAKEN_HOST}film/#{URI.escape(movie['slug'])}"

    if verbose
        puts "### #{title} ###"
        fmt_synopsis=fmt_text(movie['synopsis'])
        puts "\n#{fmt_synopsis}\n\n" unless movie['synopsis'].nil?
        puts "directors: #{movie['directors'].join(', ')}" unless movie['directors'].nil?
        puts "cast:      #{movie['cast'].join(', ')}" unless movie['cast'].nil?
        puts "genres:    #{movie['genres'].join(', ')}" unless movie['genres'].nil?
        puts "country:   #{movie['countriesOfOrigin'].join(', ')}" unless movie['countriesOfOrigin'].nil?
        puts "length:    #{movie['duration']/60}min" unless movie['duration'].nil?
        puts
        puts url
        puts
        puts
    else
        printf("# %-35s %s\n", title, url)
    end
end

def search_movies(match, option)
    api = Net::HTTP.new('cms.drakenfilm.se', 443)
    api.use_ssl = true
    
    if option[:search_type] == "title"
        search_type="title_contains"
    elsif option[:search_type] == "director"
        search_type="directors_contains"
    elsif option[:list_type] == "genre"
        search_type="genres_contains"
    else
        raise "Unknown option: #{option}"
    end

    query = [
        "_limit=100",
        "_start=0",
        "_sort=title:ASC",
        "#{search_type}=#{URI.escape(match)}"
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
    movies = search_movies(search, { search_type: "title"})

    movies.each do |movie|
        print_movie(movie, options[:verbose])
    end
end

if options[:search_director]
    search = ARGV.join(' ')
    movies = search_movies(search, { search_type: "director"})

    movies.each do |movie|
        print_movie(movie, options[:verbose])
    end
end

if options[:list_by_genre]
    search = ARGV.join(' ')
    movies = search_movies(search, { list_type: "genre"})

    movies.each do |movie|
        print_movie(movie, options[:verbose])
    end
end

if options[:random]
    rnd_letter = ('a'..'z').to_a.shuffle[0,1].join

    movies = search_movies(rnd_letter, {search_type: "title"})

    rnd_movie_indx = rand(movies.length)
    movie = movies[rnd_movie_indx]

    print_movie(movie, options[:verbose])
end