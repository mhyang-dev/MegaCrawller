require 'net/http'
require 'json'
require 'yaml'
require 'time'
require 'date'

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

ETF_CODES = %w[487240 494670].freeze

def kst_now
  (Time.now.utc + 9 * 3600).strftime('%Y-%m-%d %H:%M KST')
end

def http_get(url, from_encoding: 'UTF-8', extra_headers: {})
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')
  http.open_timeout = 10
  http.read_timeout = 15
  req = Net::HTTP::Get.new(uri.request_uri)
  req['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
  req['Accept'] = '*/*'
  extra_headers.each { |k, v| req[k] = v }
  res = http.request(req)
  return nil unless res.code == '200'
  res.body.encode('UTF-8', from_encoding, invalid: :replace, undef: :replace)
rescue StandardError => e
  puts "  [HTTP 오류] #{e.message}"
  nil
end

def get_json(url)
  body = http_get(url)
  return nil unless body
  JSON.parse(body)
rescue StandardError => e
  puts "  [JSON 오류] #{e.message}"
  nil
end

def fetch_basic(code, fallback_name)
  data = get_json("https://m.stock.naver.com/api/stock/#{code}/basic")
  return nil unless data
  {
    'code'       => code,
    'name'       => data['stockName'] || fallback_name,
    'price'      => data['closePrice'],
    'change'     => data['compareToPreviousClosePrice'],
    'change_pct' => data['fluctuationsRatio'].to_f,
    'direction'  => data.dig('compareToPreviousPrice', 'name') || 'EVEN',
    'market'     => data['stockExchangeName']
  }
end

def fetch_market_cap(code)
  data = get_json("https://polling.finance.naver.com/api/realtime/domestic/stock/#{code}")
  raw = data&.dig('datas', 0, 'marketValueFullRaw')
  raw ? raw.to_i : nil
rescue StandardError
  nil
end

def fetch_expected_profit(code)
  data = get_json("https://m.stock.naver.com/api/stock/#{code}/finance/summary")
  return nil unless data

  annual  = data.dig('chartIncomeStatement', 'annual')
  return nil unless annual

  columns = annual['columns']
  tr_list = annual['trTitleList']
  return nil unless columns && tr_list && columns.size >= 3

  # columns[2] = 영업이익 row; trTitleList index maps to columns value index (offset +1)
  consensus_idx = tr_list.rindex { |t| t['isConsensus'] == 'Y' }
  return nil unless consensus_idx

  val = columns[2][consensus_idx + 1]
  val ? val.to_f : nil  # unit: 억원
rescue StandardError => e
  puts "  [재무 오류] #{e.message}"
  nil
end

def fetch_disclosure(code)
  data = get_json("https://m.stock.naver.com/api/stock/#{code}/disclosure?pageSize=1")
  item = data&.first
  return nil unless item
  {
    'title'    => item['title'],
    'datetime' => item['datetime']&.slice(0, 16)&.tr('T', ' '),
    'author'   => item['author']
  }
rescue StandardError
  nil
end

def fetch_analyst_targets(code)
  html = http_get(
    "https://finance.naver.com/research/company_list.nhn?searchType=itemCode&itemCode=#{code}",
    from_encoding: 'EUC-KR',
    extra_headers: { 'Referer' => 'https://finance.naver.com/' }
  )
  return nil unless html

  nids  = html.scan(/company_read\.naver\?nid=(\d+)/).flatten
  dates = html.scan(/<td class="date"[^>]*>(\d{2}\.\d{2}\.\d{2})<\/td>/).flatten
  return nil if nids.empty?

  cutoff = Date.today - 30
  recent_nids = nids.zip(dates).filter_map do |nid, date_str|
    next unless date_str
    y, m, d = date_str.split('.').map(&:to_i)
    report_date = Date.new(2000 + y, m, d) rescue nil
    nid if report_date && report_date >= cutoff
  end
  return nil if recent_nids.empty?

  targets = []
  mutex = Mutex.new
  threads = recent_nids.map do |nid|
    Thread.new do
      report = http_get(
        "https://finance.naver.com/research/company_read.naver?nid=#{nid}&searchType=itemCode&itemCode=#{code}",
        from_encoding: 'EUC-KR',
        extra_headers: { 'Referer' => 'https://finance.naver.com/research/company_list.nhn' }
      )
      next unless report
      m2 = report.match(/class="money"><strong>([\d,]+)<\/strong>/)
      next unless m2
      price = m2[1].gsub(',', '').to_i
      mutex.synchronize { targets << price } if price > 0
    end
  end
  threads.each(&:join)
  return nil if targets.empty?

  if targets.size >= 5
    sorted  = targets.sort
    trimmed = sorted[1..-2]
    avg = (trimmed.sum.to_f / trimmed.size).round(0).to_i
  else
    avg = (targets.sum.to_f / targets.size).round(0).to_i
  end

  avg_formatted = avg.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
  { 'avg' => avg, 'avg_formatted' => avg_formatted, 'count' => targets.size }
rescue StandardError => e
  puts "  [목표가 오류] #{e.message}"
  nil
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
  basic = fetch_basic(code, fallback)
  unless basic
    puts "  #{fallback}(#{code}): 기본 데이터 실패"
    next nil
  end

  is_etf = ETF_CODES.include?(code)

  if is_etf
    basic['per']            = nil
    basic['analyst_target'] = nil
  else
    market_cap      = fetch_market_cap(code)
    expected_profit = fetch_expected_profit(code)
    per = if market_cap && expected_profit && expected_profit > 0
      (market_cap / (expected_profit * 100_000_000.0)).round(1)
    end
    basic['per']            = per
    basic['analyst_target'] = fetch_analyst_targets(code)
  end

  basic['disclosure'] = fetch_disclosure(code)

  puts "  #{basic['name']}(#{code}): #{basic['price']} (#{basic['change_pct']}%) PER=#{basic['per']}"

  prev = prev_stocks[code]
  notify_discord(basic) if basic['change_pct'].abs >= ALERT_THRESHOLD && (prev.nil? || prev.abs < ALERT_THRESHOLD)

  basic
end

File.write(DATA_FILE, { 'fetched_at' => kst_now, 'stocks' => stocks }.to_yaml)
puts "[완료] #{stocks.size}/#{MY_STOCKS.size}개 종목 저장"
