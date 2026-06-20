---
layout: page
title: 내 주식
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

/* ── 표 영역 ──────────────────────────────────────── */
.section-title {
  font-size: 1em;
  font-weight: bold;
  margin: 1.4em 0 0.5em;
  color: #333;
  border-left: 3px solid #555;
  padding-left: 0.6em;
}
.stock-table { width: 100%; border-collapse: collapse; font-size: 0.86em; margin-bottom: 2em; }
.stock-table th { background: #f0f0f0; padding: 7px 9px; text-align: right; border-bottom: 2px solid #ddd; white-space: nowrap; }
.stock-table th:first-child, .stock-table th.left { text-align: left; }
.stock-table td { padding: 6px 9px; border-bottom: 1px solid #eee; text-align: right; vertical-align: top; white-space: nowrap; }
.stock-table td:first-child { text-align: left; font-weight: bold; }
.disclosure-cell { white-space: normal; }

/* ── 색상 ────────────────────────────────────────── */
.rising  { color: #e74c3c; }
.falling { color: #3498db; }
.even    { color: #888; }
.na      { color: #ccc; }

/* ── 공시 셀 ─────────────────────────────────────── */
.disclosure-cell  { text-align: left !important; max-width: 280px; word-break: break-all; overflow-wrap: break-word; }
.disclosure-title { display: block; }
.disclosure-title a { word-break: break-all; }
.disclosure-meta  { color: #999; font-size: 0.82em; word-break: break-all; }
.target-count     { color: #999; font-size: 0.82em; }

/* ── ETF 구성 종목 셀 ────────────────────────────── */
.holdings-cell { text-align: left !important; }
.holdings-list { margin: 0; padding: 0; list-style: none; }
.holdings-list li { font-size: 0.84em; line-height: 1.65; white-space: nowrap; }
.holdings-ratio { color: #999; margin-left: 0.4em; }

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
.opinion-name {
  font-weight: bold;
  font-size: 0.95em;
  color: #222;
  margin-bottom: 0.4em;
}
.opinion-text { color: #444; line-height: 1.55; }
.opinion-pending {
  color: #bbb;
  font-style: italic;
  font-size: 0.82em;
}

/* ── 메타 ─────────────────────────────────────────── */
.meta { color: #999; font-size: 0.84em; margin-bottom: 1em; }

/* ── 모바일 반응형 ───────────────────────────────── */
@media (max-width: 768px) {
  /* page-outer 100vw 트릭 해제 */
  .page-outer {
    width: 100%;
    position: static;
    left: auto;
    transform: none;
    padding: 0;
  }

  /* 1열 레이아웃으로 전환 */
  .page-grid {
    grid-template-columns: 1fr;
  }

  /* 사이드바 숨김 */
  .ai-sidebar {
    display: none;
  }

  /* 테이블 가로 스크롤 */
  .tables-col {
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
  }
  .stock-table {
    min-width: 520px;
    font-size: 0.78em;
  }
  .stock-table th,
  .stock-table td {
    padding: 5px 7px;
  }
  .disclosure-cell {
    max-width: 180px;
  }
}
</style>

{% if site.data.mystocks and site.data.mystocks.stocks.size > 0 %}
<p class="meta">마지막 업데이트: {{ site.data.mystocks.fetched_at }} · 매 시간 자동 갱신</p>

{% assign individual = site.data.mystocks.stocks | where: "category", "stock" %}
{% assign etfs       = site.data.mystocks.stocks | where: "category", "etf" %}

<div class="page-outer">
<div class="page-grid">

<!-- ── 좌측: 표 영역 ──────────────────────────────── -->
<div class="tables-col">

<p class="section-title">개별 주식</p>
<table class="stock-table">
<thead>
  <tr>
    <th>종목</th>
    <th>현재가</th>
    <th>전일비</th>
    <th>등락률</th>
    <th>PER</th>
    <th>목표가 평균</th>
    <th class="left">최근 공시</th>
  </tr>
</thead>
<tbody>
{% for item in individual %}
{% assign cls = "even" %}{% assign arrow = "—" %}
{% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
{% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}{% endif %}
<tr>
  <td><a href="https://m.stock.naver.com/domestic/stock/{{ item.code }}" target="_blank">{{ item.name }}</a></td>
  <td>{{ item.price }}</td>
  <td class="{{ cls }}">{{ arrow }} {{ item.change | remove: "-" }}</td>
  <td class="{{ cls }}">{{ item.change_pct }}%</td>
  <td>{% if item.per %}{{ item.per }}배{% else %}<span class="na">—</span>{% endif %}</td>
  <td>
    {% if item.analyst_target %}
      {{ item.analyst_target.avg_formatted }}
      <span class="target-count">({{ item.analyst_target.count }}건)</span>
    {% else %}<span class="na">—</span>{% endif %}
  </td>
  <td class="disclosure-cell">
    {% if item.disclosure %}
      <span class="disclosure-title">
        <a href="{{ item.disclosure.url }}" target="_blank">{{ item.disclosure.title | truncate: 38 }}</a>
      </span>
      <span class="disclosure-meta">{{ item.disclosure.datetime }} · {{ item.disclosure.author }}</span>
    {% else %}<span class="na">—</span>{% endif %}
  </td>
</tr>
{% endfor %}
</tbody>
</table>

<p class="section-title">ETF / ETN</p>
<table class="stock-table">
<thead>
  <tr>
    <th>종목</th>
    <th>현재가</th>
    <th>전일비</th>
    <th>등락률</th>
    <th class="left">구성 종목 TOP5</th>
  </tr>
</thead>
<tbody>
{% for item in etfs %}
{% assign cls = "even" %}{% assign arrow = "—" %}
{% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
{% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}{% endif %}
<tr>
  <td><a href="https://m.stock.naver.com/domestic/stock/{{ item.code }}" target="_blank">{{ item.name }}</a></td>
  <td>{{ item.price }}</td>
  <td class="{{ cls }}">{{ arrow }} {{ item.change | remove: "-" }}</td>
  <td class="{{ cls }}">{{ item.change_pct }}%</td>
  <td class="holdings-cell">
    {% if item.holdings %}
      <ul class="holdings-list">
      {% for h in item.holdings %}
        <li>{{ h.name }}<span class="holdings-ratio">{{ h.ratio }}</span></li>
      {% endfor %}
      </ul>
    {% else %}<span class="na">—</span>{% endif %}
  </td>
</tr>
{% endfor %}
</tbody>
</table>

</div><!-- .tables-col -->

<!-- ── 우측: AI 사이드바 ──────────────────────────── -->
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
