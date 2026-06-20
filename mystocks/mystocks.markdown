---
layout: page
title: 내 주식
permalink: /mystocks/
---

<style>
.stock-table { width: 100%; border-collapse: collapse; font-size: 0.88em; }
.stock-table th { background: #f0f0f0; padding: 7px 10px; text-align: right; border-bottom: 2px solid #ddd; white-space: nowrap; }
.stock-table th:first-child, .stock-table th.left { text-align: left; }
.stock-table td { padding: 6px 10px; border-bottom: 1px solid #eee; text-align: right; vertical-align: top; }
.stock-table td:first-child { text-align: left; font-weight: bold; white-space: nowrap; }
.rising  { color: #e74c3c; }
.falling { color: #3498db; }
.even    { color: #888; }
.disclosure-cell { text-align: left !important; max-width: 260px; }
.disclosure-title { display: block; }
.disclosure-meta  { color: #999; font-size: 0.82em; }
.target-count { color: #999; font-size: 0.82em; }
.na { color: #bbb; }
.meta { color: #999; font-size: 0.85em; margin-bottom: 1em; }
</style>

{% if site.data.mystocks and site.data.mystocks.stocks.size > 0 %}
<p class="meta">마지막 업데이트: {{ site.data.mystocks.fetched_at }} · 매 시간 자동 갱신</p>

<table class="stock-table">
<thead>
  <tr>
    <th>종목</th>
    <th>현재가</th>
    <th>전일비</th>
    <th>등락률</th>
    <th>PER</th>
    <th class="left">최근 공시</th>
    <th>목표가 평균</th>
  </tr>
</thead>
<tbody>
{% for item in site.data.mystocks.stocks %}
{% assign cls = "even" %}{% assign arrow = "—" %}
{% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
{% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}{% endif %}
<tr>
  <td><a href="https://m.stock.naver.com/domestic/stock/{{ item.code }}" target="_blank">{{ item.name }}</a></td>
  <td>{{ item.price }}</td>
  <td class="{{ cls }}">{{ arrow }} {{ item.change | remove: "-" }}</td>
  <td class="{{ cls }}">{{ item.change_pct }}%</td>
  <td>
    {% if item.per %}{{ item.per }}배{% else %}<span class="na">—</span>{% endif %}
  </td>
  <td class="disclosure-cell">
    {% if item.disclosure %}
      <span class="disclosure-title">{{ item.disclosure.title | truncate: 40 }}</span>
      <span class="disclosure-meta">{{ item.disclosure.datetime }} · {{ item.disclosure.author }}</span>
    {% else %}<span class="na">—</span>{% endif %}
  </td>
  <td>
    {% if item.analyst_target %}
      {{ item.analyst_target.avg_formatted }}
      <span class="target-count">({{ item.analyst_target.count }}건)</span>
    {% else %}<span class="na">—</span>{% endif %}
  </td>
</tr>
{% endfor %}
</tbody>
</table>

{% else %}
<p>데이터가 없습니다. <code>ruby mystocks/mystocks_scraper.rb</code>를 실행해주세요.</p>
{% endif %}
