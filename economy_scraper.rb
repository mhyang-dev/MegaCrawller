require 'net/http'
require 'json'
require 'yaml'
require 'time'

DATA_FILE       = File.join(__dir__, '_data', 'economy.yml')
ALERT_THRESHOLD = 3.0

def kst_now
  (Time.now.utc + 9 * 3600).strftime('%Y-%m-%d %H:%M KST')
end

def get_json(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 12
  http.read_timeout = 12
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

def fetch_naver_index(code)
  data = get_json("https://m.stock.naver.com/api/index/#{code}/basic")
  return nil unless data
  ratio = data['fluctuationsRatio'].to_f
  {
    'code'       => code,
    'name'       => code,
    'price'      => data['closePrice'],
    'change'     => data['compareToPreviousClosePrice'],
    'change_pct' => ratio,
    'direction'  => ratio > 0 ? 'RISING' : ratio < 0 ? 'FALLING' : 'EVEN'
  }
end

def fetch_yahoo(symbol, name)
  encoded = URI.encode_www_form_component(symbol)
  data    = get_json("https://query1.finance.yahoo.com/v8/finance/chart/#{encoded}?interval=1d&range=2d")
  meta    = data&.dig('chart', 'result', 0, 'meta')
  return nil unless meta

  price = meta['regularMarketPrice'].to_f
  prev  = (meta['chartPreviousClose'] || meta['previousClose']).to_f
  return nil if prev.zero?

  change     = price - prev
  change_pct = (change / prev * 100).round(2)

  {
    'code'       => symbol,
    'name'       => name,
    'price'      => price.round(2).to_s,
    'change'     => change.round(2).to_s,
    'change_pct' => change_pct,
    'direction'  => change >= 0 ? 'RISING' : 'FALLING'
  }
rescue StandardError => e
  puts "  [오류] #{name}: #{e.message}"
  nil
end

def notify_discord(item)
  webhook_url = ENV['DISCORD_WEBHOOK_URL']
  return unless webhook_url
  arrow = item['direction'] == 'RISING' ? '📈' : '📉'
  sign  = item['change_pct'] >= 0 ? '+' : ''
  msg   = "#{arrow} **#{item['name']}** #{sign}#{item['change_pct']}% 급등락!\n현재: **#{item['price']}**"
  uri = URI.parse(webhook_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  req = Net::HTTP::Post.new(uri.path)
  req['Content-Type'] = 'application/json'
  req.body = { content: msg }.to_json
  http.request(req)
rescue StandardError => e
  puts "  [Discord 오류] #{e.message}"
end

puts "[#{kst_now}] 경제 지표 수집 시작"

kr_indices = %w[KOSPI KOSDAQ].filter_map do |code|
  r = fetch_naver_index(code)
  puts "  #{r ? "#{r['name']}: #{r['price']} (#{r['change_pct']}%)" : "#{code}: 실패"}"
  r
end

us_indices = [
  ['^IXIC', 'NASDAQ'],
  ['^GSPC', 'S&P 500'],
  ['^DJI',  'Dow Jones']
].filter_map do |sym, name|
  r = fetch_yahoo(sym, name)
  puts "  #{r ? "#{r['name']}: #{r['price']} (#{r['change_pct']}%)" : "#{name}: 실패"}"
  r
end

fx_rates = [
  ['USDKRW=X', 'USD/KRW', 1],
  ['EURKRW=X', 'EUR/KRW', 1],
  ['JPYKRW=X', '100JPY/KRW', 100],
  ['CNYKRW=X', 'CNY/KRW', 1]
].filter_map do |sym, name, mult|
  r = fetch_yahoo(sym, name)
  if r && mult > 1
    r['price']  = (r['price'].to_f  * mult).round(2).to_s
    r['change'] = (r['change'].to_f * mult).round(2).to_s
  end
  puts "  #{r ? "#{r['name']}: #{r['price']}" : "#{name}: 실패"}"
  r
end

(kr_indices + us_indices).each do |item|
  notify_discord(item) if item['change_pct'].abs >= ALERT_THRESHOLD
end

File.write(DATA_FILE, {
  'fetched_at' => kst_now,
  'kr_indices' => kr_indices,
  'us_indices' => us_indices,
  'fx_rates'   => fx_rates
}.to_yaml)

puts "[완료] 국내 #{kr_indices.size}개, 해외 #{us_indices.size}개, 환율 #{fx_rates.size}개"
