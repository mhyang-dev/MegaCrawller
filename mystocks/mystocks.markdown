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
  text-align: right;
  border-bottom: 2px solid #ddd;
  white-space: nowrap;
}
.stock-table th:first-child,
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
  min-width: 130px;
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
.disclosure-title { display: block; }
.disclosure-title a { word-break: break-all; }
.disclosure-meta { color: #999; font-size: 0.82em; }

/* ── ETF 구성 종목 셀 ────────────────────────────── */
.holdings-cell { text-align: left !important; }
.holdings-list { margin: 0; padding: 0; list-style: none; }
.holdings-list li { font-size: 0.84em; line-height: 1.65; white-space: nowrap; }
.holdings-ratio { color: #999; margin-left: 0.4em; }

/* ── 테이블 주석 ─────────────────────────────────── */
.table-note {
  color: #aaa;
  font-size: 0.78em;
  margin: 0 0 2em;
  line-height: 1.7;
}

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
<div class="table-scroll">
<table class="stock-table" id="stock-table">
<thead>
  <tr>
    <th class="left" data-col="fics">업종 <span class="sort-icon">⇅</span></th>
    <th data-col="name">종목 <span class="sort-icon">⇅</span></th>
    <th data-col="cap">시총 <span class="sort-icon">⇅</span></th>
    <th data-col="price">현재가 <span class="sort-icon">⇅</span></th>
    <th data-col="change">전일비 / 등락률 <span class="sort-icon">⇅</span></th>
    <th data-col="per">PER (업종 PER) <span class="sort-icon">⇅</span></th>
    <th data-col="target">목표가 / 대비 <span class="sort-icon">⇅</span></th>
    <th class="left">매수 주체</th>
    <th class="left">최근 공시</th>
  </tr>
</thead>
<tbody>
{% for item in individual %}
{% assign cls = "even" %}{% assign arrow = "—" %}
{% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
{% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}{% endif %}
{% assign upside = item.upside_pct %}
{% if upside > 0 %}{% assign upside_cls = "rising" %}{% assign upside_sign = "+" %}
{% elsif upside < 0 %}{% assign upside_cls = "falling" %}{% assign upside_sign = "" %}
{% else %}{% assign upside_cls = "even" %}{% assign upside_sign = "" %}{% endif %}
<tr>
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
        {% assign indi_v = is.indi | default: 0 %}
        <div class="investor-item">
          <span class="investor-label">개인</span>
          {% if indi_v > 0 %}<span class="investor-buy">{{ indi_v }}</span>
          {% elsif indi_v < 0 %}<span class="investor-sell">{{ indi_v | abs }}</span>
          {% else %}<span class="investor-zero">—</span>{% endif %}
        </div>
        {% assign foreign_v = is.foreign | default: 0 %}
        <div class="investor-item">
          <span class="investor-label">외인</span>
          {% if foreign_v > 0 %}<span class="investor-buy">{{ foreign_v }}</span>
          {% elsif foreign_v < 0 %}<span class="investor-sell">{{ foreign_v | abs }}</span>
          {% else %}<span class="investor-zero">—</span>{% endif %}
        </div>
        {% assign gigan_v = is.gigan | default: 0 %}
        <div class="investor-item">
          <span class="investor-label">기관</span>
          {% if gigan_v > 0 %}<span class="investor-buy">{{ gigan_v }}</span>
          {% elsif gigan_v < 0 %}<span class="investor-sell">{{ gigan_v | abs }}</span>
          {% else %}<span class="investor-zero">—</span>{% endif %}
        </div>
      </div>
      {% if is.as_of %}<div class="investor-as-of">{{ is.as_of }} 기준</div>{% endif %}
    {% else %}<span class="na">—</span>{% endif %}
  </td>
  <td class="disclosure-cell">
    {% if item.disclosure %}
      <span class="disclosure-title"><a href="{{ item.disclosure.url }}" target="_blank">{{ item.disclosure.title | truncate: 38 }}</a></span>
      <span class="disclosure-meta">{{ item.disclosure.datetime }} · {{ item.disclosure.author }}</span>
    {% else %}<span class="na">—</span>{% endif %}
  </td>
</tr>
{% endfor %}
</tbody>
</table>
</div>
<p class="table-note">
  * 업종: FnGuide FICS(FnGuide Industry Classification Standard) 소분류<br>
  * PER: FnGuide FY1 컨센서스 — 증권사 평균 예상 EPS 기준 (시총 ÷ 추정 순이익)<br>
  * 목표가: FnGuide 컨센서스 목표주가 단순 평균 / 목표가 대비: (목표가 − 현재가) ÷ 현재가 × 100<br>
  * 매수 주체: 최근 일자 기준 연속 순매수(빨강)·순매도(파랑) 일수. 개인=-(외국인+기관) 추정치.
</p>

<p class="section-title">ETF / ETN</p>
<div class="table-scroll">
<table class="stock-table" id="etf-table">
<thead>
  <tr>
    <th data-col="name">종목 <span class="sort-icon">⇅</span></th>
    <th data-col="price">현재가 <span class="sort-icon">⇅</span></th>
    <th data-col="change">전일비 / 등락률 <span class="sort-icon">⇅</span></th>
    <th class="left">구성 종목 TOP5</th>
  </tr>
</thead>
<tbody>
{% for item in etfs %}
{% assign cls = "even" %}{% assign arrow = "—" %}
{% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
{% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}{% endif %}
<tr>
  <td data-sort="{{ item.name }}"><a href="https://m.stock.naver.com/domestic/stock/{{ item.code }}" target="_blank">{{ item.name }}</a></td>
  <td data-sort="{{ item.price | remove: ',' }}">{{ item.price }}</td>
  <td data-sort="{{ item.change_pct }}" class="{{ cls }}">{{ arrow }} {{ item.change | remove: "-" }} <span class="sub">({{ item.change_pct }}%)</span></td>
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
</div>

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

<script>
(function () {
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
      var rows = Array.from(tbody.querySelectorAll('tr'));
      rows.sort(function (a, b) {
        var ac = a.cells[ci], bc = b.cells[ci];
        var av = ac ? (ac.dataset.sort !== undefined ? ac.dataset.sort : ac.textContent.trim()) : '';
        var bv = bc ? (bc.dataset.sort !== undefined ? bc.dataset.sort : bc.textContent.trim()) : '';
        var an = parseFloat(av), bn = parseFloat(bv);
        if (!isNaN(an) && !isNaN(bn)) return asc ? an - bn : bn - an;
        return asc ? av.localeCompare(bv, 'ko') : bv.localeCompare(av, 'ko');
      });
      rows.forEach(function (r) { tbody.appendChild(r); });
    });
  });
})();
</script>
