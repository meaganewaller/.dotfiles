---
layout: page
title: Tags
permalink: /tags/
---

Browse all posts by tag.

{% for tag in site.tags %}
## {{ tag[0] }}
{: id="{{ tag[0] | slugify }}"}

<ul class="list-none pl-0">
{% for post in tag[1] %}
  <li class="mb-2">
    <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
    <span class="text-stone-400 text-xs ml-2">{{ post.date | date: "%b %d, %Y" }}</span>
  </li>
{% endfor %}
</ul>
{% endfor %}

{% if site.tags.size == 0 %}
*No tags yet.*
{% endif %}
