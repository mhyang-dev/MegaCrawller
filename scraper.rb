require 'selenium-webdriver'
require 'yaml'
require 'time'

KEYWORD = '태블릿'
TARGET_URL = 'https://www.fmkorea.com/hotdeal'
DATA_FILE = File.join(__dir__, '_data', 'deals.yml')

def load_existing_deals
  return [] unless File.exist?(DATA_FILE)
  YAML.load_file(DATA_FILE) || []
end

def save_deals(deals)
  File.write(DATA_FILE, deals.to_yaml)
end

def fetch_posts
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')

  driver = Selenium::WebDriver.for :chrome, options: options
  posts = []

  begin
    driver.get(TARGET_URL)
    sleep 3

    items = driver.find_elements(css: '.title a, li.hotdeal_item a, .fm_best_widget a')

    if items.empty?
      # 범용 링크 탐색
      items = driver.find_elements(css: 'a[href*="/hotdeal/"]')
    end

    items.each do |el|
      title = el.text.strip
      href  = el.attribute('href')
      next if title.empty? || href.nil?
      next unless title.include?(KEYWORD)

      href = "https://www.fmkorea.com#{href}" unless href.start_with?('http')
      posts << { 'title' => title, 'url' => href }
    end
  ensure
    driver.quit
  end

  posts
end

puts "[#{Time.now}] FMKorea 핫딜 스캔 시작 (키워드: #{KEYWORD})"

existing = load_existing_deals
existing_urls = existing.map { |d| d['url'] }

new_posts = fetch_posts
added = 0

new_posts.each do |post|
  next if existing_urls.include?(post['url'])
  post['found_at'] = Time.now.strftime('%Y-%m-%d %H:%M')
  existing.unshift(post)
  added += 1
  puts "  [추가] #{post['title']}"
  puts "         #{post['url']}"
end

if added > 0
  save_deals(existing)
  puts "[완료] #{added}개 새 글 저장됨"
else
  puts "[완료] 새 글 없음"
end
