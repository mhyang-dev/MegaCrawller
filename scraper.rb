require 'yaml'
require 'time'
require 'net/http'
require 'json'
require 'rexml/document'

KEYWORD   = '마우스'
RSS_URL   = 'https://www.fmkorea.com/?act=atom&mid=hotdeal'
DATA_FILE = File.join(__dir__, '_data', 'deals.yml')

def load_existing_deals
  return [] unless File.exist?(DATA_FILE)
  YAML.load_file(DATA_FILE) || []
end

def save_deals(deals)
  File.write(DATA_FILE, deals.to_yaml)
end

def notify_discord(post)
  webhook_url = ENV['DISCORD_WEBHOOK_URL']
  return unless webhook_url

  uri = URI.parse(webhook_url)
  message = {
    content: "🔔 **핫딜 발견! (#{KEYWORD})**\n**#{post['title']}**\n#{post['url']}"
  }

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.path)
  request['Content-Type'] = 'application/json'
  request.body = message.to_json
  http.request(request)
  puts "  [Discord 알림 전송완료]"
end

def fetch_posts
  uri = URI.parse(RSS_URL)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'

  request = Net::HTTP::Get.new(uri.request_uri)
  request['User-Agent'] = 'Mozilla/5.0 (compatible; RSS reader)'

  response = http.request(request)
  puts "  [디버그] RSS 응답 코드: #{response.code}"

  doc   = REXML::Document.new(response.body)
  posts = []

  doc.elements.each('feed/entry') do |entry|
    title = entry.elements['title']&.text.to_s.strip
    link  = entry.elements['link']&.attributes['href'].to_s.strip

    next if title.empty? || link.empty?
    next unless title.include?(KEYWORD)

    posts << { 'title' => title, 'url' => link }
  end

  puts "  [디버그] 키워드 매칭 글 수: #{posts.size}"
  posts
end

puts "[#{Time.now}] FMKorea 핫딜 RSS 스캔 시작 (키워드: #{KEYWORD})"

existing      = load_existing_deals
existing_urls = existing.map { |d| d['url'] }

new_posts = fetch_posts
added     = 0

new_posts.each do |post|
  next if existing_urls.include?(post['url'])
  post['found_at'] = Time.now.strftime('%Y-%m-%d %H:%M')
  existing.unshift(post)
  added += 1
  puts "  [추가] #{post['title']}"
  puts "         #{post['url']}"
  notify_discord(post)
end

if added > 0
  save_deals(existing)
  puts "[완료] #{added}개 새 글 저장됨"
else
  puts "[완료] 새 글 없음"
end
