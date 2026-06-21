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

US_STOCKS = {}.freeze  # 보유 해외 주식 (현재 없음)

US_WATCHLIST = {
  'MU' => '마이크론 테크놀로지'
}.freeze

KR_WATCHLIST = {
  '006800' => '미래에셋증권'
}.freeze

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

def get_json(url, extra_headers: {})
  body = http_get(url, extra_headers: extra_headers)
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

def load_usd_krw
  economy_file = File.join(__dir__, '..', '_data', 'economy.yml')
  return 1380.0 unless File.exist?(economy_file)
  data = YAML.load_file(economy_file) || {}
  fx   = (data['fx_rates'] || []).find { |r| r['name'] == 'USD/KRW' }
  rate = fx ? fx['price'].to_f : 0.0
  rate > 100 ? rate : 1380.0
rescue StandardError
  1380.0
end

def format_krw(won)
  won.round.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
end

def format_market_cap_usd(billion_usd)
  if billion_usd >= 1000
    format('$%.1fT', billion_usd / 1000.0)
  else
    format('$%.0fB', billion_usd.round)
  end
end

@yahoo_cookie = nil
@yahoo_crumb  = nil

def yahoo_crumb
  return [@yahoo_cookie, @yahoo_crumb] if @yahoo_crumb

  ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'

  uri1 = URI.parse('https://fc.yahoo.com/')
  http1 = Net::HTTP.new(uri1.host, uri1.port)
  http1.use_ssl = true; http1.open_timeout = 10; http1.read_timeout = 10
  req1 = Net::HTTP::Get.new(uri1.request_uri)
  req1['User-Agent'] = ua
  res1 = http1.request(req1)
  @yahoo_cookie = res1['set-cookie']&.split(';')&.first

  uri2 = URI.parse('https://query1.finance.yahoo.com/v1/test/getcrumb')
  http2 = Net::HTTP.new(uri2.host, uri2.port)
  http2.use_ssl = true; http2.open_timeout = 10; http2.read_timeout = 10
  req2 = Net::HTTP::Get.new(uri2.request_uri)
  req2['User-Agent'] = ua
  req2['Cookie'] = @yahoo_cookie if @yahoo_cookie
  res2 = http2.request(req2)
  @yahoo_crumb = res2.body.strip

  puts "  [Yahoo] crumb 획득 완료"
  [@yahoo_cookie, @yahoo_crumb]
rescue StandardError => e
  puts "  [Yahoo 인증 오류] #{e.message}"
  [nil, nil]
end

# Yahoo Finance v10 quoteSummary: price, PE, market cap, analyst target, industry
def fetch_yahoo_data(ticker, fallback_name, usd_krw: 1380.0)
  cookie, crumb = yahoo_crumb
  ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
  headers = {
    'Accept'          => 'application/json',
    'Accept-Language' => 'en-US,en;q=0.9',
    'Referer'         => 'https://finance.yahoo.com/',
    'User-Agent'      => ua
  }
  headers['Cookie'] = cookie if cookie

  modules = 'price,summaryDetail,defaultKeyStatistics,assetProfile,financialData'
  crumb_param = crumb ? "&crumb=#{URI.encode_www_form_component(crumb)}" : ''
  data = get_json(
    "https://query2.finance.yahoo.com/v10/finance/quoteSummary/#{ticker}?modules=#{modules}#{crumb_param}",
    extra_headers: headers
  )
  result = data&.dig('quoteSummary', 'result', 0)

  if result
    price_mod  = result['price']                || {}
    summary    = result['summaryDetail']        || {}
    stats      = result['defaultKeyStatistics'] || {}
    profile    = result['assetProfile']         || {}
    financial  = result['financialData']        || {}

    current_price = price_mod.dig('regularMarketPrice', 'raw')
    change        = price_mod.dig('regularMarketChange', 'raw')
    change_pct    = price_mod.dig('regularMarketChangePercent', 'raw')
    market_cap    = price_mod.dig('marketCap', 'raw')
    name          = price_mod['shortName'] || fallback_name

    unless current_price
      puts "  [Yahoo] #{ticker}: regularMarketPrice 없음"
      return nil
    end

    forward_pe  = stats.dig('forwardPE', 'raw')
    trailing_pe = summary.dig('trailingPE', 'raw')
    per         = forward_pe || trailing_pe

    target    = financial.dig('targetMeanPrice', 'raw')
    ana_count = financial.dig('numberOfAnalystOpinions', 'raw')&.to_i
    industry  = profile['industry']

    market_cap_b   = market_cap ? market_cap / 1_000_000_000.0 : nil
    price_krw      = (current_price * usd_krw).round
    change_krw     = (change.abs * usd_krw).round
    market_cap_eok = market_cap ? (market_cap.to_f * usd_krw / 100_000_000).round : nil
    target_krw     = target ? (target * usd_krw).round : nil
    upside_pct     = (target && current_price > 0) ? ((target / current_price - 1) * 100).round(1) : nil

    return {
      'code'                     => ticker,
      'name'                     => name,
      'price'                    => format_krw(price_krw),
      'price_usd'                => format('$%.2f', current_price),
      'change'                   => format_krw(change_krw),
      'change_pct'               => change_pct&.round(2),
      'direction'                => (change || 0) >= 0 ? 'RISING' : 'FALLING',
      'currency'                 => 'USD',
      'market'                   => 'US',
      'category'                 => 'us_watch',
      'fics'                     => industry,
      'per'                      => per&.round(1),
      'market_cap_eok'           => market_cap_eok,
      'market_cap_formatted'     => market_cap_eok ? format_market_cap(market_cap_eok) : nil,
      'market_cap_usd_formatted' => market_cap_b ? format_market_cap_usd(market_cap_b) : nil,
      'analyst_target'           => target_krw ? {
        'avg'           => target_krw,
        'avg_formatted' => format_krw(target_krw),
        'avg_usd'       => format('$%.2f', target),
        'count'         => ana_count
      } : nil,
      'upside_pct' => upside_pct
    }
  end

  # v10 실패 시 v8 chart API 폴백
  puts "  [Yahoo] #{ticker}: v10 실패, v8 차트로 폴백"
  chart = get_json(
    "https://query1.finance.yahoo.com/v8/finance/chart/#{ticker}?interval=1d&range=1d",
    extra_headers: headers
  )
  meta = chart&.dig('chart', 'result', 0, 'meta')
  return nil unless meta

  price = meta['regularMarketPrice']
  prev  = meta['previousClose'] || meta['chartPreviousClose']
  return nil unless price && prev

  change      = price - prev
  change_pct  = ((change / prev) * 100).round(2)
  price_krw   = (price * usd_krw).round
  change_krw  = (change.abs * usd_krw).round

  {
    'code'       => ticker,
    'name'       => fallback_name,
    'price'      => format_krw(price_krw),
    'price_usd'  => format('$%.2f', price),
    'change'     => format_krw(change_krw),
    'change_pct' => change_pct,
    'direction'  => change >= 0 ? 'RISING' : 'FALLING',
    'currency'   => 'USD',
    'market'     => 'US',
    'category'   => 'us_watch'
  }
rescue StandardError => e
  puts "  [Yahoo 오류] #{e.message}"
  nil
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

  # FICS 업종: <span class="stxt stxt2">FICS 자동차</span> 형태
  fics_span = html.match(/stxt2">\s*FICS\s+([\s\S]{1,100}?)<\/span>/)
  fics = fics_span ? fics_span[1].gsub(/&nbsp;/, ' ').gsub(/<[^>]+>/, '').strip : nil

  # svdMainGrid9 컨센서스 섹션
  grid_idx = html.index('svdMainGrid9')
  unless grid_idx
    puts "  [FnGuide] #{code}: svdMainGrid9 없음 (html #{html.size}B)"
    return fics ? { 'fics' => fics } : nil
  end
  grid_section = html[grid_idx, 20_000]

  # tbody 행 구조: [clf=투자의견] [목표주가] [EPS] [PER] [cle=추정기관수]
  # rwc_g 클래스 행에서 셀을 순서대로 추출
  row_m = grid_section.match(
    /<tr[^>]*rwc_g[^>]*>[\s\S]{0,100}?
     <td[^>]*clf[^>]*>[\s\S]{0,30}?<\/td>\s*
     <td[^>]*>([\d,]+)<\/td>\s*
     <td[^>]*>[\d,]+<\/td>\s*
     <td[^>]*>([\d,.]+)<\/td>\s*
     <td[^>]*cle[^>]*>(\d+)<\/td>/x
  )
  unless row_m
    puts "  [FnGuide] #{code}: 컨센서스 행 미매칭"
    return fics ? { 'fics' => fics } : nil
  end

  target_price  = row_m[1].gsub(',', '').to_i
  per           = row_m[2].to_f
  analyst_count = row_m[3].to_i

  if target_price == 0
    puts "  [FnGuide] #{code}: 목표주가 0"
    return fics ? { 'fics' => fics } : nil
  end

  avg_formatted = target_price.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse

  cap_match = html.match(/보통주,억원[\s\S]{0,500}?<td[^>]*class="r"[^>]*>\s*([\d,]+)\s*<\/td>/)
  market_cap_eok = cap_match ? cap_match[1].gsub(',', '').to_i : nil

  # 업종 PER: id="h_u_per" 직후 <dd> 값
  indu_per_m = html.match(/id="h_u_per"[\s\S]{0,200}?<\/dt>\s*<dd>([\d.]+)<\/dd>/)
  indu_per   = indu_per_m ? indu_per_m[1].to_f : nil

  {
    'analyst_target'       => { 'avg' => target_price, 'avg_formatted' => avg_formatted, 'count' => analyst_count },
    'per'                  => per,
    'indu_per'             => indu_per,
    'market_cap_eok'       => market_cap_eok,
    'market_cap_formatted' => market_cap_eok ? format_market_cap(market_cap_eok) : nil,
    'fics'                 => fics
  }
rescue StandardError => e
  puts "  [FnGuide 오류] #{e.message}"
  nil
end

DISCLOSURE_JUNK = /가격제한폭|기준가격|단기과열|투자주의|투자경고|투자위험|거래정지|매매정지|이상급등/

def fetch_disclosure(code)
  data = get_json("https://m.stock.naver.com/api/stock/#{code}/disclosure?pageSize=20")
  return nil unless data&.any?
  filtered = data.reject { |item| (item['title'] || '').match?(DISCLOSURE_JUNK) }
  return nil if filtered.empty?
  filtered.first(3).map do |item|
    {
      'title'    => item['title'],
      'datetime' => item['datetime']&.slice(0, 10),
      'url'      => "https://finance.naver.com/item/news_notice_read.naver?no=#{item['disclosureId']}&code=#{code}&page_notice="
    }
  end
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

# ── 연속 매수/매도 + 누적 금액 계산 ──────────────────────────────────
def format_investor_amount(shares, price_num)
  return nil unless price_num && price_num > 0
  eok = (shares.to_f * price_num / 100_000_000).round(1)
  return nil if eok < 1
  eok >= 10_000 ? format('%.1f조', eok / 10_000.0) : "#{eok.round}억"
end

def streak_with_amount(vals, price_num)
  return { 'days' => 0, 'amount' => nil } if vals.nil? || vals.empty?
  first = vals.find { |v| v != 0 }
  return { 'days' => 0, 'amount' => nil } unless first
  dir = first > 0 ? 1 : -1
  count = 0; total = 0
  vals.each do |v|
    break if v == 0 || (v > 0 ? 1 : -1) != dir
    count += 1; total += v.abs
  end
  { 'days' => dir * count, 'amount' => format_investor_amount(total, price_num) }
end

def fetch_investor_streaks(code, price: nil)
  html = http_get(
    "https://finance.naver.com/item/frgn.naver?code=#{code}",
    from_encoding: 'EUC-KR',
    extra_headers: { 'Referer' => "https://finance.naver.com/item/main.naver?code=#{code}" }
  )
  return nil unless html

  # Parse rows: find date spans (gray03) then extract 기관(w=66) and 외국인(w=80) net amounts
  # Rows are sorted most-recent-first by frgn.naver
  gigan_vals   = []
  foreign_vals = []

  html.scan(
    /<span[^>]*gray03[^>]*>([\d.]+)<\/span>[\s\S]{0,1800}?<td[^>]*width="66"[^>]*>[\s\S]{0,300}?<span[^>]*>([+\-]?[\d,]+)<\/span>[\s\S]{0,600}?<td[^>]*width="80"[^>]*>[\s\S]{0,300}?<span[^>]*>([+\-]?[\d,]+)<\/span>/
  ) do |_date, gigan_raw, foreign_raw|
    gigan_vals   << gigan_raw.gsub(/[+,]/, '').to_i
    foreign_vals << foreign_raw.gsub(/[+,]/, '').to_i
  end

  return nil if gigan_vals.empty?

  indi_vals  = gigan_vals.zip(foreign_vals).map { |g, f| -(g + f) }
  price_num  = price.to_s.gsub(',', '').to_f
  gi  = streak_with_amount(gigan_vals,   price_num)
  fo  = streak_with_amount(foreign_vals, price_num)
  ind = streak_with_amount(indi_vals,    price_num)

  {
    'gigan'          => gi['days'],
    'gigan_amount'   => gi['amount'],
    'foreign'        => fo['days'],
    'foreign_amount' => fo['amount'],
    'indi'           => ind['days'],
    'indi_amount'    => ind['amount']
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

def fetch_kr_stock_list
  require 'uri'
  seen = {}  # code => {name, market}

  # KOSPI/KOSDAQ 전체 커버리지: 한글 음절 + 영문 A-Z + 주요 종목/ETF 접두사
  prefixes = %w[
    가 각 강 개 거 건 게 경 고 공 광 교 구 국 군 굿 귀 그 글 금 기
    나 남 내 넥 노 뉴
    다 단 달 담 대 더 데 도 동 두 드 디 딥
    라 란 레 로 롯 루 리
    마 만 매 메 모 무 미 민
    바 반 방 배 보 부 브 비 빅
    사 산 상 새 서 선 세 소 솔 수 스 시 신 씨
    아 안 알 애 앤 에 엔 엘 엠 여 영 오 올 온 원 위 유 은 이 인 일
    자 장 재 전 제 조 종 주 지 진
    차 청 체
    케 코 크 키
    테 토 트
    파 판 팜 포 피 핀
    한 항 해 현 화 효 히
    A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
    LG SK KT GS HD CJ NH OCI HMM
    KODEX TIGER KINDEX KBSTAR KOSEF HANARO ACE TIMEFOLIO SMART
  ]

  ac_headers = { 'Referer' => 'https://finance.naver.com/', 'Accept' => 'application/json, */*' }

  prefixes.uniq.each do |q|
    encoded = URI.encode_www_form_component(q)
    data = get_json("https://ac.stock.naver.com/ac?q=#{encoded}&target=stock", extra_headers: ac_headers)
    next unless data.is_a?(Hash)
    (data['items'] || []).each do |item|
      code   = (item['code']     || item[1] || '').to_s
      name   = (item['name']     || item[0] || '').to_s
      market = (item['typeCode'] || '').to_s  # KOSPI / KOSDAQ / KONEX 등
      seen[code] = { 'name' => name, 'market' => market } if code.match?(/^\d{6}$/) && !name.empty?
    end
    sleep 0.05
  end

  result = seen.map { |c, v| { 'code' => c, 'name' => v['name'], 'market' => v['market'] } }
  puts "  [주식목록] #{result.length}개 수집 (KOSPI/KOSDAQ 포함)#{result.empty? ? ' — fallback 사용' : ''}"
  result.empty? ? (MY_STOCKS.merge(KR_WATCHLIST)).map { |c, n| { 'code' => c, 'name' => n, 'market' => '' } } : result
rescue StandardError => e
  puts "  [주식목록] 실패: #{e.message}"
  (MY_STOCKS.merge(KR_WATCHLIST)).map { |c, n| { 'code' => c, 'name' => n, 'market' => '' } }
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
    basic['indu_per']         = consensus&.dig('indu_per')
    basic['investor_streaks'] = fetch_investor_streaks(code, price: basic['price'])
  end

  puts "  #{basic['name']}(#{code}): #{basic['price']} (#{basic['change_pct']}%) [#{basic['category']}]"

  prev = prev_stocks[code]
  notify_discord(basic) if basic['change_pct'].abs >= ALERT_THRESHOLD && (prev.nil? || prev.abs < ALERT_THRESHOLD)

  sleep 1 unless is_etf  # FnGuide 레이트리밋 방지

  basic
end

usd_krw = load_usd_krw
puts "  [환율] USD/KRW = #{usd_krw}"

# 국내 관심주
kr_watch_stocks = KR_WATCHLIST.filter_map do |code, fallback|
  basic = fetch_basic(code, fallback)
  unless basic
    puts "  #{fallback}(#{code}): 기본 데이터 실패"
    next nil
  end
  basic['category'] = 'stock_watch'
  consensus = fetch_fnguide_consensus(code)
  basic['per']            = consensus&.dig('per')
  basic['analyst_target'] = consensus&.dig('analyst_target')
  cap_eok = consensus&.dig('market_cap_eok') || fetch_naver_market_cap(code)
  basic['market_cap_eok']       = cap_eok
  basic['market_cap_formatted'] = cap_eok ? format_market_cap(cap_eok) : nil
  price_raw  = basic['price'].to_s.gsub(',', '').to_i
  target_avg = basic.dig('analyst_target', 'avg')
  basic['upside_pct'] = (target_avg && price_raw > 0) ? ((target_avg / price_raw.to_f - 1) * 100).round(1) : nil
  basic['disclosure']       = fetch_disclosure(code)
  basic['fics']             = consensus&.dig('fics')
  basic['indu_per']         = consensus&.dig('indu_per')
  basic['investor_streaks'] = fetch_investor_streaks(code, price: basic['price'])
  puts "  #{basic['name']}(#{code}): #{basic['price']} (#{basic['change_pct']}%) [stock_watch]"
  sleep 1
  basic
end

# 해외 포트폴리오 (현재 없음)
us_port_stocks = US_STOCKS.filter_map do |ticker, fallback_name|
  data = fetch_yahoo_data(ticker, fallback_name, usd_krw: usd_krw)
  next nil unless data
  data['category'] = 'us_stock'
  puts "  #{data['name']}(#{ticker}): #{data['price']} [us_stock]"
  sleep 0.5
  data
end

# 해외 관심주
us_watch_stocks = US_WATCHLIST.filter_map do |ticker, fallback_name|
  data = fetch_yahoo_data(ticker, fallback_name, usd_krw: usd_krw)
  unless data
    puts "  #{fallback_name}(#{ticker}): 데이터 실패"
    next nil
  end
  data['category'] = 'us_watch'
  puts "  #{data['name']}(#{ticker}): #{data['price']} (#{data['price_usd']}) [us_watch]"
  sleep 0.5
  data
end

individual = stocks.select { |s| s['category'] == 'stock' }
                   .sort_by { |s| -(s['market_cap_eok'] || 0) }
etfs       = stocks.select { |s| s['category'] == 'etf' }
sorted     = individual + etfs + kr_watch_stocks + us_port_stocks + us_watch_stocks

puts "  [주식목록] 전체 종목 목록 수집 중..."
kr_stocks_list = fetch_kr_stock_list

total_target = MY_STOCKS.size + KR_WATCHLIST.size + US_WATCHLIST.size
File.write(DATA_FILE, { 'fetched_at' => kst_now, 'stocks' => sorted, 'kr_stocks_list' => kr_stocks_list }.to_yaml)
puts "[완료] #{sorted.size}/#{total_target}개 종목 저장"
