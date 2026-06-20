---
layout: page
title: 주식 현황
permalink: /stocks/
---

<style>
.stock-table { width: 100%; border-collapse: collapse; font-size: 0.95em; }
.stock-table th { background: #f0f0f0; padding: 8px 12px; text-align: right; border-bottom: 2px solid #ddd; }
.stock-table th:first-child { text-align: left; }
.stock-table td { padding: 7px 12px; border-bottom: 1px solid #eee; text-align: right; }
.stock-table td:first-child { text-align: left; font-weight: bold; }
.rising  { color: #e74c3c; }
.falling { color: #3498db; }
.even    { color: #888; }
.index-row { background: #fafafa; font-weight: bold; }
.meta { color: #999; font-size: 0.85em; margin-bottom: 12px; }
</style>

{% if site.data.stocks %}
<p class="meta">마지막 업데이트: {{ site.data.stocks.fetched_at }} (매 시간 자동 갱신)</p>

<table class="stock-table">
<thead>
  <tr>
    <th>종목</th>
    <th>현재가</th>
    <th>전일비</th>
    <th>등락률</th>
    <th>시장</th>
  </tr>
</thead>
<tbody>

{% for item in site.data.stocks.indices %}
{% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
{% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}
{% else %}{% assign cls = "even" %}{% assign arrow = "-" %}{% endif %}
<tr class="index-row">
  <td>{{ item.name }}</td>
  <td>{{ item.price }}</td>
  <td class="{{ cls }}">{{ arrow }} {{ item.change | remove: "-" }}</td>
  <td class="{{ cls }}">{{ item.change_pct }}%</td>
  <td>지수</td>
</tr>
{% endfor %}

{% for item in site.data.stocks.stocks %}
{% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
{% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}
{% else %}{% assign cls = "even" %}{% assign arrow = "-" %}{% endif %}
<tr>
  <td><a href="https://m.stock.naver.com/domestic/stock/{{ item.code }}" target="_blank">{{ item.name }}</a></td>
  <td>{{ item.price }}</td>
  <td class="{{ cls }}">{{ arrow }} {{ item.change | remove: "-" }}</td>
  <td class="{{ cls }}">{{ item.change_pct }}%</td>
  <td>{{ item.market }}</td>
</tr>
{% endfor %}

</tbody>
</table>

{% else %}
<p>데이터가 없습니다. <code>ruby stock_scraper.rb</code>를 실행해주세요.</p>
{% endif %}
