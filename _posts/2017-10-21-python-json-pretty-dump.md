---
layout: post
title: Python outputting json.dump like json.tool
category: engineering
tags:
 - python
 - tips
year: 2017
month: 10
day: 21
published: true
type: markdown
---

Sometimes, it is desirable in Python command line utilities to export JSON
pretty printed similar to `python -m json.tool`.  Typically, one could pretty
print any arbitrary JSON using the [Python module `json.tool`][json].

{% highlight bash %}
python -m json.tool < compact.json > pretty.json
{% endhighlight %}

If writing a CLI utility which exports JSON via `json.dump`, then it may be
useful to offer users a `--pretty-json` option.  To replicate `json.dumps` like
`json.tool` the following can be printed to stdout.

{% highlight python %}
import json

with open('path/to/compact.json') as f:
    json_object = json.load(f)

print json.dumps(json_object, indent=4, separators=(',', ': '), sort_keys=True)
{% endhighlight %}

To write to a file using `json.dump` like `json.tool`:

{% highlight python %}
import json

with open('compact.json') as f:
    json_object = json.load(f)

with open('pretty.json', 'w') as f:
    json.dump(json_object, f, indent=4, separators=(',', ': '), sort_keys=True)
    #add trailing newline for POSIX compatibility
    f.write('\n')
{% endhighlight %}

[json]: https://docs.python.org/2/library/json.html
