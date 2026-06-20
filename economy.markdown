---
layout: page
title: 경제 지표
permalink: /economy/
---

<style>
.eco-table { width: 100%; border-collapse: collapse; font-size: 0.95em; margin-bottom: 2em; }
.eco-table th { background: #f0f0f0; padding: 8px 12px; text-align: right; border-bottom: 2px solid #ddd; }
.eco-table th:first-child { text-align: left; }
.eco-table td { padding: 7px 12px; border-bottom: 1px solid #eee; text-align: right; }
.eco-table td:first-child { text-align: left; font-weight: bold; }
.rising  { color: #e74c3c; }
.falling { color: #3498db; }
.even    { color: #888; }
.section-title { font-size: 1.1em; font-weight: bold; margin: 1.5em 0 0.5em; color: #333; border-left: 4px solid #2a7ae2; padding-left: 10px; }
.meta { color: #999; font-size: 0.85em; margin-bottom: 1.2em; }
</style>

{% if site.data.economy %}
<p class="meta">마지막 업데이트: {{ site.data.economy.fetched_at }} · 매 시간 자동 갱신</p>

<p class="section-title">🇰🇷 국내 지수</p>
<table class="eco-table">
<thead><tr><th>지수</th><th>현재가</th><th>전일비</th><th>등락률</th></tr></thead>
<tbody>
{% for item in site.data.economy.kr_indices %}
{% assign cls = "even" %}{% assign arrow = "—" %}
{% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
{% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}{% endif %}
<tr>
  <td>{{ item.name }}</td>
  <td>{{ item.price }}</td>
  <td class="{{ cls }}">{{ arrow }} {{ item.change | remove: "-" }}</td>
  <td class="{{ cls }}">{{ item.change_pct }}%</td>
</tr>
{% endfor %}
</tbody>
</table>

<p class="section-title">🌐 해외 지수</p>
<table class="eco-table">
<thead><tr><th>지수</th><th>현재가</th><th>전일비</th><th>등락률</th></tr></thead>
<tbody>
{% for item in site.data.economy.us_indices %}
{% assign cls = "even" %}{% assign arrow = "—" %}
{% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
{% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}{% endif %}
<tr>
  <td>{{ item.name }}</td>
  <td>{{ item.price }}</td>
  <td class="{{ cls }}">{{ arrow }} {{ item.change | remove: "-" }}</td>
  <td class="{{ cls }}">{{ item.change_pct }}%</td>
</tr>
{% endfor %}
</tbody>
</table>

<p class="section-title">💱 주요 환율</p>
<table class="eco-table">
<thead><tr><th>통화쌍</th><th>환율 (원)</th><th>전일비</th><th>등락률</th></tr></thead>
<tbody>
{% for item in site.data.economy.fx_rates %}
{% assign cls = "even" %}{% assign arrow = "—" %}
{% if item.direction == "RISING" %}{% assign cls = "rising" %}{% assign arrow = "▲" %}
{% elsif item.direction == "FALLING" %}{% assign cls = "falling" %}{% assign arrow = "▼" %}{% endif %}
<tr>
  <td>{{ item.name }}</td>
  <td>{{ item.price }}</td>
  <td class="{{ cls }}">{{ arrow }} {{ item.change | remove: "-" }}</td>
  <td class="{{ cls }}">{{ item.change_pct }}%</td>
</tr>
{% endfor %}
</tbody>
</table>

{% else %}
<p>데이터가 없습니다. <code>ruby economy_scraper.rb</code>를 실행해주세요.</p>
{% endif %}
