require 'net/http'
require 'json'
require 'yaml'
require 'time'

DATA_FILE       = File.join(__dir__, '..', '_data', 'mystocks.yml')
ALERT_THRESHOLD = 3.0

MY_STOCKS = {
  '005930' => '삼성전자',
  '000660' => 'SK하이닉스',
  '009150' => '삼성전기',
  '005380' => '현대차',
  '012330' => '현대모비스',
  '032830' => '삼성생명',
  '069960' => '현대백화점',
  '020000' => '한섬',
  '278470' => '에이피알',
  '487240' => 'KODEX AI전력핵심설비',
  '494670' => 'TIGER 조선TOP10'
}.freeze

def kst_now
  (Time.now.utc + 9 * 3600).strftime('%Y-%m-%d %H:%M KST')
end

def get_json(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 10
  req = Net::HTTP::Get.new(uri.request_uri)
  req['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
  req['Accept']     = 'application/json'
  res = http.request(req)
  return nil unless res.code == '200'
  JSON.parse(res.body)
rescue StandardError => e
  puts "  [오류] #{e.message}"
  nil
end

def fetch_stock(code, fallback_name)
  data = get_json("https://m.stock.naver.com/api/stock/#{code}/basic")
  return nil unless data
  ratio = data['fluctuationsRatio'].to_f
  {
    'code'       => code,
    'name'       => data['stockName'] || fallback_name,
    'price'      => data['closePrice'],
    'change'     => data['compareToPreviousClosePrice'],
    'change_pct' => ratio,
    'direction'  => data.dig('compareToPreviousPrice', 'name') || 'EVEN',
    'market'     => data['stockExchangeName']
  }
end

def notify_discord(item)
  webhook_url = ENV['DISCORD_WEBHOOK_URL']
  return unless webhook_url
  arrow = item['direction'] == 'RISING' ? '📈' : '📉'
  sign  = item['change_pct'] >= 0 ? '+' : ''
  msg   = "#{arrow} **[내 주식] #{item['name']}** #{sign}#{item['change_pct']}% 급등락!\n" \
          "현재가: **#{item['price']}** (#{sign}#{item['change']})"
  uri = URI.parse(webhook_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  req = Net::HTTP::Post.new(uri.path)
  req['Content-Type'] = 'application/json'
  req.body = { content: msg }.to_json
  http.request(req)
  puts "  [Discord] #{item['name']} 알림 전송"
rescue StandardError => e
  puts "  [Discord 오류] #{e.message}"
end

puts "[#{kst_now}] 내 주식 수집 시작"

prev_stocks = if File.exist?(DATA_FILE)
  (YAML.load_file(DATA_FILE) || {}).fetch('stocks', [])
    .each_with_object({}) { |s, h| h[s['code']] = s['change_pct'].to_f }
else
  {}
end

stocks = MY_STOCKS.filter_map do |code, fallback|
  r = fetch_stock(code, fallback)
  if r
    puts "  #{r['name']}(#{code}): #{r['price']} (#{r['change_pct']}%)"
    prev = prev_stocks[code]
    notify_discord(r) if r['change_pct'].abs >= ALERT_THRESHOLD && (prev.nil? || prev.abs < ALERT_THRESHOLD)
  else
    puts "  #{fallback}(#{code}): 실패"
  end
  r
end

File.write(DATA_FILE, { 'fetched_at' => kst_now, 'stocks' => stocks }.to_yaml)
puts "[완료] #{stocks.size}/#{MY_STOCKS.size}개 종목 저장"
