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
  res.body.force_encoding(from_encoding).encode('UTF-8', invalid: :replace, undef: :replace)
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

def format_market_cap(eok)
  if eok >= 10_000
    int_s, dec_s = format('%.1f', eok / 10_000.0).split('.')
    int_fmt = int_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
    "#{int_fmt}.#{dec_s}조"
  else
    eok.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse + '억'
  end
end

def fetch_fnguide_consensus(code)
  html = http_get(
    "https://comp.fnguide.com/SVO2/ASP/SVD_Main.asp?pGB=1&gicode=A#{code}",
    extra_headers: { 'Referer' => 'https://comp.fnguide.com/' }
  )
  return nil unless html

  # 컨센서스 (투자의견·목표주가·EPS·PER·추정기관수)
  grid_match = html.match(/id="svdMainGrid9"[\s\S]{1,2000}?<tbody>([\s\S]{1,500}?)<\/tbody>/)
  return nil unless grid_match

  cells = grid_match[1].scan(/<td[^>]*>([\d,.\-]+)<\/td>/).flatten
  return nil if cells.size < 5

  target_price  = cells[1].gsub(',', '').to_i
  per           = cells[3].to_f
  analyst_count = cells[4].to_i
  return nil if target_price == 0

  avg_formatted = target_price.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse

  # 시가총액 (보통주, 억원)
  cap_match = html.match(/보통주,억원[\s\S]*?<td class="r">([\d,]+)<\/td>/)
  market_cap_eok = cap_match ? cap_match[1].gsub(',', '').to_i : nil

  {
    'analyst_target'       => { 'avg' => target_price, 'avg_formatted' => avg_formatted, 'count' => analyst_count },
    'per'                  => per,
    'market_cap_eok'       => market_cap_eok,
    'market_cap_formatted' => market_cap_eok ? format_market_cap(market_cap_eok) : nil
  }
rescue StandardError => e
  puts "  [FnGuide 오류] #{e.message}"
  nil
end

def fetch_disclosure(code)
  data = get_json("https://m.stock.naver.com/api/stock/#{code}/disclosure?pageSize=1")
  item = data&.first
  return nil unless item
  {
    'title'    => item['title'],
    'datetime' => item['datetime']&.slice(0, 16)&.tr('T', ' '),
    'author'   => item['author'],
    'url'      => "https://finance.naver.com/item/news_notice_read.naver?no=#{item['disclosureId']}&code=#{code}&page_notice="
  }
rescue StandardError
  nil
end

def fetch_etf_holdings(code)
  html = http_get(
    "https://finance.naver.com/item/main.naver?code=#{code}",
    extra_headers: { 'Referer' => 'https://finance.naver.com/' }
  )
  return nil unless html

  matches = html.scan(
    /<a href="\/item\/main\.naver\?code=\d+"[^>]*>([^<]+)<\/a>[\s\S]*?<td class="per">\s*([\d.]+%)\s*<\/td>/m
  )
  return nil if matches.empty?

  matches.first(5).map { |name, ratio| { 'name' => name.strip, 'ratio' => ratio.strip } }
rescue StandardError => e
  puts "  [ETF 구성 오류] #{e.message}"
  nil
end

def rule_based_opinion(item)
  per        = item['per']
  change_pct = item['change_pct']
  direction  = item['direction']
  target_avg = item.dig('analyst_target', 'avg')
  price_raw  = item['price'].to_s.gsub(',', '').to_f

  parts = []

  # 밸류에이션 평가
  if per
    parts << if per < 8
      "PER #{per}배로 동종업 대비 저평가 구간에 위치."
    elsif per < 15
      "PER #{per}배로 적정 밸류에이션 수준."
    elsif per < 25
      "PER #{per}배로 다소 고평가된 상태."
    else
      "PER #{per}배로 고평가 구간 — 이익 성장 기대감이 선반영된 상황."
    end
  end

  # 단기 가격 흐름
  parts << if direction == 'RISING' && change_pct >= 3
    "당일 #{change_pct}% 급등하며 강한 매수세 유입 중."
  elsif direction == 'RISING' && change_pct > 0
    "소폭 상승하며 긍정적 흐름 유지."
  elsif direction == 'FALLING' && change_pct <= -3
    "당일 #{change_pct.abs}% 급락 — 단기 조정 또는 매도 압력 주의."
  elsif direction == 'FALLING' && change_pct < 0
    "소폭 하락하며 숨 고르기 국면."
  else
    "보합세로 방향성 탐색 중."
  end

  # 목표가 대비 상승 여력
  if target_avg && price_raw > 0
    upside = ((target_avg / price_raw - 1) * 100).round(1)
    parts << if upside >= 20
      "애널리스트 목표가까지 #{upside}% 상승 여력 — 중장기 매력적."
    elsif upside >= 5
      "목표가 대비 #{upside}% 여력 존재."
    elsif upside >= 0
      "목표가와 현재가 거의 수렴 — 추가 상승 모멘텀 제한적."
    else
      "현재가가 목표가를 #{upside.abs}% 상회 — 단기 과열 가능성."
    end
  end

  parts.join(' ')
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
  basic['category'] = is_etf ? 'etf' : 'stock'

  if is_etf
    basic['holdings'] = fetch_etf_holdings(code)
  else
    consensus = fetch_fnguide_consensus(code)
    basic['per']                  = consensus&.dig('per')
    basic['analyst_target']       = consensus&.dig('analyst_target')
    basic['market_cap_eok']       = consensus&.dig('market_cap_eok')
    basic['market_cap_formatted'] = consensus&.dig('market_cap_formatted')

    price_raw  = basic['price'].to_s.gsub(',', '').to_i
    target_avg = basic.dig('analyst_target', 'avg')
    basic['upside_pct'] = if target_avg && price_raw > 0
      ((target_avg / price_raw.to_f - 1) * 100).round(1)
    end

    basic['disclosure'] = fetch_disclosure(code)
    basic['opinion']    = rule_based_opinion(basic)
  end

  puts "  #{basic['name']}(#{code}): #{basic['price']} (#{basic['change_pct']}%) [#{basic['category']}]"

  prev = prev_stocks[code]
  notify_discord(basic) if basic['change_pct'].abs >= ALERT_THRESHOLD && (prev.nil? || prev.abs < ALERT_THRESHOLD)

  basic
end

individual = stocks.select { |s| s['category'] == 'stock' }
                   .sort_by { |s| -(s['market_cap_eok'] || 0) }
etfs       = stocks.select { |s| s['category'] == 'etf' }
sorted     = individual + etfs

File.write(DATA_FILE, { 'fetched_at' => kst_now, 'stocks' => sorted }.to_yaml)
puts "[완료] #{stocks.size}/#{MY_STOCKS.size}개 종목 저장"
