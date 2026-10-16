---
layout: default
---
<section class="intro">
  <p><em>Notes and short stories.</em> I write down what I'm learning, and sometimes what I can't help imagining. This is where both live.</p>
</section>

{% assign notes = site.notes | sort: 'date' | reverse %}
{% assign stories = site.stories | sort: 'date' | reverse %}
<div class="index">
  <section>
    <h2 class="label">Notes</h2>
    {% include entry-list.html docs=notes limit=4 %}
    <a class="all" href="{{ '/notes/' | relative_url }}">All notes →</a>
  </section>
  <section>
    <h2 class="label">Stories</h2>
    {% include entry-list.html docs=stories limit=4 %}
    <a class="all" href="{{ '/stories/' | relative_url }}">All stories →</a>
  </section>
</div>
