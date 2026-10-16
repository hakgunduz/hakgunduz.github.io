---
title: Stories
permalink: /stories/
layout: default
---
<h1 class="list-title">Stories</h1>
{% assign docs = site.stories | sort: 'date' | reverse %}
{% include entry-list.html docs=docs %}
