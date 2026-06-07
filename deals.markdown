---
layout: page
title: 태블릿 핫딜 모음
permalink: /deals/
---

FMKorea 핫딜 게시판에서 **태블릿** 관련 글을 자동으로 수집합니다.

{% if site.data.deals and site.data.deals.size > 0 %}
<ul>
{% for deal in site.data.deals %}
  <li>
    <a href="{{ deal.url }}" target="_blank">{{ deal.title }}</a>
    <small style="color:gray;"> — {{ deal.found_at }}</small>
  </li>
{% endfor %}
</ul>
{% else %}
<p>아직 수집된 글이 없습니다. scraper.rb를 실행해주세요.</p>
{% endif %}
