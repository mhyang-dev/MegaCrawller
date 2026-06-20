require 'yaml'
require 'time'
require 'net/http'
require 'json'
require 'rexml/document'
require 'open3'

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

def fetch_with_curl(url)
  cmd = [
    'curl', '-s', '-L',
    '-A', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
    '-H', 'Accept: application/atom+xml,application/xml,text/xml,*/*',
    '-H', 'Accept-Language: ko-KR,ko;q=0.9,en-US;q=0.8',
    '-H', 'Referer: https://www.fmkorea.com/hotdeal',
    '--compressed',
    '--max-time', '30',
    '-w', '\n===HTTP_CODE:%{http_code}===',
    url
  ]

  stdout, _stderr, status = Open3.capture3(*cmd)
  if stdout =~ /===HTTP_CODE:(\d+)===/
    code = $1
    body = stdout.sub(/\n===HTTP_CODE:\d+===/, '')
    puts "  [디버그] curl 응답 코드: #{code}"
    [code, body]
  else
    puts "  [디버그] curl 실패: #{status}"
    ['0', '']
  end
end

def parse_atom(body)
  body = body.force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace)
  doc  = REXML::Document.new(body)

  posts = []
  total = 0

  doc.elements.each('feed/entry') do |entry|
    total += 1
    title = entry.elements['title']&.text.to_s.strip
    link  = entry.elements['link']&.attributes['href'].to_s.strip

    next if title.empty? || link.empty?
    next unless title.include?(KEYWORD)

    posts << { 'title' => title, 'url' => link }
  end

  puts "  [디버그] 총 항목 수: #{total}, 키워드 매칭: #{posts.size}"
  posts
rescue REXML::ParseException => e
  puts "  [경고] XML 파싱 실패: #{e.message.lines.first.strip}"
  puts "  [디버그] 응답 앞 200자: #{body[0, 200]}"
  []
end

def fetch_posts
  code, body = fetch_with_curl(RSS_URL)

  unless code == '200'
    puts "  [경고] RSS 피드 접근 실패 (#{code}) — 다음 실행까지 기다립니다"
    return []
  end

  parse_atom(body)
rescue StandardError => e
  puts "  [오류] 예외 발생: #{e.message}"
  []
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
