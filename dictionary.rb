require 'singleton'
require 'set'

class Dictionary
  include Singleton
  attr_accessor :anagrams, :stats

  def initialize()
    @anagrams = {}
    @stats = { min: 0, max: 0, median: 0, average: 0, words_count: 0 }
  end

  def get_anagrams(word)
    key = get_key(word)

    if self.anagrams.has_key?(key)
      self.anagrams[key] - [ word ]
    else
      Array.new
    end
  end

  def ingest_from_file(path: nil)
    path ||= Dir.pwd + "/dictionary.txt"
    raise TypeError unless File.extname(path) == '.txt'

    File.open(path, 'r').each_line do |word|
      add_anagram(word.strip)
    end

  end

  def ingest_from_array(words)
    words.each do |word|
      add_anagram(word)
    end
  end

  def reset_dictionary
    self.anagrams = Hash.new
  end

  def delete_word(word)
    key = get_key(word)
    self.anagrams[key].delete(word) if self.anagrams.has_key?(key)
  end

  private

  def get_key(word)
    word.downcase.chars.sort.join
  end

  def add_anagram(word)
    key = word.downcase.chars.sort.join
    if self.anagrams.has_key?(key)
      self.anagrams[key].add(word)
    else
      self.anagrams[key] = Set.new [word]
    end

    update_stats(word)
  end


  def update_stats(word)
    self.stats[:words_count] += 1

    size = word.size
    if size <= self.stats[:min] || self.stats[:min] == 0
      self.stats[:min] = size
    end

    if size > self.stats[:max]
      self.stats[:max] = size
    end

    self.stats[:average] = (self.stats[:average] * (self.stats[:words_count] - 1)  + size) / self.stats[:words_count].to_f

  end

end
