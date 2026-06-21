#!/usr/bin/env ruby
# 실행: ruby mystocks/local_server.rb  (프로젝트 루트에서)
# 브라우저에서 종목 동적 추가 시 전체 데이터 조회용 로컬 서버 (포트 9001)

require 'net/http'
require 'json'
require 'yaml'
require 'webrick'
require 'uri'
require 'thread'

PORT = 9001

# ── HTTP 헬퍼 ────────────────────────────────────────────────────────────
def http_get(url, from_encoding: 'UTF-8', extra_headers: {}, retries: 1)
  attempts = 0
  begin
    attempts += 1
    uri  = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl       = (uri.scheme == 'https')
    http.open_timeout  = 12
    http.read_timeout  = 20
    req = Net::HTTP::Get.new(uri.request_uri)
    req['User-Agent']      = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    req['Accept']          = 'text/html,application/xhtml+xml,*/*'
    req['Accept-Language'] = 'ko-KR,ko;q=0.9'
    extra_headers.each { |k, v| req[k] = v }
    res = http.request(req)
    return nil unless res.code == '200'
    res.body.force_encoding(from_encoding).encode('UTF-8', invalid: :replace, undef: :replace)
  rescue StandardError => e
    retry if attempts <= retries
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

# ── 포맷 헬퍼 ────────────────────────────────────────────────────────────
def format_krw(won)
  won.round.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
end

def format_market_cap(eok)
  if eok >= 10_000
    int_s, dec_s = format('%.1f', eok / 10_000.0).split('.')
    "#{int_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse}.#{dec_s}조"
  else
    eok.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse + '억'
  end
end

def format_market_cap_usd(billion_usd)
  billion_usd >= 1000 ? format('$%.1fT', billion_usd / 1000.0) : format('$%.0fB', billion_usd.round)
end

# ── 환율 ─────────────────────────────────────────────────────────────────
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

# ── KR/ETF 기본 가격 ─────────────────────────────────────────────────────
def fetch_kr_basic(code)
  data = get_json("https://m.stock.naver.com/api/stock/#{code}/basic")
  return nil unless data
  raw_chg = data['compareToPreviousClosePrice'].to_s
  {
    'code'       => code,
    'name'       => data['stockName'] || code,
    'price'      => data['closePrice'] || '—',
    'change'     => raw_chg.gsub(/^-/, ''),
    'change_pct' => data['fluctuationsRatio'].to_f,
    'direction'  => data.dig('compareToPreviousPrice', 'name') || 'EVEN'
  }
end

# ── FnGuide 컨센서스 ─────────────────────────────────────────────────────
def fetch_fnguide(code)
  html = http_get(
    "https://comp.fnguide.com/SVO2/ASP/SVD_Main.asp?pGB=1&gicode=A#{code}",
    extra_headers: { 'Referer' => 'https://comp.fnguide.com/' },
    retries: 2
  )
  return nil unless html

  fics_m = html.match(/stxt2">\s*FICS\s+([\s\S]{1,100}?)<\/span>/)
  fics   = fics_m ? fics_m[1].gsub(/&nbsp;/, ' ').gsub(/<[^>]+>/, '').strip : nil

  grid_idx = html.index('svdMainGrid9')
  return fics ? { 'fics' => fics } : nil unless grid_idx

  grid  = html[grid_idx, 20_000]
  row_m = grid.match(
    /<tr[^>]*rwc_g[^>]*>[\s\S]{0,100}?
     <td[^>]*clf[^>]*>[\s\S]{0,30}?<\/td>\s*
     <td[^>]*>([\d,]+)<\/td>\s*
     <td[^>]*>[\d,]+<\/td>\s*
     <td[^>]*>([\d,.]+)<\/td>\s*
     <td[^>]*cle[^>]*>(\d+)<\/td>/x
  )
  return fics ? { 'fics' => fics } : nil unless row_m

  target = row_m[1].gsub(',', '').to_i
  per    = row_m[2].to_f
  count  = row_m[3].to_i
  return fics ? { 'fics' => fics } : nil if target == 0

  avg_fmt = target.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse

  cap_m    = html.match(/보통주,억원[\s\S]{0,500}?<td[^>]*class="r"[^>]*>\s*([\d,]+)\s*<\/td>/)
  cap      = cap_m ? cap_m[1].gsub(',', '').to_i : nil
  ipu_m    = html.match(/id="h_u_per"[\s\S]{0,200}?<\/dt>\s*<dd>([\d.]+)<\/dd>/)
  indu_per = ipu_m ? ipu_m[1].to_f : nil

  {
    'fics'                 => fics,
    'per'                  => per,
    'indu_per'             => indu_per,
    'market_cap_eok'       => cap,
    'market_cap_formatted' => cap ? format_market_cap(cap) : nil,
    'analyst_target'       => { 'avg' => target, 'avg_formatted' => avg_fmt, 'count' => count }
  }
rescue StandardError => e
  puts "  [FnGuide 오류] #{e.message}"
  nil
end

# ── 연속 매수/매도 ───────────────────────────────────────────────────────
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

  gigan_vals = []; foreign_vals = []
  html.scan(
    /<span[^>]*gray03[^>]*>([\d.]+)<\/span>[\s\S]{0,1800}?<td[^>]*width="66"[^>]*>[\s\S]{0,300}?<span[^>]*>([+\-]?[\d,]+)<\/span>[\s\S]{0,600}?<td[^>]*width="80"[^>]*>[\s\S]{0,300}?<span[^>]*>([+\-]?[\d,]+)<\/span>/
  ) do |_date, gi, fo|
    gigan_vals   << gi.gsub(/[+,]/, '').to_i
    foreign_vals << fo.gsub(/[+,]/, '').to_i
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

# ── 최근 공시 ─────────────────────────────────────────────────────────────
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

# ── ETF 구성 종목 ─────────────────────────────────────────────────────────
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
  matches.first(5).map { |n, r| { 'name' => n.strip, 'ratio' => r.strip } }
rescue StandardError => e
  puts "  [ETF 구성 오류] #{e.message}"
  nil
end

# ── Yahoo Finance ─────────────────────────────────────────────────────────
@yahoo_cookie = nil
@yahoo_crumb  = nil
@yahoo_mutex  = Mutex.new

def yahoo_crumb
  @yahoo_mutex.synchronize do
    return [@yahoo_cookie, @yahoo_crumb] if @yahoo_crumb
    ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'

    uri1 = URI.parse('https://fc.yahoo.com/')
    h1   = Net::HTTP.new(uri1.host, uri1.port); h1.use_ssl = true; h1.open_timeout = 10; h1.read_timeout = 10
    r1   = Net::HTTP::Get.new(uri1.request_uri); r1['User-Agent'] = ua
    res1 = h1.request(r1)
    @yahoo_cookie = res1['set-cookie']&.split(';')&.first

    uri2 = URI.parse('https://query1.finance.yahoo.com/v1/test/getcrumb')
    h2   = Net::HTTP.new(uri2.host, uri2.port); h2.use_ssl = true; h2.open_timeout = 10; h2.read_timeout = 10
    r2   = Net::HTTP::Get.new(uri2.request_uri); r2['User-Agent'] = ua; r2['Cookie'] = @yahoo_cookie if @yahoo_cookie
    res2 = h2.request(r2)
    @yahoo_crumb = res2.body.strip
    puts "  [Yahoo] crumb 획득"
    [@yahoo_cookie, @yahoo_crumb]
  end
rescue StandardError => e
  puts "  [Yahoo 인증 오류] #{e.message}"
  [nil, nil]
end

def fetch_us_data(ticker, usd_krw: 1380.0)
  cookie, crumb = yahoo_crumb
  ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
  hdrs = {
    'Accept' => 'application/json', 'Accept-Language' => 'en-US,en;q=0.9',
    'Referer' => 'https://finance.yahoo.com/', 'User-Agent' => ua
  }
  hdrs['Cookie'] = cookie if cookie

  modules     = 'price,summaryDetail,defaultKeyStatistics,assetProfile,financialData'
  crumb_param = crumb ? "&crumb=#{URI.encode_www_form_component(crumb)}" : ''
  data        = get_json(
    "https://query2.finance.yahoo.com/v10/finance/quoteSummary/#{ticker}?modules=#{modules}#{crumb_param}",
    extra_headers: hdrs
  )
  result = data&.dig('quoteSummary', 'result', 0)

  unless result
    # v8 폴백
    chart = get_json("https://query1.finance.yahoo.com/v8/finance/chart/#{ticker}?interval=1d&range=1d", extra_headers: hdrs)
    meta  = chart&.dig('chart', 'result', 0, 'meta')
    return nil unless meta
    price = meta['regularMarketPrice']
    prev  = meta['previousClose'] || meta['chartPreviousClose']
    return nil unless price && prev
    change     = price - prev
    change_pct = ((change / prev) * 100).round(2)
    price_krw  = (price * usd_krw).round
    chg_krw    = (change.abs * usd_krw).round
    cap        = meta['marketCap']
    cap_eok    = cap ? (cap.to_f * usd_krw / 100_000_000).round : nil
    cap_b      = cap ? cap / 1_000_000_000.0 : nil
    return {
      'code' => ticker, 'name' => ticker,
      'price' => format_krw(price_krw), 'price_usd' => format('$%.2f', price),
      'change' => format_krw(chg_krw), 'change_pct' => change_pct,
      'direction' => change >= 0 ? 'RISING' : 'FALLING',
      'market_cap_eok' => cap_eok,
      'market_cap_formatted' => cap_eok ? format_market_cap(cap_eok) : nil,
      'market_cap_usd_formatted' => cap_b ? format_market_cap_usd(cap_b) : nil
    }
  end

  pm  = result['price']                || {}
  sd  = result['summaryDetail']        || {}
  dks = result['defaultKeyStatistics'] || {}
  ap  = result['assetProfile']         || {}
  fd  = result['financialData']        || {}

  price      = pm.dig('regularMarketPrice', 'raw')
  change     = pm.dig('regularMarketChange', 'raw')
  change_pct = pm.dig('regularMarketChangePercent', 'raw')
  cap        = pm.dig('marketCap', 'raw')
  name       = pm['shortName'] || ticker
  return nil unless price

  per        = dks.dig('forwardPE', 'raw') || sd.dig('trailingPE', 'raw')
  target     = fd.dig('targetMeanPrice', 'raw')
  ana_count  = fd.dig('numberOfAnalystOpinions', 'raw')&.to_i
  industry   = ap['industry']

  cap_b      = cap ? cap / 1_000_000_000.0 : nil
  price_krw  = (price * usd_krw).round
  chg_krw    = ((change || 0).abs * usd_krw).round
  cap_eok    = cap ? (cap.to_f * usd_krw / 100_000_000).round : nil
  tgt_krw    = target ? (target * usd_krw).round : nil
  upside     = (target && price > 0) ? ((target / price - 1) * 100).round(1) : nil

  {
    'code'                     => ticker,
    'name'                     => name,
    'price'                    => format_krw(price_krw),
    'price_usd'                => format('$%.2f', price),
    'change'                   => format_krw(chg_krw),
    'change_pct'               => change_pct&.round(2),
    'direction'                => ((change || 0) >= 0 ? 'RISING' : 'FALLING'),
    'fics'                     => industry,
    'per'                      => per&.round(1),
    'market_cap_eok'           => cap_eok,
    'market_cap_formatted'     => cap_eok ? format_market_cap(cap_eok) : nil,
    'market_cap_usd_formatted' => cap_b ? format_market_cap_usd(cap_b) : nil,
    'analyst_target'           => tgt_krw ? {
      'avg' => tgt_krw, 'avg_formatted' => format_krw(tgt_krw),
      'avg_usd' => format('$%.2f', target), 'count' => ana_count
    } : nil,
    'upside_pct' => upside
  }
rescue StandardError => e
  puts "  [Yahoo 오류] #{e.message}"
  nil
end

# ── WEBrick 서버 ─────────────────────────────────────────────────────────
server = WEBrick::HTTPServer.new(
  Port:      PORT,
  Logger:    WEBrick::Log.new($stderr, WEBrick::Log::ERROR),
  AccessLog: []
)

REPO_ROOT = File.expand_path('..', __dir__)

def set_cors(res)
  res['Access-Control-Allow-Origin']          = '*'
  res['Access-Control-Allow-Methods']         = 'GET, POST, OPTIONS'
  res['Access-Control-Allow-Headers']         = 'Content-Type'
  res['Access-Control-Allow-Private-Network'] = 'true'
  res['Content-Type']                         = 'application/json; charset=utf-8'
end

server.mount_proc '/' do |req, res|
  set_cors(res)
  if req.request_method == 'OPTIONS'
    res.status = 200; res.body = ''; next
  end

  # POST /api/save-watchlist → watchlist.json 저장 후 git push
  if req.path == '/api/save-watchlist' && req.request_method == 'POST'
    begin
      data = JSON.parse(req.body)
      File.write(File.join(REPO_ROOT, '_data', 'watchlist.json'), JSON.pretty_generate(data))
      Dir.chdir(REPO_ROOT) do
        system('git add _data/watchlist.json')
        no_changes = system('git diff --cached --quiet')
        if no_changes
          res.body = { ok: true, message: 'no changes' }.to_json
        else
          system('git commit --no-verify -m "종목 목록 업데이트"')
          pushed = system('git push origin master')
          if pushed
            res.body = { ok: true, message: 'pushed' }.to_json
          else
            res.status = 500
            res.body = { error: 'git push failed' }.to_json
          end
        end
      end
    rescue StandardError => e
      res.status = 500
      res.body = { error: e.message }.to_json
    end
    next
  end

  unless req.path =~ /^\/api\/stock\/([^\/]+)$/
    res.status = 404; res.body = '{"error":"not found"}'; next
  end

  code    = $1.strip
  type    = req.query['type'] || (code.match?(/^\d{6}$/) ? 'kr' : 'us')
  usd_krw = load_usd_krw
  t0      = Time.now

  result = case type
  when 'etf'
    basic    = fetch_kr_basic(code)
    holdings = fetch_etf_holdings(code)
    basic ? basic.merge('holdings' => holdings) : { 'error' => 'not found' }

  when 'us'
    fetch_us_data(code.upcase, usd_krw: usd_krw) || { 'error' => 'not found' }

  else
    basic = fetch_kr_basic(code)
    unless basic
      { 'error' => 'not found' }
    else
      price_str = basic['price']
      fnguide_r = nil; investor_r = nil; disclosure_r = nil
      threads = [
        Thread.new { fnguide_r    = fetch_fnguide(code) },
        Thread.new { investor_r   = fetch_investor_streaks(code, price: price_str) },
        Thread.new { disclosure_r = fetch_disclosure(code) }
      ]
      threads.each(&:join)

      r = basic.merge(fnguide_r || {}).merge(
        'investor_streaks' => investor_r,
        'disclosure'       => disclosure_r
      )
      if r['analyst_target'] && r['price']
        price_num = r['price'].to_s.gsub(',', '').to_f
        tgt       = r.dig('analyst_target', 'avg')
        r['upside_pct'] = ((tgt.to_f / price_num - 1) * 100).round(1) if price_num > 0 && tgt
      end
      r
    end
  end

  elapsed = ((Time.now - t0) * 1000).round
  puts "[#{Time.now.strftime('%H:%M:%S')}] #{type.upcase} #{code} → #{result['name'] || result['error']} (#{elapsed}ms)"
  res.body = result.to_json
end

trap('INT') { server.shutdown }

puts '=' * 52
puts "  주식 데이터 로컬 서버  (포트 #{PORT})"
puts "  종목 추가 시 전체 데이터 자동 조회"
puts "  종료: Ctrl+C"
puts '=' * 52

server.start
