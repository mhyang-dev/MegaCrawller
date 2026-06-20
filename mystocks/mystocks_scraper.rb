require 'net/http'
require 'json'
require 'yaml'
require 'time'
require 'date'
require 'thread'

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

def http_get(url, from_encoding: 'UTF-8', extra_headers: {}, retries: 1)
  attempts = 0
  begin
    attempts += 1
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = 12
    http.read_timeout = 20
    req = Net::HTTP::Get.new(uri.request_uri)
    req['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    req['Accept'] = 'text/html,application/xhtml+xml,*/*'
    req['Accept-Language'] = 'ko-KR,ko;q=0.9'
    extra_headers.each { |k, v| req[k] = v }
    res = http.request(req)
    return nil unless res.code == '200'
    res.body.force_encoding(from_encoding).encode('UTF-8', invalid: :replace, undef: :replace)
  rescue StandardError => e
    if attempts <= retries
      sleep(3)
      retry
    end
    puts "  [HTTP 오류] #{e.message}"
    nil
  end
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

def fetch_naver_market_cap(code)
  html = http_get(
    "https://finance.naver.com/item/main.naver?code=#{code}",
    from_encoding: 'EUC-KR',
    extra_headers: { 'Referer' => 'https://finance.naver.com/' }
  )
  return nil unless html
  m = html.match(/_market_sum[^>]*>([^<]+)</)
  return nil unless m
  text = m[1].strip  # e.g. "125조 1,164억" or "4조 1,987억"
  total = 0
  total += $1.gsub(',', '').to_i * 10_000 if text.match(/(\d[\d,]*)조/)
  total += $1.gsub(',', '').to_i          if text.match(/(\d[\d,]*)억/)
  total > 0 ? total : nil
rescue StandardError
  nil
end

def fetch_fnguide_consensus(code)
  html = http_get(
    "https://comp.fnguide.com/SVO2/ASP/SVD_Main.asp?pGB=1&gicode=A#{code}",
    extra_headers: { 'Referer' => 'https://comp.fnguide.com/' },
    retries: 2
  )
  return nil unless html

  # FICS 업종 분류: "대분류(소분류)" 형태에서 괄호 안 소분류 추출
  fics_match = html.match(/FICS[\s\S]{0,800}?\(([^)<>"]{2,60})\)/)
  fics = fics_match&.[](1)&.strip

  # svdMainGrid9 컨센서스 섹션
  grid_idx = html.index('svdMainGrid9')
  unless grid_idx
    puts "  [FnGuide] #{code}: svdMainGrid9 없음 (html #{html.size}B)"
    return fics ? { 'fics' => fics } : nil
  end
  grid_section = html[grid_idx, 20_000]

  # 셀 인덱스 대신 행 헤더명으로 각 값을 직접 추출
  target_price  = grid_section.match(/목표주가[\s\S]{0,600}?<td[^>]*>\s*([\d,]+)\s*<\/td>/)
                              &.[](1)&.gsub(',', '')&.to_i
  per           = grid_section.match(/\bPER\b[\s\S]{0,600}?<td[^>]*>\s*([\d,.]+)\s*<\/td>/)
                              &.[](1)&.gsub(',', '')&.to_f
  analyst_count = grid_section.match(/추정기관수[\s\S]{0,600}?<td[^>]*>\s*(\d+)\s*<\/td>/)
                              &.[](1)&.to_i

  if target_price.nil? || target_price == 0
    puts "  [FnGuide] #{code}: 목표주가 미매칭 (grid #{grid_section.size}B)"
    return fics ? { 'fics' => fics } : nil
  end

  avg_formatted = target_price.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse

  cap_match = html.match(/보통주,억원[\s\S]{0,500}?<td[^>]*class="r"[^>]*>\s*([\d,]+)\s*<\/td>/)
  market_cap_eok = cap_match ? cap_match[1].gsub(',', '').to_i : nil

  {
    'analyst_target'       => { 'avg' => target_price, 'avg_formatted' => avg_formatted, 'count' => analyst_count },
    'per'                  => per,
    'market_cap_eok'       => market_cap_eok,
    'market_cap_formatted' => market_cap_eok ? format_market_cap(market_cap_eok) : nil,
    'fics'                 => fics
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

# ── 연속 매수/매도 계산 ──────────────────────────────────
# values: 순매매량 배열 (최신→과거 순서). 양수=매수, 음수=매도.
# 반환값: 양수=연속 매수일, 음수=연속 매도일, 0=해당없음
def consecutive_streak(values)
  return 0 if values.nil? || values.empty?
  first_nonzero = values.find { |v| v != 0 }
  return 0 unless first_nonzero

  direction = first_nonzero > 0 ? 1 : -1
  count = 0
  values.each do |v|
    break if v == 0 || (v > 0 ? 1 : -1) != direction
    count += 1
  end
  direction * count
end

def fetch_investor_streaks(code)
  html = http_get(
    "https://finance.naver.com/item/frgn.naver?code=#{code}",
    from_encoding: 'EUC-KR',
    extra_headers: { 'Referer' => "https://finance.naver.com/item/main.naver?code=#{code}" }
  )
  return nil unless html

  # Parse rows: find date spans (gray03) then extract 기관(w=66) and 외국인(w=80) net amounts
  # Rows are sorted most-recent-first by frgn.naver
  dates        = []
  gigan_vals   = []
  foreign_vals = []

  html.scan(
    /<span[^>]*gray03[^>]*>([\d.]+)<\/span>[\s\S]{0,1800}?<td[^>]*width="66"[^>]*>[\s\S]{0,300}?<span[^>]*>([+\-]?[\d,]+)<\/span>[\s\S]{0,600}?<td[^>]*width="80"[^>]*>[\s\S]{0,300}?<span[^>]*>([+\-]?[\d,]+)<\/span>/
  ) do |date, gigan_raw, foreign_raw|
    dates        << date
    gigan_vals   << gigan_raw.gsub(/[+,]/, '').to_i
    foreign_vals << foreign_raw.gsub(/[+,]/, '').to_i
  end

  return nil if gigan_vals.empty?

  indi_vals = gigan_vals.zip(foreign_vals).map { |g, f| -(g + f) }

  # as_of: 마지막으로 시장이 열린 날 (frgn.naver의 가장 최신 행)
  as_of = dates.first&.gsub('.', '-')  # "2026.06.19" → "2026-06-19"

  {
    'gigan'   => consecutive_streak(gigan_vals),
    'foreign' => consecutive_streak(foreign_vals),
    'indi'    => consecutive_streak(indi_vals),
    'as_of'   => as_of
  }
rescue StandardError => e
  puts "  [수급 오류] #{e.message}"
  nil
end

# ── 규칙 기반 Claude 의견 ───────────────────────────────
def rule_based_opinion(item)
  per        = item['per']
  change_pct = item['change_pct']
  direction  = item['direction']
  target_avg = item.dig('analyst_target', 'avg')
  price_raw  = item['price'].to_s.gsub(',', '').to_f

  parts = []

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
  msg   = "#{arrow} **[내 포트폴리오] #{item['name']}** #{sign}#{item['change_pct']}% 급등락!\n" \
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

puts "[#{kst_now}] 내 포트폴리오 수집 시작"

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
    basic['per']            = consensus&.dig('per')
    basic['analyst_target'] = consensus&.dig('analyst_target')
    cap_eok = consensus&.dig('market_cap_eok') || fetch_naver_market_cap(code)
    basic['market_cap_eok']       = cap_eok
    basic['market_cap_formatted'] = cap_eok ? format_market_cap(cap_eok) : nil

    price_raw  = basic['price'].to_s.gsub(',', '').to_i
    target_avg = basic.dig('analyst_target', 'avg')
    basic['upside_pct'] = if target_avg && price_raw > 0
      ((target_avg / price_raw.to_f - 1) * 100).round(1)
    end

    basic['disclosure']       = fetch_disclosure(code)
    basic['opinion']          = rule_based_opinion(basic)
    basic['fics']             = consensus&.dig('fics')
    basic['investor_streaks'] = fetch_investor_streaks(code)
  end

  puts "  #{basic['name']}(#{code}): #{basic['price']} (#{basic['change_pct']}%) [#{basic['category']}]"

  prev = prev_stocks[code]
  notify_discord(basic) if basic['change_pct'].abs >= ALERT_THRESHOLD && (prev.nil? || prev.abs < ALERT_THRESHOLD)

  sleep 1 unless is_etf  # FnGuide 레이트리밋 방지

  basic
end

individual = stocks.select { |s| s['category'] == 'stock' }
                   .sort_by { |s| -(s['market_cap_eok'] || 0) }
etfs       = stocks.select { |s| s['category'] == 'etf' }
sorted     = individual + etfs

File.write(DATA_FILE, { 'fetched_at' => kst_now, 'stocks' => sorted }.to_yaml)
puts "[완료] #{stocks.size}/#{MY_STOCKS.size}개 종목 저장"
