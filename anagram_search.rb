require 'sinatra'
require 'sinatra/json'
require_relative 'dictionary.rb'

configure do
  Dictionary.instance.ingest_from_file

  set :port, 3000
  set :server, 'thin'
  set :logging, false
end

helpers do
  def dict
    Dictionary.instance
  end
end

get '/anagrams/:word.json' do
  anagrams = dict.get_anagrams(params[:word])

  limit = params.fetch(:limit, anagrams.size)
  json anagrams: anagrams.first(limit.to_i)

end

get '/stats.json' do
  json stats: dict.stats
end


post '/words.json' do
  words = JSON.parse(request.body.read)
  dict.ingest_from_array(words['words'])

  status 201
end

delete '/words/:word.json' do
  if params.has_key?(:word)
    dict.delete_word(params[:word])
  end

  status 204
end


delete '/words.json' do
  dict.reset_dictionary

  status 204
end
