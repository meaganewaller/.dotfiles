---
layout: page
title: Glossary
permalink: /glossary/
---

Canonical definitions of terms used throughout this site.

{% assign sorted_glossary = site.glossary | sort: "term" %}
{% assign categories = sorted_glossary | map: "category" | uniq | sort %}

<div class="flex flex-wrap gap-2 mb-8">
  <button onclick="filterCards('all')" class="filter-btn px-3 py-1 text-xs bg-lime-400 text-lime-700 rounded-full" data-filter="all">All</button>
{% for cat in categories %}
  <button onclick="filterCards('{{ cat }}')" class="filter-btn px-3 py-1 text-xs bg-stone-200 text-stone-600 rounded-full hover:bg-stone-300" data-filter="{{ cat }}">{{ cat }}</button>
{% endfor %}
</div>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
{% for item in sorted_glossary %}
  <a href="{{ item.url | relative_url }}"
     class="glossary-card block p-4 bg-white rounded-lg hover:shadow-md transition-all group"
     data-category="{{ item.category }}">
    <div class="flex items-start justify-between mb-2">
      <h3 class="font-semibold text-stone-800  group-hover:text-blue-600">
        {{ item.term }}
      </h3>
      <span class="text-xs px-2 py-0.5 bg-stone-100 text-stone-500 rounded">
        {{ item.category }}
      </span>
    </div>
    <p class="text-sm text-stone-500 mb-3">
      {{ item.short }}
    </p>
    {% if item.related %}
    <div class="flex flex-wrap gap-1">
      {% for rel in item.related limit:3 %}
      <span class="text-xs text-stone-400">{{ rel | replace: "-", " " }}{% unless forloop.last %},{% endunless %}</span>
      {% endfor %}
      {% if item.related.size > 3 %}
      <span class="text-xs text-stone-400">+{{ item.related.size | minus: 3 }} more</span>
      {% endif %}
    </div>
    {% endif %}
  </a>
{% endfor %}
</div>

<script>
function filterCards(category) {
  const cards = document.querySelectorAll('.glossary-card');
  const buttons = document.querySelectorAll('.filter-btn');

  buttons.forEach(btn => {
    if (btn.dataset.filter === category) {
      btn.classList.remove('bg-stone-200', 'text-stone-600');
      btn.classList.add('bg-lime-400', 'text-lime-700');
    } else {
      btn.classList.add('bg-stone-200','text-stone-600');
      btn.classList.remove('bg-lime-400', 'text-lime-700');
    }
  });

  cards.forEach(card => {
    if (category === 'all' || card.dataset.category === category) {
      card.style.display = 'block';
    } else {
      card.style.display = 'none';
    }
  });
}
</script>
