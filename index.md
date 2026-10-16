---
layout: default
---
<p class="lede">I write notes on what I'm learning and short stories when I can't help it. This is where they live.</p>

{% assign everything = site.notes | concat: site.stories | sort: 'date' | reverse %}
<h2 class="section-title">Recent</h2>
{% include entry-list.html docs=everything show_kind=true %}
