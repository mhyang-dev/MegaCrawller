---
layout: page
title: 내 포트폴리오
permalink: /mystocks/
---

<style>
/* ── 전체 레이아웃 ────────────────────────────────── */
.page-outer {
  width: 100vw;
  position: relative;
  left: 50%;
  transform: translateX(-50%);
  padding: 0 1.5em;
  box-sizing: border-box;
}
.page-grid {
  display: grid;
  grid-template-columns: 4fr 1fr;
  gap: 1.5em;
  align-items: start;
}

/* ── 섹션 타이틀 ──────────────────────────────────── */
.section-title {
  font-size: 1em;
  font-weight: bold;
  margin: 1.4em 0 0.5em;
  color: #333;
  border-left: 3px solid #555;
  padding-left: 0.6em;
}

/* ── 표 공통 ──────────────────────────────────────── */
.stock-table {
  width: auto;
  border-collapse: collapse;
  font-size: 0.86em;
  margin-bottom: 0.4em;
}
.stock-table th {
  background: #f0f0f0;
  padding: 7px 10px;
  text-align: center;
  border-bottom: 2px solid #ddd;
  white-space: nowrap;
}
.stock-table th.left { text-align: left; }
.stock-table td {
  padding: 6px 10px;
  border-bottom: 1px solid #eee;
  text-align: right;
  vertical-align: top;
  white-space: nowrap;
}
.stock-table td:first-child { text-align: left; font-weight: normal; }
.stock-table td:nth-child(2) { text-align: left; font-weight: bold; }

/* ── 정렬 버튼 ────────────────────────────────────── */
.stock-table th[data-col] {
  cursor: pointer;
  user-select: none;
}
.stock-table th[data-col]:hover { background: #e2e2e2; }
.sort-icon {
  display: inline-block;
  margin-left: 3px;
  color: #bbb;
  font-size: 0.75em;
}
.sort-asc .sort-icon,
.sort-desc .sort-icon { color: #444; }

/* ── 색상 ────────────────────────────────────────── */
.rising  { color: #e74c3c; }
.falling { color: #3498db; }
.even    { color: #888; }
.na      { color: #ccc; }

/* ── 셀 서브텍스트 ────────────────────────────────── */
.sub { color: #999; font-size: 0.82em; margin-left: 2px; }

/* ── FICS 업종 셀 ────────────────────────────────── */
.fics-cell {
  text-align: left !important;
  white-space: nowrap;
}
.fics-tag {
  display: inline-block;
  background: #f4f0ff;
  border: 1px solid #d0c4f8;
  color: #6040b0;
  font-size: 0.78em;
  padding: 2px 7px;
  border-radius: 10px;
  white-space: nowrap;
  font-weight: normal;
}

/* ── 매수 주체 셀 ──────────────────────────────────── */
.investor-cell {
  text-align: center !important;
  min-width: 160px;
  white-space: nowrap;
}
.investor-row {
  display: flex;
  gap: 4px;
  justify-content: center;
  flex-wrap: nowrap;
}
.investor-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  min-width: 28px;
}
.investor-label {
  font-size: 0.7em;
  color: #999;
  margin-bottom: 1px;
}
.investor-buy  { color: #e74c3c; font-weight: bold; font-size: 0.9em; }
.investor-sell { color: #3498db; font-weight: bold; font-size: 0.9em; }
.investor-zero { color: #ccc; font-size: 0.85em; }
.investor-as-of { font-size: 0.7em; color: #bbb; margin-top: 2px; }

/* ── 공시 셀 ─────────────────────────────────────── */
.disclosure-cell {
  text-align: left !important;
  min-width: 500px;
  width: 500px;
  white-space: normal;
  word-break: break-all;
  overflow-wrap: break-word;
}
.disclosure-item { display: flex; align-items: baseline; gap: 6px; margin-bottom: 2px; }
.disclosure-item:last-child { margin-bottom: 0; }
.disclosure-title { flex: 1; min-width: 0; }
.disclosure-title a { word-break: break-all; }
.disclosure-date { color: #bbb; font-size: 0.78em; white-space: nowrap; flex-shrink: 0; }

/* ── ETF 구성 종목 셀 ────────────────────────────── */
.holdings-cell { text-align: left !important; }
.holdings-list { margin: 0; padding: 0; list-style: none; }
.holdings-list li { font-size: 0.84em; line-height: 1.65; white-space: nowrap; }
.holdings-ratio { color: #999; margin-left: 0.4em; }

/* ── GitHub 저장 바 ────────────────────────────────── */
.sync-bar { display: flex; align-items: center; gap: 8px; margin: 6px 0 10px; }
.sync-btn { background: none; border: 1px solid #ccc; border-radius: 12px; padding: 3px 12px; cursor: pointer; color: #555; font-size: 0.8em; }
.sync-btn:hover { background: #f0f0f0; }
.sync-btn:disabled { opacity: 0.45; cursor: default; }
.sync-msg { color: #888; font-size: 0.8em; }

/* ── 테이블 주석 ─────────────────────────────────── */
.table-note {
  color: #aaa;
  font-size: 0.78em;
  margin: 0 0 2em;
  line-height: 1.7;
}

/* ── 대분류탭 ────────────────────────────────────── */
.tabs-major {
  display: flex;
  border-bottom: 2px solid #ddd;
  margin-bottom: 0;
}
.tab-major {
  padding: 9px 22px;
  border: none;
  background: transparent;
  cursor: pointer;
  font-size: 0.92em;
  color: #999;
  border-bottom: 3px solid transparent;
  margin-bottom: -2px;
}
.tab-major:hover { color: #444; }
.tab-major.active { color: #222; font-weight: bold; border-bottom-color: #444; }

/* ── 중분류탭 ────────────────────────────────────── */
.tabs-minor {
  display: flex;
  gap: 6px;
  margin: 0.9em 0 0.7em;
}
.tab-minor {
  padding: 4px 15px;
  border: 1px solid #ddd;
  border-radius: 20px;
  background: transparent;
  cursor: pointer;
  font-size: 0.82em;
  color: #aaa;
}
.tab-minor:hover { color: #555; border-color: #aaa; }
.tab-minor.active { background: #444; color: #fff; border-color: #444; font-weight: bold; }

/* ── 패널 표시 제어 ──────────────────────────────── */
.major-panel { display: none; }
.major-panel.active { display: block; }
.minor-panel { display: none; }
.minor-panel.active { display: block; }

/* ── 해외 주식 이중 표시 ─────────────────────────── */
.sub-usd { color: #bbb; font-size: 0.8em; margin-left: 3px; }

/* ── 종목 검색/추가 UI ────────────────────────────── */
.stock-adder {
  position: relative;
  margin-bottom: 0.8em;
  display: flex;
  align-items: center;
  gap: 8px;
}
.stock-search-input {
  width: 220px;
  padding: 6px 14px;
  border: 1px solid #ddd;
  border-radius: 20px;
  font-size: 0.84em;
  outline: none;
  box-sizing: border-box;
}
.stock-search-input:focus { border-color: #888; }
.search-dropdown {
  display: none;
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  min-width: 220px;
  background: #fff;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  box-shadow: 0 4px 14px rgba(0,0,0,0.10);
  z-index: 200;
  overflow: hidden;
}
.search-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 14px;
  cursor: pointer;
  font-size: 0.84em;
  border-bottom: 1px solid #f2f2f2;
  gap: 12px;
}
.search-item:last-child { border-bottom: none; }
.search-item:hover, .search-item.selected { background: #f0f0f0; }
.si-name { color: #222; }
.si-code { color: #bbb; font-size: 0.82em; white-space: nowrap; }
.si-market { font-size: 0.72em; padding: 1px 5px; border-radius: 3px; white-space: nowrap; font-weight: 500; margin-left: 4px; }
.si-market.kospi  { background: #e8f0fb; color: #1a5276; }
.si-market.kosdaq { background: #e8f8e8; color: #1a5c1a; }
.search-no-result { padding: 10px 14px; color: #bbb; font-size: 0.84em; }
.remove-btn {
  background: none;
  border: none;
  color: #ddd;
  cursor: pointer;
  font-size: 1em;
  padding: 2px 4px;
  border-radius: 3px;
}
.remove-btn:hover { color: #e74c3c; }

/* ── 우측 AI 사이드바 ────────────────────────────── */
.ai-sidebar {
  position: sticky;
  top: 1.5em;
  max-height: calc(100vh - 3em);
  overflow-y: auto;
}
.ai-sidebar-title {
  font-size: 0.78em;
  font-weight: bold;
  color: #888;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  margin-bottom: 0.8em;
  padding-bottom: 0.4em;
  border-bottom: 1px solid #ddd;
}
.opinion-card {
  background: #fafafa;
  border: 1px solid #e8e8e8;
  border-radius: 6px;
  padding: 0.7em 0.9em;
  margin-bottom: 0.75em;
  font-size: 0.8em;
}
.opinion-name { font-weight: bold; font-size: 0.95em; color: #222; margin-bottom: 0.4em; }
.opinion-text { color: #444; line-height: 1.55; }
.opinion-pending { color: #bbb; font-style: italic; font-size: 0.82em; }

/* ── 메타 ─────────────────────────────────────────── */
.meta { color: #999; font-size: 0.84em; margin-bottom: 1em; }

/* ── 모바일 반응형 ───────────────────────────────── */
@media (max-width: 768px) {
  .page-outer {
    width: 100%;
    position: static;
    left: auto;
    transform: none;
    padding: 0;
  }
  .page-grid { grid-template-columns: 1fr; }
  .ai-sidebar { display: none; }
  .tables-col { min-width: 0; }
  .table-scroll {
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
  }
  .stock-table {
    min-width: 600px;
    font-size: 0.78em;
  }
  .stock-table th,
  .stock-table td { padding: 5px 7px; }
  .disclosure-cell { min-width: 320px; width: 320px; }
  .fics-cell { min-width: 80px; }
  .investor-cell { min-width: 110px; }
  #etf-port-table { min-width: 0; }
}
</style>

{% if site.data.mystocks and site.data.mystocks.stocks.size > 0 %}
<p class="meta">마지막 업데이트: {{ site.data.mystocks.fetched_at }} · 매 시간 자동 갱신</p>

{% assign individual = site.data.mystocks.stocks | where: "category", "stock" %}
{% assign etfs       = site.data.mystocks.stocks | where: "category", "etf" %}
{% assign kr_watch   = site.data.mystocks.stocks | where: "category", "stock_watch" %}
{% assign us_port    = site.data.mystocks.stocks | where: "category", "us_stock" %}
{% assign us_watch   = site.data.mystocks.stocks | where: "category", "us_watch" %}

<div class="page-outer">
<div class="page-grid">
<div class="tables-col">

<!-- 대분류탭 -->
<div class="tabs-major">
  <button class="tab-major active" data-major="kr">국내 주식</button>
  <button class="tab-major" data-major="etf">ETF / ETN</button>
  <button class="tab-major" data-major="us">해외 주식</button>
</div>
<div class="sync-bar">
  <button class="sync-btn" id="github-save-btn">☁ GitHub 저장</button>
  <span class="sync-msg" id="sync-msg"></span>
</div>

<!-- ══ 국내 주식 패널 ══ -->
<div class="major-panel active" id="panel-kr">
  <div class="tabs-minor">
    <button class="tab-minor active" data-panel="panel-kr-port">내 포트폴리오</button>
    <button class="tab-minor" data-panel="panel-kr-watch">관심주</button>
  </div>
  <div class="minor-panel active" id="panel-kr-port">
  <div id="kr-port-adder" class="stock-adder">
    <input type="text" id="kr-port-search-input" class="stock-search-input" placeholder="종목명 검색 (예: 삼성)" autocomplete="off" />
    <div id="kr-port-search-dropdown" class="search-dropdown"></div>
  </div>
  <div class="table-scroll">
  <table class="stock-table" id="kr-port-table">
  <thead><tr>
    <th class="left" data-col="fics">업종 <span class="sort-icon">⇅</span></th>
    <th data-col="name">종목 <span class="sort-icon">⇅</span></th>
    <th data-col="cap">시총(억) <span class="sort-icon">⇅</span></th>
    <th data-col="price">현재가(원) <span class="sort-icon">⇅</span></th>
    <th data-col="change">전일비 / 등락률(%) <span class="sort-icon">⇅</span></th>
    <th data-col="per">PER (업종 PER) <span class="sort-icon">⇅</span></th>
    <th data-col="target">목표가(원) / 대비 <span class="sort-icon">⇅</span></th>
    <th class="left">매수 주체</th>
    <th class="left">최근 공시</th>
    <th></th>
  </tr></thead>
<tbody>
{% for item in individual %}
{% assign cls = "even" %}{% assign arrow = "—" %}
{% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
{% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}{% endif %}
{% assign upside = item.upside_pct %}
{% if upside > 0 %}{% assign upside_cls = "rising" %}{% assign upside_sign = "+" %}
{% elsif upside < 0 %}{% assign upside_cls = "falling" %}{% assign upside_sign = "" %}
{% else %}{% assign upside_cls = "even" %}{% assign upside_sign = "" %}{% endif %}
<tr data-code="{{ item.code }}">
  <td class="fics-cell" data-sort="{{ item.fics | default: '' }}">{% if item.fics %}<span class="fics-tag">{{ item.fics }}</span>{% else %}<span class="na">—</span>{% endif %}</td>
  <td data-sort="{{ item.name }}"><a href="https://m.stock.naver.com/domestic/stock/{{ item.code }}" target="_blank">{{ item.name }}</a></td>
  <td data-sort="{{ item.market_cap_eok | default: 0 }}">{% if item.market_cap_formatted %}{{ item.market_cap_formatted }}{% else %}<span class="na">—</span>{% endif %}</td>
  <td data-sort="{{ item.price | remove: ',' }}">{{ item.price }}</td>
  <td data-sort="{{ item.change_pct }}" class="{{ cls }}">{{ arrow }} {{ item.change | remove: "-" }} <span class="sub">({{ item.change_pct }}%)</span></td>
  <td data-sort="{{ item.per | default: 0 }}">
    {% if item.per %}{{ item.per }}{% if item.indu_per %}<span class="sub">({{ item.indu_per }})</span>{% endif %}{% else %}<span class="na">—</span>{% endif %}
  </td>
  <td data-sort="{{ item.upside_pct | default: -999 }}">
    {% if item.analyst_target %}
      {{ item.analyst_target.avg_formatted }}<span class="sub">({{ item.analyst_target.count }}건)</span>
      {% if item.upside_pct %}<br><span class="{{ upside_cls }}">{{ upside_sign }}{{ item.upside_pct }}%</span>{% endif %}
    {% else %}<span class="na">—</span>{% endif %}
  </td>
  <td class="investor-cell">
    {% if item.investor_streaks %}
      {% assign is = item.investor_streaks %}
      <div class="investor-row">
        {% assign v = is.indi | default: 0 %}
        <div class="investor-item">
          <span class="investor-label">개인</span>
          {% if v > 0 %}<span class="investor-buy">{% if is.indi_amount %}{{ is.indi_amount }}({{ v }}){% else %}{{ v }}{% endif %}</span>
          {% elsif v < 0 %}<span class="investor-sell">{% if is.indi_amount %}{{ is.indi_amount }}({{ v | abs }}){% else %}{{ v | abs }}{% endif %}</span>
          {% else %}<span class="investor-zero">—</span>{% endif %}
        </div>
        {% assign v = is.foreign | default: 0 %}
        <div class="investor-item">
          <span class="investor-label">외인</span>
          {% if v > 0 %}<span class="investor-buy">{% if is.foreign_amount %}{{ is.foreign_amount }}({{ v }}){% else %}{{ v }}{% endif %}</span>
          {% elsif v < 0 %}<span class="investor-sell">{% if is.foreign_amount %}{{ is.foreign_amount }}({{ v | abs }}){% else %}{{ v | abs }}{% endif %}</span>
          {% else %}<span class="investor-zero">—</span>{% endif %}
        </div>
        {% assign v = is.gigan | default: 0 %}
        <div class="investor-item">
          <span class="investor-label">기관</span>
          {% if v > 0 %}<span class="investor-buy">{% if is.gigan_amount %}{{ is.gigan_amount }}({{ v }}){% else %}{{ v }}{% endif %}</span>
          {% elsif v < 0 %}<span class="investor-sell">{% if is.gigan_amount %}{{ is.gigan_amount }}({{ v | abs }}){% else %}{{ v | abs }}{% endif %}</span>
          {% else %}<span class="investor-zero">—</span>{% endif %}
        </div>
      </div>
    {% else %}<span class="na">—</span>{% endif %}
  </td>
  <td class="disclosure-cell">
    {% if item.disclosure %}
      {% for d in item.disclosure %}
      <div class="disclosure-item">
        <span class="disclosure-title"><a href="{{ d.url }}" target="_blank">{{ d.title | truncate: 40 }}</a></span>
        <span class="disclosure-date">{{ d.datetime }}</span>
      </div>
      {% endfor %}
    {% else %}<span class="na">—</span>{% endif %}
  </td>
  <td></td>
</tr>
{% endfor %}
</tbody>
</table>
</div>
<p class="table-note">
    * 업종: FnGuide FICS 소분류 / PER: FnGuide FY1 컨센서스, 괄호는 업종 PER<br>
    * 목표가: FnGuide 컨센서스 단순 평균 / 매수 주체: 연속 순매수·매도 누적금액(빨강=매수, 파랑=매도), 괄호는 연속일수
  </p>
  </div><!-- #panel-kr-port -->

  <div class="minor-panel" id="panel-kr-watch">
  <div id="kr-adder" class="stock-adder">
    <input type="text" id="kr-search-input" class="stock-search-input" placeholder="종목명 검색 (예: 삼성)" autocomplete="off" />
    <div id="kr-search-dropdown" class="search-dropdown"></div>
  </div>
  <div class="table-scroll">
  <table class="stock-table" id="kr-watch-table">
  <thead><tr>
    <th class="left" data-col="fics">업종 <span class="sort-icon">⇅</span></th>
    <th data-col="name">종목 <span class="sort-icon">⇅</span></th>
    <th data-col="cap">시총(억) <span class="sort-icon">⇅</span></th>
    <th data-col="price">현재가(원) <span class="sort-icon">⇅</span></th>
    <th data-col="change">전일비 / 등락률(%) <span class="sort-icon">⇅</span></th>
    <th data-col="per">PER (업종 PER) <span class="sort-icon">⇅</span></th>
    <th data-col="target">목표가(원) / 대비 <span class="sort-icon">⇅</span></th>
    <th class="left">매수 주체</th>
    <th class="left">최근 공시</th>
    <th></th>
  </tr></thead>
  <tbody>
  {% for item in kr_watch %}
  {% assign cls = "even" %}{% assign arrow = "—" %}
  {% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
  {% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}{% endif %}
  {% assign upside = item.upside_pct %}
  {% if upside > 0 %}{% assign upside_cls = "rising" %}{% assign upside_sign = "+" %}
  {% elsif upside < 0 %}{% assign upside_cls = "falling" %}{% assign upside_sign = "" %}
  {% else %}{% assign upside_cls = "even" %}{% assign upside_sign = "" %}{% endif %}
  <tr data-code="{{ item.code }}">
    <td class="fics-cell" data-sort="{{ item.fics | default: '' }}">{% if item.fics %}<span class="fics-tag">{{ item.fics }}</span>{% else %}<span class="na">—</span>{% endif %}</td>
    <td data-sort="{{ item.name }}"><a href="https://m.stock.naver.com/domestic/stock/{{ item.code }}" target="_blank">{{ item.name }}</a></td>
    <td data-sort="{{ item.market_cap_eok | default: 0 }}">{% if item.market_cap_formatted %}{{ item.market_cap_formatted }}{% else %}<span class="na">—</span>{% endif %}</td>
    <td data-sort="{{ item.price | remove: ',' }}">{{ item.price }}</td>
    <td data-sort="{{ item.change_pct }}" class="{{ cls }}">{{ arrow }} {{ item.change | remove: "-" }} <span class="sub">({{ item.change_pct }}%)</span></td>
    <td data-sort="{{ item.per | default: 0 }}">{% if item.per %}{{ item.per }}{% if item.indu_per %}<span class="sub">({{ item.indu_per }})</span>{% endif %}{% else %}<span class="na">—</span>{% endif %}</td>
    <td data-sort="{{ item.upside_pct | default: -999 }}">{% if item.analyst_target %}{{ item.analyst_target.avg_formatted }}<span class="sub">({{ item.analyst_target.count }}건)</span>{% if item.upside_pct %}<br><span class="{{ upside_cls }}">{{ upside_sign }}{{ item.upside_pct }}%</span>{% endif %}{% else %}<span class="na">—</span>{% endif %}</td>
    <td class="investor-cell">{% if item.investor_streaks %}{% assign is = item.investor_streaks %}<div class="investor-row">{% assign v = is.indi | default: 0 %}<div class="investor-item"><span class="investor-label">개인</span>{% if v > 0 %}<span class="investor-buy">{% if is.indi_amount %}{{ is.indi_amount }}({{ v }}){% else %}{{ v }}{% endif %}</span>{% elsif v < 0 %}<span class="investor-sell">{% if is.indi_amount %}{{ is.indi_amount }}({{ v | abs }}){% else %}{{ v | abs }}{% endif %}</span>{% else %}<span class="investor-zero">—</span>{% endif %}</div>{% assign v = is.foreign | default: 0 %}<div class="investor-item"><span class="investor-label">외인</span>{% if v > 0 %}<span class="investor-buy">{% if is.foreign_amount %}{{ is.foreign_amount }}({{ v }}){% else %}{{ v }}{% endif %}</span>{% elsif v < 0 %}<span class="investor-sell">{% if is.foreign_amount %}{{ is.foreign_amount }}({{ v | abs }}){% else %}{{ v | abs }}{% endif %}</span>{% else %}<span class="investor-zero">—</span>{% endif %}</div>{% assign v = is.gigan | default: 0 %}<div class="investor-item"><span class="investor-label">기관</span>{% if v > 0 %}<span class="investor-buy">{% if is.gigan_amount %}{{ is.gigan_amount }}({{ v }}){% else %}{{ v }}{% endif %}</span>{% elsif v < 0 %}<span class="investor-sell">{% if is.gigan_amount %}{{ is.gigan_amount }}({{ v | abs }}){% else %}{{ v | abs }}{% endif %}</span>{% else %}<span class="investor-zero">—</span>{% endif %}</div></div>{% else %}<span class="na">—</span>{% endif %}</td>
    <td class="disclosure-cell">{% if item.disclosure %}{% for d in item.disclosure %}<div class="disclosure-item"><span class="disclosure-title"><a href="{{ d.url }}" target="_blank">{{ d.title | truncate: 40 }}</a></span><span class="disclosure-date">{{ d.datetime }}</span></div>{% endfor %}{% else %}<span class="na">—</span>{% endif %}</td>
    <td></td>
  </tr>
  {% endfor %}
  {% if kr_watch.size == 0 %}
  <tr id="kr-watch-empty"><td colspan="10" style="text-align:center;color:#ccc;padding:2em;">검색해서 관심 종목을 추가해보세요.</td></tr>
  {% endif %}
  </tbody></table></div>
  </div><!-- #panel-kr-watch -->
</div><!-- #panel-kr -->

<!-- ══ ETF / ETN 패널 ══ -->
<div class="major-panel" id="panel-etf">
  <div class="tabs-minor">
    <button class="tab-minor active" data-panel="panel-etf-port">내 포트폴리오</button>
    <button class="tab-minor" data-panel="panel-etf-watch">관심주</button>
  </div>
  <div class="minor-panel active" id="panel-etf-port">
  <div id="etf-port-adder" class="stock-adder">
    <input type="text" id="etf-port-search-input" class="stock-search-input" placeholder="ETF명 검색 (예: KODEX)" autocomplete="off" />
    <div id="etf-port-search-dropdown" class="search-dropdown"></div>
  </div>
  <div class="table-scroll">
  <table class="stock-table" id="etf-port-table">
  <thead><tr>
    <th data-col="name">종목 <span class="sort-icon">⇅</span></th>
    <th data-col="price">현재가(원) <span class="sort-icon">⇅</span></th>
    <th data-col="change">전일비 / 등락률(%) <span class="sort-icon">⇅</span></th>
    <th class="left">구성 종목 TOP5</th>
    <th></th>
  </tr></thead>
  <tbody>
  {% for item in etfs %}
  {% assign cls = "even" %}{% assign arrow = "—" %}
  {% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
  {% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}{% endif %}
  <tr data-code="{{ item.code }}">
    <td data-sort="{{ item.name }}"><a href="https://m.stock.naver.com/domestic/stock/{{ item.code }}" target="_blank">{{ item.name }}</a></td>
    <td data-sort="{{ item.price | remove: ',' }}">{{ item.price }}</td>
    <td data-sort="{{ item.change_pct }}" class="{{ cls }}">{{ arrow }} {{ item.change | remove: "-" }} <span class="sub">({{ item.change_pct }}%)</span></td>
    <td class="holdings-cell">{% if item.holdings %}<ul class="holdings-list">{% for h in item.holdings %}<li>{{ h.name }}<span class="holdings-ratio">{{ h.ratio }}</span></li>{% endfor %}</ul>{% else %}<span class="na">—</span>{% endif %}</td>
    <td></td>
  </tr>
  {% endfor %}
  </tbody></table></div>
  </div><!-- #panel-etf-port -->
  <div class="minor-panel" id="panel-etf-watch">
  <div id="etf-adder" class="stock-adder">
    <input type="text" id="etf-search-input" class="stock-search-input" placeholder="ETF명 검색 (예: KODEX)" autocomplete="off" />
    <div id="etf-search-dropdown" class="search-dropdown"></div>
  </div>
  <div class="table-scroll">
  <table class="stock-table" id="etf-watch-table">
  <thead><tr>
    <th data-col="name">종목 <span class="sort-icon">⇅</span></th>
    <th data-col="price">현재가(원) <span class="sort-icon">⇅</span></th>
    <th data-col="change">전일비 / 등락률(%) <span class="sort-icon">⇅</span></th>
    <th class="left">구성 종목 TOP5</th>
    <th></th>
  </tr></thead>
  <tbody>
  <tr id="etf-watch-empty"><td colspan="5" style="text-align:center;color:#ccc;padding:2em;">검색해서 관심 ETF를 추가해보세요.</td></tr>
  </tbody></table></div>
  </div><!-- #panel-etf-watch -->
</div><!-- #panel-etf -->

<!-- ══ 해외 주식 패널 ══ -->
<div class="major-panel" id="panel-us">
  <div class="tabs-minor">
    <button class="tab-minor active" data-panel="panel-us-port">내 포트폴리오</button>
    <button class="tab-minor" data-panel="panel-us-watch">관심주</button>
  </div>
  <div class="minor-panel active" id="panel-us-port">
  <div id="us-port-adder" class="stock-adder">
    <input type="text" id="us-port-search-input" class="stock-search-input" placeholder="종목 검색 (예: Apple, AAPL)" autocomplete="off" />
    <div id="us-port-search-dropdown" class="search-dropdown"></div>
  </div>
  <div class="table-scroll">
  <table class="stock-table" id="us-port-table">
  <thead><tr>
    <th class="left" data-col="fics">업종 <span class="sort-icon">⇅</span></th>
    <th data-col="name">종목 <span class="sort-icon">⇅</span></th>
    <th data-col="cap">시총(억) <span class="sort-icon">⇅</span></th>
    <th data-col="price">현재가(원) <span class="sort-icon">⇅</span></th>
    <th data-col="change">전일비 / 등락률(%) <span class="sort-icon">⇅</span></th>
    <th data-col="per">PER <span class="sort-icon">⇅</span></th>
    <th data-col="target">목표가(원) / 대비 <span class="sort-icon">⇅</span></th>
    <th></th>
  </tr></thead>
  <tbody>
  {% for item in us_port %}
  {% assign cls = "even" %}{% assign arrow = "—" %}
  {% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
  {% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}{% endif %}
  {% assign upside = item.upside_pct %}
  {% if upside > 0 %}{% assign upside_cls = "rising" %}{% assign upside_sign = "+" %}
  {% elsif upside < 0 %}{% assign upside_cls = "falling" %}{% assign upside_sign = "" %}
  {% else %}{% assign upside_cls = "even" %}{% assign upside_sign = "" %}{% endif %}
  <tr data-code="{{ item.code }}">
    <td class="fics-cell" data-sort="{{ item.fics | default: '' }}">{% if item.fics %}<span class="fics-tag">{{ item.fics }}</span>{% else %}<span class="na">—</span>{% endif %}</td>
    <td data-sort="{{ item.name }}"><a href="https://finance.yahoo.com/quote/{{ item.code }}" target="_blank">{{ item.name }}</a></td>
    <td data-sort="{{ item.market_cap_eok | default: 0 }}">{% if item.market_cap_formatted %}{{ item.market_cap_formatted }}<span class="sub-usd">({{ item.market_cap_usd_formatted }})</span>{% else %}<span class="na">—</span>{% endif %}</td>
    <td data-sort="{{ item.price | remove: ',' }}">{{ item.price }}<span class="sub-usd">({{ item.price_usd }})</span></td>
    <td data-sort="{{ item.change_pct }}" class="{{ cls }}">{{ arrow }} {{ item.change }} <span class="sub">({{ item.change_pct }}%)</span></td>
    <td data-sort="{{ item.per | default: 0 }}">{% if item.per %}{{ item.per }}{% else %}<span class="na">—</span>{% endif %}</td>
    <td data-sort="{{ item.upside_pct | default: -999 }}">{% if item.analyst_target %}{{ item.analyst_target.avg_formatted }}<span class="sub-usd">({{ item.analyst_target.avg_usd }})</span> <span class="sub">· {{ item.analyst_target.count }}건</span>{% if item.upside_pct %}<br><span class="{{ upside_cls }}">{{ upside_sign }}{{ item.upside_pct }}%</span>{% endif %}{% else %}<span class="na">—</span>{% endif %}</td>
    <td></td>
  </tr>
  {% endfor %}
  {% if us_port.size == 0 %}
  <tr id="us-port-empty"><td colspan="8" style="text-align:center;color:#ccc;padding:2em;">검색해서 해외 포트폴리오를 추가해보세요.</td></tr>
  {% endif %}
  </tbody></table></div>
  </div><!-- #panel-us-port -->

  <div class="minor-panel" id="panel-us-watch">
  <div id="us-adder" class="stock-adder">
    <input type="text" id="us-search-input" class="stock-search-input" placeholder="종목 검색 (예: Apple, AAPL)" autocomplete="off" />
    <div id="us-search-dropdown" class="search-dropdown"></div>
  </div>
  <div class="table-scroll">
  <table class="stock-table" id="us-watch-table">
  <thead><tr>
    <th class="left" data-col="fics">업종 <span class="sort-icon">⇅</span></th>
    <th data-col="name">종목 <span class="sort-icon">⇅</span></th>
    <th data-col="cap">시총(억) <span class="sort-icon">⇅</span></th>
    <th data-col="price">현재가(원) <span class="sort-icon">⇅</span></th>
    <th data-col="change">전일비 / 등락률(%) <span class="sort-icon">⇅</span></th>
    <th data-col="per">PER <span class="sort-icon">⇅</span></th>
    <th data-col="target">목표가(원) / 대비 <span class="sort-icon">⇅</span></th>
    <th></th>
  </tr></thead>
  <tbody>
  {% for item in us_watch %}
  {% assign cls = "even" %}{% assign arrow = "—" %}
  {% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
  {% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}{% endif %}
  {% assign upside = item.upside_pct %}
  {% if upside > 0 %}{% assign upside_cls = "rising" %}{% assign upside_sign = "+" %}
  {% elsif upside < 0 %}{% assign upside_cls = "falling" %}{% assign upside_sign = "" %}
  {% else %}{% assign upside_cls = "even" %}{% assign upside_sign = "" %}{% endif %}
  <tr data-code="{{ item.code }}">
    <td class="fics-cell" data-sort="{{ item.fics | default: '' }}">{% if item.fics %}<span class="fics-tag">{{ item.fics }}</span>{% else %}<span class="na">—</span>{% endif %}</td>
    <td data-sort="{{ item.name }}"><a href="https://finance.yahoo.com/quote/{{ item.code }}" target="_blank">{{ item.name }}</a></td>
    <td data-sort="{{ item.market_cap_eok | default: 0 }}">{% if item.market_cap_formatted %}{{ item.market_cap_formatted }}<span class="sub-usd">({{ item.market_cap_usd_formatted }})</span>{% else %}<span class="na">—</span>{% endif %}</td>
    <td data-sort="{{ item.price | remove: ',' }}">{{ item.price }}<span class="sub-usd">({{ item.price_usd }})</span></td>
    <td data-sort="{{ item.change_pct }}" class="{{ cls }}">{{ arrow }} {{ item.change }} <span class="sub">({{ item.change_pct }}%)</span></td>
    <td data-sort="{{ item.per | default: 0 }}">{% if item.per %}{{ item.per }}{% else %}<span class="na">—</span>{% endif %}</td>
    <td data-sort="{{ item.upside_pct | default: -999 }}">{% if item.analyst_target %}{{ item.analyst_target.avg_formatted }}<span class="sub-usd">({{ item.analyst_target.avg_usd }})</span> <span class="sub">· {{ item.analyst_target.count }}건</span>{% if item.upside_pct %}<br><span class="{{ upside_cls }}">{{ upside_sign }}{{ item.upside_pct }}%</span>{% endif %}{% else %}<span class="na">—</span>{% endif %}</td>
    <td></td>
  </tr>
  {% endfor %}
  {% if us_watch.size == 0 %}
  <tr id="us-watch-empty"><td colspan="8" style="text-align:center;color:#ccc;padding:2em;">검색해서 관심 해외 주식을 추가해보세요.</td></tr>
  {% endif %}
  </tbody></table></div>
  <p class="table-note">
    * 업종: Yahoo Finance 산업 분류 / PER: Forward PE (없을 경우 Trailing PE)<br>
    * 현재가·시총·목표가: 원화 환산액, 괄호 안은 USD 원래 값 (환율: 경제 지표 기준)
  </p>
  </div><!-- #panel-us-watch -->
</div><!-- #panel-us -->

</div><!-- .tables-col -->

<aside class="ai-sidebar">
  <p class="ai-sidebar-title">Claude 의견</p>
  {% for item in individual %}
  <div class="opinion-card">
    <div class="opinion-name">{{ item.name }}</div>
    {% if item.opinion %}
      <div class="opinion-text">{{ item.opinion }}</div>
    {% else %}
      <div class="opinion-pending">데이터 수집 후 표시됩니다</div>
    {% endif %}
  </div>
  {% endfor %}
</aside>

</div><!-- .page-grid -->
</div><!-- .page-outer -->

{% else %}
<p>데이터가 없습니다. <code>ruby mystocks/mystocks_scraper.rb</code>를 실행해주세요.</p>
{% endif %}

<script>
var KR_STOCKS = {{ site.data.mystocks.kr_stocks_list | default: "[]" | jsonify }};
var WATCHLIST = {{ site.data.watchlist | jsonify }};
var US_STOCKS_LIST = [
  {code:'AAPL',name:'Apple Inc.'},{code:'MSFT',name:'Microsoft Corporation'},{code:'NVDA',name:'NVIDIA Corporation'},
  {code:'AMZN',name:'Amazon.com Inc.'},{code:'META',name:'Meta Platforms Inc.'},{code:'GOOGL',name:'Alphabet Inc. (Class A)'},
  {code:'GOOG',name:'Alphabet Inc. (Class C)'},{code:'TSLA',name:'Tesla Inc.'},{code:'AVGO',name:'Broadcom Inc.'},
  {code:'JPM',name:'JPMorgan Chase & Co.'},{code:'LLY',name:'Eli Lilly and Company'},{code:'V',name:'Visa Inc.'},
  {code:'UNH',name:'UnitedHealth Group Inc.'},{code:'XOM',name:'Exxon Mobil Corporation'},{code:'MA',name:'Mastercard Inc.'},
  {code:'JNJ',name:'Johnson & Johnson'},{code:'COST',name:'Costco Wholesale Corporation'},{code:'PG',name:'Procter & Gamble Company'},
  {code:'HD',name:'The Home Depot Inc.'},{code:'NFLX',name:'Netflix Inc.'},{code:'AMD',name:'Advanced Micro Devices Inc.'},
  {code:'MU',name:'Micron Technology Inc.'},{code:'INTC',name:'Intel Corporation'},{code:'CRM',name:'Salesforce Inc.'},
  {code:'ORCL',name:'Oracle Corporation'},{code:'QCOM',name:'QUALCOMM Inc.'},{code:'AMAT',name:'Applied Materials Inc.'},
  {code:'LRCX',name:'Lam Research Corporation'},{code:'KLAC',name:'KLA Corporation'},{code:'TXN',name:'Texas Instruments Inc.'},
  {code:'PANW',name:'Palo Alto Networks Inc.'},{code:'CRWD',name:'CrowdStrike Holdings Inc.'},{code:'NOW',name:'ServiceNow Inc.'},
  {code:'SNOW',name:'Snowflake Inc.'},{code:'DDOG',name:'Datadog Inc.'},{code:'NET',name:'Cloudflare Inc.'},
  {code:'PLTR',name:'Palantir Technologies Inc.'},{code:'ARM',name:'Arm Holdings plc'},{code:'TSM',name:'Taiwan Semiconductor Manufacturing'},
  {code:'SMCI',name:'Super Micro Computer Inc.'},{code:'MRVL',name:'Marvell Technology Inc.'},{code:'ON',name:'ON Semiconductor'},
  {code:'WMT',name:'Walmart Inc.'},{code:'DIS',name:'The Walt Disney Company'},{code:'UBER',name:'Uber Technologies Inc.'},
  {code:'ABNB',name:'Airbnb Inc.'},{code:'SHOP',name:'Shopify Inc.'},{code:'SPOT',name:'Spotify Technology S.A.'},
  {code:'NFLX',name:'Netflix Inc.'},{code:'PYPL',name:'PayPal Holdings Inc.'},{code:'SQ',name:'Block Inc.'},
  {code:'COIN',name:'Coinbase Global Inc.'},{code:'MSTR',name:'MicroStrategy Inc.'},{code:'HOOD',name:'Robinhood Markets Inc.'},
  {code:'RIVN',name:'Rivian Automotive Inc.'},{code:'NIO',name:'NIO Inc.'},{code:'BABA',name:'Alibaba Group Holding Ltd.'},
  {code:'BIDU',name:'Baidu Inc.'},{code:'PDD',name:'PDD Holdings Inc.'},{code:'JD',name:'JD.com Inc.'},
  {code:'LMT',name:'Lockheed Martin Corporation'},{code:'BA',name:'The Boeing Company'},{code:'RTX',name:'RTX Corporation'},
  {code:'GE',name:'GE Aerospace'},{code:'CAT',name:'Caterpillar Inc.'},{code:'HON',name:'Honeywell International Inc.'},
  {code:'BAC',name:'Bank of America Corporation'},{code:'WFC',name:'Wells Fargo & Company'},{code:'GS',name:'The Goldman Sachs Group Inc.'},
  {code:'MS',name:'Morgan Stanley'},{code:'C',name:'Citigroup Inc.'},{code:'BLK',name:'BlackRock Inc.'},
  {code:'AXP',name:'American Express Company'},{code:'PFE',name:'Pfizer Inc.'},{code:'ABBV',name:'AbbVie Inc.'},
  {code:'MRK',name:'Merck & Co. Inc.'},{code:'AMGN',name:'Amgen Inc.'},{code:'MRNA',name:'Moderna Inc.'},
  {code:'GILD',name:'Gilead Sciences Inc.'},{code:'CVX',name:'Chevron Corporation'},{code:'COP',name:'ConocoPhillips'},
  {code:'NEE',name:'NextEra Energy Inc.'},{code:'T',name:'AT&T Inc.'},{code:'VZ',name:'Verizon Communications Inc.'},
  {code:'TMUS',name:'T-Mobile US Inc.'},{code:'CMCSA',name:'Comcast Corporation'},
  {code:'AMT',name:'American Tower Corporation'},{code:'EQIX',name:'Equinix Inc.'},{code:'DLR',name:'Digital Realty Trust Inc.'},
  {code:'SPY',name:'SPDR S&P 500 ETF Trust'},{code:'QQQ',name:'Invesco QQQ Trust'},{code:'IWM',name:'iShares Russell 2000 ETF'},
  {code:'SOXL',name:'Direxion Daily Semiconductor Bull 3X'},{code:'TQQQ',name:'ProShares UltraPro QQQ'},
  {code:'IBM',name:'International Business Machines'},{code:'ACN',name:'Accenture plc'},{code:'DELL',name:'Dell Technologies Inc.'},
  {code:'HPE',name:'Hewlett Packard Enterprise'},{code:'WDAY',name:'Workday Inc.'},{code:'HUBS',name:'HubSpot Inc.'},
  {code:'TEAM',name:'Atlassian Corporation'},{code:'ZM',name:'Zoom Video Communications'},{code:'DOCU',name:'DocuSign Inc.'},
  {code:'MDB',name:'MongoDB Inc.'},{code:'CFLT',name:'Confluent Inc.'},{code:'TTD',name:'The Trade Desk Inc.'},
  {code:'ROKU',name:'Roku Inc.'},{code:'SOFI',name:'SoFi Technologies Inc.'},{code:'SNAP',name:'Snap Inc.'}
];

(function () {
  // 대분류탭 전환
  var majorBtns = document.querySelectorAll('.tab-major');
  majorBtns.forEach(function (btn) {
    btn.addEventListener('click', function () {
      majorBtns.forEach(function (b) { b.classList.remove('active'); });
      document.querySelectorAll('.major-panel').forEach(function (p) { p.classList.remove('active'); });
      btn.classList.add('active');
      var panel = document.getElementById('panel-' + btn.dataset.major);
      if (panel) panel.classList.add('active');
    });
  });

  // 중분류탭 전환
  document.querySelectorAll('.tab-minor').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var parent = btn.closest('.major-panel');
      parent.querySelectorAll('.tab-minor').forEach(function (b) { b.classList.remove('active'); });
      parent.querySelectorAll('.minor-panel').forEach(function (p) { p.classList.remove('active'); });
      btn.classList.add('active');
      var panel = document.getElementById(btn.dataset.panel);
      if (panel) panel.classList.add('active');
    });
  });

  // 열 정렬 (빈 행 고정)
  var state = {};
  document.querySelectorAll('.stock-table th[data-col]').forEach(function (th) {
    th.addEventListener('click', function () {
      var table = th.closest('table');
      var ths = Array.from(table.querySelectorAll('thead th'));
      var ci = ths.indexOf(th);
      var key = table.id + '-' + ci;
      var asc = !state[key];
      state[key] = asc;

      ths.forEach(function (t) {
        var ic = t.querySelector('.sort-icon');
        if (ic) ic.textContent = '⇅';
        t.classList.remove('sort-asc', 'sort-desc');
      });
      var icon = th.querySelector('.sort-icon');
      if (icon) icon.textContent = asc ? '▲' : '▼';
      th.classList.add(asc ? 'sort-asc' : 'sort-desc');

      var tbody = table.querySelector('tbody');
      var emptyRows = Array.from(tbody.querySelectorAll('tr[id$="-empty"]'));
      var rows = Array.from(tbody.querySelectorAll('tr')).filter(function(r) { return !r.id.endsWith('-empty'); });
      rows.sort(function (a, b) {
        var ac = a.cells[ci], bc = b.cells[ci];
        var av = ac ? (ac.dataset.sort !== undefined ? ac.dataset.sort : ac.textContent.trim()) : '';
        var bv = bc ? (bc.dataset.sort !== undefined ? bc.dataset.sort : bc.textContent.trim()) : '';
        var an = parseFloat(av), bn = parseFloat(bv);
        if (!isNaN(an) && !isNaN(bn)) return asc ? an - bn : bn - an;
        return asc ? av.localeCompare(bv, 'ko') : bv.localeCompare(av, 'ko');
      });
      rows.forEach(function (r) { tbody.appendChild(r); });
      emptyRows.forEach(function(r) { tbody.appendChild(r); });
    });
  });
})();

// ── 관심주 공통 검색/추가 ──────────────────────────
function escHtml(str) {
  return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function setupWatchSearch(opts) {
  var input    = document.getElementById(opts.inputId);
  var dropdown = document.getElementById(opts.dropdownId);
  if (!input || !dropdown) return;

  var stocks   = opts.type === 'us' ? US_STOCKS_LIST : KR_STOCKS;
  var timer    = null;
  var sk       = opts.storageKey;
  var selIdx   = -1;

  function loadList() { try { return JSON.parse(localStorage.getItem(sk) || '[]'); } catch(e) { return []; } }
  function saveList(list) { try { localStorage.setItem(sk, JSON.stringify(list)); } catch(e) {} }
  function hasCode(code) { return loadList().some(function(s) { return s.code === code; }); }
  function getItems() { return Array.from(dropdown.querySelectorAll('.search-item')); }
  function hideDD() { dropdown.style.display = 'none'; dropdown.innerHTML = ''; selIdx = -1; }
  function setSelected(idx) {
    var items = getItems();
    items.forEach(function(el) { el.classList.remove('selected'); });
    selIdx = (items.length === 0) ? -1 : Math.max(0, Math.min(idx, items.length - 1));
    if (selIdx >= 0) items[selIdx].classList.add('selected');
  }

  input.addEventListener('input', function() {
    clearTimeout(timer);
    selIdx = -1;
    var q = this.value.trim();
    if (!q) { hideDD(); return; }
    timer = setTimeout(function() { doSearch(q); }, 150);
  });
  input.addEventListener('keydown', function(e) {
    var items = getItems();
    if (e.key === 'Escape') { hideDD(); input.value = ''; return; }
    if (e.key === 'ArrowDown') { e.preventDefault(); setSelected(selIdx + 1); return; }
    if (e.key === 'ArrowUp')   { e.preventDefault(); setSelected(selIdx <= 0 ? 0 : selIdx - 1); return; }
    if (e.key === 'Enter') {
      var target = selIdx >= 0 ? items[selIdx] : items[0];
      if (target) { addStock(target.dataset.code, target.dataset.name); hideDD(); input.value = ''; }
    }
  });
  document.addEventListener('click', function(e) {
    var adder = input.closest('.stock-adder');
    if (adder && !adder.contains(e.target)) hideDD();
  });

  function doSearch(q) {
    q = q.toLowerCase();
    var matches = stocks.filter(function(s) {
      return s.name.toLowerCase().indexOf(q) !== -1 || s.code.toLowerCase().indexOf(q) !== -1;
    }).slice(0, 8);
    if (!matches.length) {
      dropdown.innerHTML = '<div class="search-no-result">검색 결과 없음</div>';
      dropdown.style.display = 'block';
      return;
    }
    dropdown.innerHTML = matches.map(function(s) {
      var mkt = s.market ? s.market.toLowerCase() : '';
      var mktBadge = (mkt === 'kospi' || mkt === 'kosdaq')
        ? '<span class="si-market ' + mkt + '">' + s.market.toUpperCase() + '</span>' : '';
      return '<div class="search-item" data-code="' + escHtml(s.code) + '" data-name="' + escHtml(s.name) + '">' +
        '<span class="si-name">' + escHtml(s.name) + '</span>' +
        '<span class="si-code">' + escHtml(s.code) + mktBadge + '</span></div>';
    }).join('');
    dropdown.style.display = 'block';
    dropdown.querySelectorAll('.search-item').forEach(function(el) {
      el.addEventListener('click', function() {
        addStock(this.dataset.code, this.dataset.name); hideDD(); input.value = '';
      });
    });
  }

  function addStock(code, name) {
    // If hidden static row exists, un-hide it instead of adding a new dynamic row
    if (opts.hiddenKey) {
      var tbody = document.querySelector('#' + opts.tableId + ' tbody');
      if (tbody) {
        var staticRows = tbody.querySelectorAll('tr[data-code]:not([data-dynamic])');
        for (var i = 0; i < staticRows.length; i++) {
          if (staticRows[i].dataset.code === code && staticRows[i].style.display === 'none') {
            staticRows[i].style.display = '';
            var h = JSON.parse(localStorage.getItem(opts.hiddenKey) || '[]');
            h = h.filter(function(c) { return c !== code; });
            localStorage.setItem(opts.hiddenKey, JSON.stringify(h));
            initStaticTrashRow(staticRows[i], opts.hiddenKey);
            return;
          }
        }
      }
    }
    var existing = document.querySelector('#' + opts.tableId + ' tbody tr[data-code="' + code + '"]');
    if (existing && existing.style.display !== 'none') { alert(name + ' 은(는) 이미 목록에 있습니다.'); return; }
    if (hasCode(code)) { alert(name + ' 은(는) 이미 추가되어 있습니다.'); return; }
    var list = loadList(); list.push({code:code, name:name}); saveList(list);
    fetchAndRender(code, name);
  }

  function fetchAndRender(code, name) {
    // YAML 정적 행이 이미 표시 중이면 중복 추가 않음
    var tbody = document.querySelector('#' + opts.tableId + ' tbody');
    if (tbody) {
      var sRows = tbody.querySelectorAll('tr[data-code]:not([data-dynamic])');
      for (var si = 0; si < sRows.length; si++) {
        if (sRows[si].dataset.code === code && sRows[si].style.display !== 'none') return;
      }
    }
    var type = opts.type;
    fetch('http://localhost:9001/api/stock/' + encodeURIComponent(code) + '?type=' + type)
      .then(function(r) { if (!r.ok) throw new Error('server'); return r.json(); })
      .then(function(d) {
        if (d.error) throw new Error(d.error);
        var extra = {};
        if (d.fics)                     extra.fics       = d.fics;
        if (d.market_cap_formatted)     extra.cap        = d.market_cap_formatted;
        if (d.market_cap_eok)           extra.capNum     = d.market_cap_eok;
        if (d.market_cap_usd_formatted) extra.capUsd     = d.market_cap_usd_formatted;
        if (d.per != null)              extra.per        = String(d.per);
        if (d.indu_per != null)         extra.induPer    = String(d.indu_per);
        if (d.analyst_target) {
          extra.targetFmt   = d.analyst_target.avg_formatted;
          extra.targetCount = d.analyst_target.count;
          extra.targetUsd   = d.analyst_target.avg_usd;
        }
        if (d.upside_pct != null)       extra.upside     = d.upside_pct;
        if (d.investor_streaks)         extra.investor   = d.investor_streaks;
        if (d.disclosure)               extra.disclosure = d.disclosure;
        if (d.holdings)                 extra.holdings   = d.holdings;
        if (d.price_usd)                extra.priceUsd   = d.price_usd;
        appendRow(code, d.name || name, d.price || '—', d.change || '—',
                  d.change_pct != null ? String(d.change_pct) : '0', d.direction || 'EVEN', extra);
      })
      .catch(function() { fallbackFetch(code, name); });
  }

  function fallbackFetch(code, name) {
    if (opts.type === 'us') {
      fetch('https://query1.finance.yahoo.com/v8/finance/chart/' + code + '?interval=1d&range=1d')
        .then(function(r) { return r.json(); })
        .then(function(d) {
          var meta = d.chart && d.chart.result && d.chart.result[0] && d.chart.result[0].meta;
          if (!meta) throw new Error('no data');
          var price = meta.regularMarketPrice || 0, prev = meta.previousClose || price;
          var chg = price - prev, pct = prev > 0 ? ((chg / prev) * 100).toFixed(2) : 0;
          var cap = meta.marketCap;
          var capStr = cap > 0 ? (cap >= 1e12 ? '$' + (cap/1e12).toFixed(2) + 'T' : cap >= 1e9 ? '$' + (cap/1e9).toFixed(1) + 'B' : '$' + (cap/1e6).toFixed(0) + 'M') : '';
          appendRow(code, name, price.toFixed(2), Math.abs(chg).toFixed(2), pct, chg >= 0 ? 'RISING' : 'FALLING', {cap: capStr, capNum: cap || 0});
        })
        .catch(function() { appendRow(code, name, '—', '—', '0', 'EVEN', {}); });
    } else {
      fetch('https://m.stock.naver.com/api/stock/' + code + '/basic')
        .then(function(r) { return r.json(); })
        .then(function(d) {
          var dir = d.compareToPreviousPrice ? d.compareToPreviousPrice.name : 'EVEN';
          var rawChg = String(d.compareToPreviousClosePrice || '');
          appendRow(code, d.stockName || name, d.closePrice || '—', rawChg.replace(/^-/, '').trim() || '—', d.fluctuationsRatio || '0', dir, {});
        })
        .catch(function() { appendRow(code, name, '—', '—', '0', 'EVEN', {}); });
    }
  }

  function appendRow(code, name, price, change, pct, dir, extra) {
    extra = extra || {};
    if (opts.emptyRowId) { var emptyEl = document.getElementById(opts.emptyRowId); if (emptyEl) emptyEl.remove(); }
    var tbody = document.querySelector('#' + opts.tableId + ' tbody');
    if (!tbody) return;
    var cls   = dir === 'RISING' ? 'rising' : dir === 'FALLING' ? 'falling' : 'even';
    var arrow = dir === 'RISING' ? '▲' : dir === 'FALLING' ? '▼' : '—';
    var pNum  = String(price).replace(/,/g, '');
    var link  = opts.type === 'us' ? 'https://finance.yahoo.com/quote/' : 'https://m.stock.naver.com/domestic/stock/';
    var na    = '<td><span class="na">—</span></td>';

    var nameCell   = '<td data-sort="' + escHtml(name) + '"><a href="' + link + escHtml(code) + '" target="_blank">' + escHtml(name) + '</a></td>';
    var priceCell  = '<td data-sort="' + escHtml(pNum) + '">' + escHtml(String(price))
      + (extra.priceUsd ? '<span class="sub-usd">(' + escHtml(extra.priceUsd) + ')</span>' : '') + '</td>';
    var changeCell = '<td data-sort="' + escHtml(String(pct)) + '" class="' + cls + '">' + arrow + ' '
      + escHtml(String(change)) + ' <span class="sub">(' + escHtml(String(pct)) + '%)</span></td>';

    var ficsCell = extra.fics
      ? '<td class="fics-cell" data-sort="' + escHtml(extra.fics) + '"><span class="fics-tag">' + escHtml(extra.fics) + '</span></td>'
      : '<td class="fics-cell" data-sort=""><span class="na">—</span></td>';

    var capCell = extra.cap
      ? '<td data-sort="' + escHtml(String(extra.capNum || 0)) + '">' + escHtml(extra.cap)
        + (extra.capUsd ? '<span class="sub-usd">(' + escHtml(extra.capUsd) + ')</span>' : '') + '</td>'
      : na;

    var perCell = extra.per
      ? '<td data-sort="' + escHtml(extra.per) + '">' + escHtml(extra.per)
        + (extra.induPer ? '<span class="sub">(' + escHtml(extra.induPer) + ')</span>' : '') + '</td>'
      : na;

    var targetCell;
    if (extra.targetFmt) {
      var up = extra.upside, upCls = up > 0 ? 'rising' : up < 0 ? 'falling' : 'even', upSign = up > 0 ? '+' : '';
      targetCell = '<td data-sort="' + escHtml(String(up != null ? up : -999)) + '">'
        + escHtml(extra.targetFmt)
        + (extra.targetUsd ? '<span class="sub-usd">(' + escHtml(extra.targetUsd) + ')</span>' : '')
        + (extra.targetCount ? ' <span class="sub">· ' + escHtml(String(extra.targetCount)) + '건</span>' : '')
        + (up != null ? '<br><span class="' + upCls + '">' + upSign + escHtml(String(up)) + '%</span>' : '')
        + '</td>';
    } else { targetCell = na; }

    var investorCell;
    if (extra.investor) {
      var is = extra.investor;
      var iH = '<td class="investor-cell"><div class="investor-row">';
      [['indi','개인'],['foreign','외인'],['gigan','기관']].forEach(function(p) {
        var v = is[p[0]] || 0;
        var amt = is[p[0] + '_amount'];
        var disp = amt ? escHtml(amt) + '(' + Math.abs(v) + ')' : (v !== 0 ? String(Math.abs(v)) : '');
        iH += '<div class="investor-item"><span class="investor-label">' + p[1] + '</span>';
        iH += v > 0 ? '<span class="investor-buy">' + disp + '</span>'
            : v < 0 ? '<span class="investor-sell">' + disp + '</span>'
            : '<span class="investor-zero">—</span>';
        iH += '</div>';
      });
      iH += '</div></td>';
      investorCell = iH;
    } else { investorCell = '<td class="investor-cell"><span class="na">—</span></td>'; }

    var disclosureCell;
    if (extra.disclosure) {
      var discArr = Array.isArray(extra.disclosure) ? extra.disclosure : [extra.disclosure];
      disclosureCell = '<td class="disclosure-cell">';
      discArr.forEach(function(dc) {
        var t = (dc.title || '');
        if (t.length > 40) t = t.slice(0, 40) + '…';
        disclosureCell += '<div class="disclosure-item">'
          + '<span class="disclosure-title"><a href="' + escHtml(dc.url || '#') + '" target="_blank">' + escHtml(t) + '</a></span>'
          + '<span class="disclosure-date">' + escHtml(dc.datetime || '') + '</span>'
          + '</div>';
      });
      disclosureCell += '</td>';
    } else { disclosureCell = '<td class="disclosure-cell"><span class="na">—</span></td>'; }

    var holdingsCell;
    if (extra.holdings && extra.holdings.length) {
      var hH = '<ul class="holdings-list">';
      extra.holdings.forEach(function(h) { hH += '<li>' + escHtml(h.name) + '<span class="holdings-ratio">' + escHtml(h.ratio) + '</span></li>'; });
      holdingsCell = '<td class="holdings-cell">' + hH + '</ul></td>';
    } else { holdingsCell = '<td class="holdings-cell"><span class="na">—</span></td>'; }

    var trash = '<td><button class="remove-btn" data-code="' + escHtml(code) + '" title="삭제">🗑</button></td>';
    var inner;
    if (opts.type === 'etf') {
      inner = nameCell + priceCell + changeCell + holdingsCell + trash;
    } else if (opts.type === 'us') {
      inner = ficsCell + nameCell + capCell + priceCell + changeCell + perCell + targetCell + trash;
    } else {
      inner = ficsCell + nameCell + capCell + priceCell + changeCell + perCell + targetCell + investorCell + disclosureCell + trash;
    }

    var tr = document.createElement('tr');
    tr.setAttribute('data-dynamic', 'true'); tr.setAttribute('data-code', code);
    tr.innerHTML = inner;
    tr.querySelector('.remove-btn').addEventListener('click', function() {
      var c = this.dataset.code;
      saveList(loadList().filter(function(s) { return s.code !== c; }));
      tr.remove(); restoreEmpty();
    });
    tbody.appendChild(tr);
  }

  function restoreEmpty() {
    if (!opts.emptyRowId) return;
    var tbody = document.querySelector('#' + opts.tableId + ' tbody');
    var visible = Array.from(tbody.querySelectorAll('tr')).filter(function(r) { return r.style.display !== 'none'; });
    if (!tbody || visible.length > 0) return;
    var tr = document.createElement('tr'); tr.id = opts.emptyRowId;
    tr.innerHTML = '<td colspan="' + opts.cols + '" style="text-align:center;color:#ccc;padding:2em;">검색해서 관심 종목을 추가해보세요.</td>';
    tbody.appendChild(tr);
  }

  loadList().forEach(function(s) { fetchAndRender(s.code, s.name); });
}

// ── 정적 행 삭제(숨기기) ─────────────────────────────
function initStaticTrashRow(tr, hiddenKey) {
  var lastTd = tr.cells[tr.cells.length - 1];
  if (!lastTd || lastTd.querySelector('.remove-btn')) return;
  var btn = document.createElement('button');
  btn.className = 'remove-btn'; btn.title = '숨기기'; btn.textContent = '🗑';
  btn.addEventListener('click', function() {
    var code = tr.dataset.code;
    var h = JSON.parse(localStorage.getItem(hiddenKey) || '[]');
    if (h.indexOf(code) === -1) h.push(code);
    localStorage.setItem(hiddenKey, JSON.stringify(h));
    tr.style.display = 'none';
  });
  lastTd.appendChild(btn);
}

function initStaticTrash(tableId, hiddenKey) {
  var tbody = document.querySelector('#' + tableId + ' tbody');
  if (!tbody) return;
  var hidden = JSON.parse(localStorage.getItem(hiddenKey) || '[]');
  tbody.querySelectorAll('tr[data-code]:not([data-dynamic])').forEach(function(tr) {
    if (hidden.indexOf(tr.dataset.code) !== -1) { tr.style.display = 'none'; return; }
    initStaticTrashRow(tr, hiddenKey);
  });
}

// ── GitHub 저장 종목 → localStorage 병합 (setupWatchSearch 전 실행) ──
(function() {
  var cats = {
    kr_port:   { lk: 'kr_port_dynamic_v1',  hk: 'kr_port_hidden_v1'  },
    kr_watch:  { lk: 'kr_watchlist_v2',      hk: 'kr_watch_hidden_v1' },
    etf_port:  { lk: 'etf_port_dynamic_v1', hk: 'etf_port_hidden_v1' },
    etf_watch: { lk: 'etf_watchlist_v1',    hk: null                  },
    us_port:   { lk: 'us_port_dynamic_v1',  hk: 'us_port_hidden_v1'  },
    us_watch:  { lk: 'us_watchlist_v1',     hk: null                  }
  };
  if (WATCHLIST && typeof WATCHLIST === 'object') {
    Object.keys(cats).forEach(function(cat) {
      var wl = WATCHLIST[cat] || [];
      if (!wl.length) return;
      var c = cats[cat];
      var cur    = JSON.parse(localStorage.getItem(c.lk) || '[]');
      var hidden = c.hk ? JSON.parse(localStorage.getItem(c.hk) || '[]') : [];
      var codes  = cur.map(function(s) { return s.code; });
      var changed = false;
      wl.forEach(function(s) {
        if (codes.indexOf(s.code) === -1 && hidden.indexOf(s.code) === -1) {
          cur.push(s); changed = true;
        }
      });
      if (changed) localStorage.setItem(c.lk, JSON.stringify(cur));
    });
  }

  // GitHub 저장 버튼 — 새 탭(http)으로 열어 HTTPS→HTTP CORS 우회
  var btn = document.getElementById('github-save-btn');
  if (!btn) return;
  btn.addEventListener('click', function() {
    var data = {
      kr_port:   JSON.parse(localStorage.getItem('kr_port_dynamic_v1')  || '[]'),
      kr_watch:  JSON.parse(localStorage.getItem('kr_watchlist_v2')      || '[]'),
      etf_port:  JSON.parse(localStorage.getItem('etf_port_dynamic_v1') || '[]'),
      etf_watch: JSON.parse(localStorage.getItem('etf_watchlist_v1')    || '[]'),
      us_port:   JSON.parse(localStorage.getItem('us_port_dynamic_v1')  || '[]'),
      us_watch:  JSON.parse(localStorage.getItem('us_watchlist_v1')     || '[]')
    };
    var encoded = btoa(unescape(encodeURIComponent(JSON.stringify(data))));
    window.open('http://localhost:9001/save#' + encoded, '_blank');
  });
})();

setupWatchSearch({type:'kr',  inputId:'kr-search-input',  dropdownId:'kr-search-dropdown',  tableId:'kr-watch-table',  emptyRowId:'kr-watch-empty',  storageKey:'kr_watchlist_v2',  cols:10});
setupWatchSearch({type:'etf', inputId:'etf-search-input', dropdownId:'etf-search-dropdown', tableId:'etf-watch-table', emptyRowId:'etf-watch-empty', storageKey:'etf_watchlist_v1', cols:5});
setupWatchSearch({type:'us',  inputId:'us-search-input',  dropdownId:'us-search-dropdown',  tableId:'us-watch-table',  emptyRowId:'us-watch-empty',  storageKey:'us_watchlist_v1',  cols:8});

setupWatchSearch({type:'kr',  inputId:'kr-port-search-input',  dropdownId:'kr-port-search-dropdown',  tableId:'kr-port-table',  storageKey:'kr_port_dynamic_v1',  hiddenKey:'kr_port_hidden_v1',  cols:10});
setupWatchSearch({type:'etf', inputId:'etf-port-search-input', dropdownId:'etf-port-search-dropdown', tableId:'etf-port-table', storageKey:'etf_port_dynamic_v1', hiddenKey:'etf_port_hidden_v1', cols:5});
setupWatchSearch({type:'us',  inputId:'us-port-search-input',  dropdownId:'us-port-search-dropdown',  tableId:'us-port-table',  emptyRowId:'us-port-empty',       storageKey:'us_port_dynamic_v1',  hiddenKey:'us_port_hidden_v1',  cols:8});

initStaticTrash('kr-port-table',  'kr_port_hidden_v1');
initStaticTrash('etf-port-table', 'etf_port_hidden_v1');
initStaticTrash('us-port-table',  'us_port_hidden_v1');
initStaticTrash('kr-watch-table', 'kr_watch_hidden_v1');
initStaticTrash('us-watch-table', 'us_watch_hidden_v1');
</script>
