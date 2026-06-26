---
layout: page
title: 🔥 핫딜
permalink: /hotdeal/
---

<style>
.meta { color: #999; font-size: 0.85em; margin-bottom: 1.2em; }
.hotdeal-list { display: flex; flex-direction: column; gap: 0; }
.hotdeal-item { display: flex; align-items: baseline; gap: 10px; padding: 10px 4px; border-bottom: 1px solid #f0f0f0; }
.hotdeal-item:last-child { border-bottom: none; }
.hotdeal-cat  { font-size: 0.75em; background: #f0f4ff; color: #2a7ae2; border-radius: 4px; padding: 2px 7px; white-space: nowrap; flex-shrink: 0; }
.hotdeal-title { flex: 1; font-size: 0.93em; color: #222; text-decoration: none; line-height: 1.45; }
.hotdeal-title:hover { text-decoration: underline; color: #2a7ae2; }
.hotdeal-vote { font-size: 0.82em; color: #888; white-space: nowrap; flex-shrink: 0; }
.hotdeal-empty { color: #aaa; font-size: 0.9em; padding: 2em 0; }
</style>

<p class="meta" id="hotdeal-meta">로딩 중...</p>
<div id="hotdeal-list" class="hotdeal-list"></div>

<script>
(function() {
  var REPO_RAW = 'https://raw.githubusercontent.com/mhyang-dev/MegaCrawller/master';
  var listEl = document.getElementById('hotdeal-list');
  var metaEl = document.getElementById('hotdeal-meta');
  fetch(REPO_RAW + '/data/hotdeal.json?v=' + Math.floor(Date.now() / 60000))
    .then(function(r) { return r.json(); })
    .then(function(data) {
      if (metaEl && data.updated_at) {
        metaEl.textContent = '추천 10개 이상 · fmkorea 핫딜 · ' + data.updated_at.replace('T',' ').slice(0,16);
      }
      var items = data.items || [];
      if (!items.length) {
        listEl.innerHTML = '<p class="hotdeal-empty">해당 조건의 핫딜이 없습니다.</p>';
        return;
      }
      listEl.innerHTML = items.map(function(d) {
        var cat  = d.category ? '<span class="hotdeal-cat">' + d.category + '</span>' : '';
        var vote = '<span class="hotdeal-vote">👍 ' + d.vote + '</span>';
        return '<div class="hotdeal-item">' + cat +
          '<a class="hotdeal-title" href="' + d.link + '" target="_blank" rel="noopener">' + d.title + '</a>' +
          vote + '</div>';
      }).join('');
    })
    .catch(function() {
      listEl.innerHTML = '<p class="hotdeal-empty">데이터 없음 — 데이터 업데이트가 필요합니다.</p>';
    });
})();
</script>
