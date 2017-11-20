#!/bin/ruby
#Created by Sam Gleske
#https://github.com/samrocketman/blog
#Checks Jekyl markdown posts for grammar and spelling issues using gingerice.

require 'ap'
require 'gingerice'
require 'kramdown'
require 'loofah'
require 'thread'

@num_threads = 16

semaphore = Mutex.new

#custom scrubber to remove html elements
class ScrubParagraph < Loofah::Scrubber
  def scrub(node)
    #remove table of contents
    node.remove if node.name == 'ul' and node['id'] == 'markdown-toc'
    #remove headings
    node.remove if node.name.match(/^h[1-6]$/)
    #remove source code block examples
    node.remove if node.name == 'div' and node['class'] == 'highlight'
  end
end
scrubparagraph = ScrubParagraph.new

#read all posts and break them down into different formats
posts = Hash.new
filepaths = Hash.new
if ARGV.size > 0 then
  filepaths
  filenames = ARGV.map do |x|
    fname = (x.sub '_posts/|_drafts/', '').strip
    filepaths[fname] = x
  end
else
  filenames = Dir.entries('_posts')
  filenames.each do |f|
    filepaths[f] = "_posts/#{f}"
  end
end
filenames.select! { |x| x.end_with? '.md' }

kramdown_options = {
  input: :GFM,
  html_to_native: true,
  hard_wrap: false,
  syntax_highlighter: :rouge
}

filenames.each do |p|
  if p.end_with? '.md' then
    if not posts[p] then
      posts[p] = Hash.new
    end
    posts[p][:raw] = IO.read(filepaths[p]).strip
    posts[p][:yaml] = posts[p][:raw].split('---')[1]
    posts[p][:markdown] = posts[p][:raw].split('---')[2].split("\n").map { |line| line.gsub(/(`[^`]+`)/, 'command') }.join("\n")
    posts[p][:html] = Kramdown::Document.new(posts[p][:markdown], options=kramdown_options).to_html
    posts[p][:paragraph] = Loofah.document(posts[p][:html]).scrub!(scrubparagraph).scrub!(:strip).to_text.gsub(/\n/,'  ').strip.gsub(/([^.”"])  ([A-Za-z])/, '\1 \2')
    posts[p][:sentences] = posts[p][:paragraph].split(/(?<=\.)   *(?=\w)|(?<=\.[”"])   *(?=\w)/)
  end
end

#Read a dictionary and build grammar ignore rules.
@ignore_rules = {}
File.open('grammar_ignore.dict', 'r') do |f|
  f.read.split(/\n/).each do |phrase|
    phrase.split(' ').each do |word|
      if not @ignore_rules[word] then
        @ignore_rules[word] = []
      end
      @ignore_rules[word] << phrase
    end
  end
end

#Read a file for lines which should skip
@skip_sentences = []
File.open('grammar_skip.sentences', 'r') do |f|
  @skip_sentences = f.read.strip.split(/\n/)
end


#function to filter our grammar corrections based on ignore rules
def ignore_some(recommended)
  whats_left = []
  (recommended["corrections"] || []).each do |correction|
    result=nil
    if @ignore_rules[correction['text']] then
      @ignore_rules[correction['text']].each do |phrase|
        if not result and recommended['text'].match(phrase) then
          result=correction
        end
      end
      if not result then
        whats_left << correction
      end
    else
      whats_left << correction
    end
  end
  whats_left
end

#try some grammar correcting
grammar_corrections_required_in={}
posts.keys.each do |post|
  puts '---------------------'
  puts "Checking post: #{post}"
  corrections = []
  threads = []
  tcount = 0
  posts[post][:sentences].each do |sentence|
    sentence.strip!
    if sentence.size > 0 and not sentence.match(/{%.*highlight.*%}/) then
      should_skip = nil
      @skip_sentences.each do |words|
        if sentence.match(words) then
          should_skip = true
        end
      end
      if should_skip then
        next
      end
      puts "Grammar checking: #{sentence}"
      threads[tcount] = Thread.new do
        parser = Gingerice::Parser.new
        recommended = parser.parse sentence
        semaphore.synchronize do
          if recommended["corrections"].size > 0 then
            recommended["corrections"] = ignore_some(recommended)
          end
          if recommended["corrections"].size > 0 then
            corrections << recommended
          end
        end
      end
      if tcount == @num_threads-1 then
        threads.each { |thread| thread.join }
      end
      tcount = (tcount + 1) % @num_threads
    end
  end

  # finish processing the current file before continuing
  threads.each { |thread| thread.join }
  if corrections.size > 0 then
    grammar_corrections_required_in[post] = corrections
  end
end

if grammar_corrections_required_in.keys.size > 0 then
  ap grammar_corrections_required_in
  puts ''
  puts '-------------------------'
  puts 'grammar issues discovered'
  puts '-------------------------'
  puts ''
  grammar_corrections_required_in.each do |k,v|
    puts "#{k} has #{v.size} grammar issues."
  end
  puts ''
  puts 'To learn more, see verbose output above this message summary.  Override false'
  puts 'positives and other quirks by updating the grammar_ignore.dict and'
  puts 'grammar_skip.sentences files.'
  exit 1
else
  puts '------------------------------'
  puts 'No grammar issues.  Good work.'
end
