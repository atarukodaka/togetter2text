# -*- coding: utf-8 -*-
require 'open-uri'
require 'nokogiri'
require 'optparse'
require 'kconv'
require 'uri'
require 'net/http'

# thx to http://h3poteto.hatenablog.com/entry/2013/10/20/135403

################################################################
module Togetter2Text
  class Extractor
    attr_reader :title
    def initialize(url_or_id)
      # 引数から togetter ID を抽出する
      if url_or_id =~ /^(\d+)$/
        @togetter_id = $1
      elsif url_or_id =~ %r{http://[w\.]*togetter.com/li/(\d+)} 
        @togetter_id = $1
      else
        raise "invalid url for togetter. it must be 'http://togetter.com/li/[0-9]+'"
      end
      @togetter_url = "http://togetter.com/li/#{@togetter_id}"
      @more_url = "http://togetter.com/api/moreTweets/#{@togetter_id}"
      @title = ""

      $stderr.puts "togetter: #{@togetter_url}\n  for more tweets: #{@more_url}"
    end
      
    def get_tweets_from_doc(doc)
      doc.xpath('//li[@class="list_item"]//div[@class="tweet"]').map(&:text)
    end
    def get_texts
      # ツイートを抽出。まず最初のページから
      tweets = []                              # ツイートテキスト保存用
      f = open(@togetter_url)
      meta = f.meta                            # 後で csrf_secret を取り出すため
      doc = Nokogiri::HTML(f)
      @title = doc.title
      tweets << get_tweets_from_doc(doc)

      more_button = doc.css('.more_tweet_box')       # 「残りを読む：ボタン

      ## 続きボタンがある場合は読み込み、ない場合は終了
      if more_button.empty?
        return tweets
      end

      $stderr.puts "...reading more.."
      # metaからcsrf_tokenを抜き出す
      csrf_token = nil
      doc.xpath("//meta[@name='csrf_token']/@content").each do |attr|
        csrf_token = attr.value
      end

      # cookie から csrf_secret を抜き出す
      cookie = {}
      str = meta['set-cookie']
      k,v = str[0...str.index(';')].split('=')
      cookie[k] = v

      csrf_secret = cookie['csrf_secret']
      $stderr.puts "csrf_token: #{csrf_token}, crsf_secret: #{cookie['csrf_secret']}"

      body_text = nil
      uri = URI.parse(@more_url)
      Net::HTTP.start(uri.host, uri.port){|http|
        header = {
          "Content-Type" =>"application/x-www-form-urlencoded; charset=UTF-8",
          "Cookie" => "csrf_secret=#{csrf_secret}"
        }
        body ="page=1&csrf_token=#{csrf_token}"
        response = http.post(uri.path, body, header)
        body_text = response.body.toutf8
      }
      doc = Nokogiri::HTML(body_text)
      tweets << get_tweets_from_doc(doc)

      ## 残りのページがあれば読む (div.pagenation)
      page = 2
      while !doc.xpath('//div[@class="pagenation"]/a[@rel="next"]').empty?
        $stderr.puts "...reading page #{page}..."
        url = "#{@togetter_url}?page=#{page}"
        doc = Nokogiri.HTML(open(url))
        tweets << get_tweets_from_doc(doc)
        page += 1
      end
      tweets.flatten    # 保存したツイートテキストを返す
    end
  end
end

################################################################

if __FILE__ == $0
  url = ARGV[0] or raise "specify togetter url"
#  id = "781477"

  t2t = Togetter2Text::Extractor.new(url)
  puts t2t.get_texts.join("\n")
end

__END__


t2t = Twilog2Text.new

opts = ARGV.getopts("r")
url = ARGV[0] || "http://twilog.org/ataru_kodaka"
#user = opts["u"] || opts["user"]

ar = t2t.get_texts(url)
ar.reverse! if opts["r"] == true
ar.each {|text| puts text}

