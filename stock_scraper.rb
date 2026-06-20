require 'net/http'
require 'json'
require 'yaml'
require 'time'

DATA_FILE       = File.join(__dir__, '_data', 'stocks.yml')
ALERT_THRESHOLD = 3.0  # % 이상 등락시 Discord 알림

STOCKS = {
  '005930' => '삼성전자',
  '000660' => 'SK하이닉스',
  '035420' => 'NAVER',
  '035720' => '카카오',
  '000270' => '기아',
  '005380' => '현대차',
  '051910' => 'LG화학',
  '066570' => 'LG전자',
  '207940' => '삼성바이오로직스',
  '005490' => 'POSCO홀딩스'
}.freeze

INDICES = %w[KOSPI KOSDAQ].freeze

def get(url)
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
  puts "  [오류] #{url}: #{e.message}"
  nil
end

def fetch_stock(code)
  data = get("https://m.stock.naver.com/api/stock/#{code}/basic")
  return nil unless data

  ratio = data['fluctuationsRatio'].to_f
  {
    'type'       => 'stock',
    'code'       => code,
    'name'       => data['stockName'],
    'price'      => data['closePrice'],
    'change'     => data['compareToPreviousClosePrice'],
    'change_pct' => ratio,
    'direction'  => data.dig('compareToPreviousPrice', 'name') || 'EVEN',
    'market'     => data['stockExchangeName'],
    'status'     => data['marketStatus'],
    'updated_at' => Time.now.strftime('%Y-%m-%d %H:%M')
  }
end

def fetch_index(code)
  data = get("https://m.stock.naver.com/api/index/#{code}/basic")
  return nil unless data

  ratio = data['fluctuationsRatio'].to_f
  direction = if ratio > 0 then 'RISING' elsif ratio < 0 then 'FALLING' else 'EVEN' end
  {
    'type'       => 'index',
    'code'       => code,
    'name'       => code,
    'price'      => data['closePrice'],
    'change'     => data['compareToPreviousClosePrice'],
    'change_pct' => ratio,
    'direction'  => direction,
    'market'     => code,
    'status'     => data['marketStatus'],
    'updated_at' => Time.now.strftime('%Y-%m-%d %H:%M')
  }
end

def notify_discord(item)
  webhook_url = ENV['DISCORD_WEBHOOK_URL']
  return unless webhook_url

  arrow = item['direction'] == 'RISING' ? '📈' : '📉'
  sign  = item['change_pct'] > 0 ? '+' : ''
  msg   = "#{arrow} **#{item['name']}** #{sign}#{item['change_pct']}% 급등락!\n" \
          "현재가: **#{item['price']}** (#{sign}#{item['change']})\n" \
          "https://m.stock.naver.com/domestic/stock/#{item['code']}"

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

def load_previous
  return {} unless File.exist?(DATA_FILE)
  prev = YAML.load_file(DATA_FILE) || {}
  all  = (prev['indices'] || []) + (prev['stocks'] || [])
  all.each_with_object({}) { |i, h| h[i['code']] = i['change_pct'].to_f }
end

puts "[#{Time.now}] 주식 데이터 수집 시작"

previous_ratios = load_previous

indices = INDICES.filter_map do |code|
  item = fetch_index(code)
  if item
    puts "  #{item['name']}: #{item['price']} (#{item['change_pct']}%)"
  end
  item
end

stocks = STOCKS.keys.filter_map do |code|
  item = fetch_stock(code)
  if item
    ratio = item['change_pct']
    prev  = previous_ratios[code]
    puts "  #{item['name']}(#{code}): #{item['price']} (#{ratio}%)"
    if ratio.abs >= ALERT_THRESHOLD && (prev.nil? || prev.abs < ALERT_THRESHOLD)
      notify_discord(item)
    end
  end
  item
end

result = {
  'fetched_at' => Time.now.strftime('%Y-%m-%d %H:%M'),
  'indices'    => indices,
  'stocks'     => stocks
}

File.write(DATA_FILE, result.to_yaml)
puts "[완료] #{indices.size}개 지수, #{stocks.size}개 종목 저장"
