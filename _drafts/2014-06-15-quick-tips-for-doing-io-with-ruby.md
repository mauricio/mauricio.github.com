---
layout: post
title: Quick tips for doing IO with Ruby
subtitle: all fun and games
keywords: ruby, file_utils, filesystem, files, io
tags:
- ruby
- useful
---

Since I always have to go back to the docs to check on most of this stuff, it might just be better to keep it all indexed here so I can just open this blog post instead of going hunting this all again.

And, guess what, this could even be helpful for other people as well, right?

### Temporary directories

You might have heard about [Tempfile](http://www.ruby-doc.org/stdlib-2.1.2/libdoc/tempfile/rdoc/Tempfile.html), but did you know you can create temporary [directories](http://ruby-doc.org/stdlib-2.1.2/libdoc/tmpdir/rdoc/Dir.html) in Ruby and it's built in into the standard library?

It's a bit hidden since it isn't part of the main [Dir](http://www.ruby-doc.org/core-2.1.2/Dir.html) documentation, but it's there, you can create temporary directories and leave the standard library delete them and it's contents for you by using `Dir.mktmpdir`:

{% highlight ruby %}
Dir.mktempdir("my-prefix") do |dir|
  File.open("text.txt", 'w') { |f| f.write("this is a test") }
end
{% endhighlight %}

Also, always set at least a prefix for your temp folders to make sure you can spot them if they aren't deleted or if your app crashes and doesn't remove them for some reason, at least you'll know which code failed to execute.

### Handling files that fit in memory? Use IO directly

If all you want is write some text to a file, Don't use `File`, use `IO` directly:

{% highlight ruby %}
IO.write("/path/to/file.txt", "This is my cool text I need to write! Yay!")
{% endhighlight %}

This opens the file at `/path/to/file.txt`, writes the text to it and closes the file. Can't get much simpler than this.

And just as simple is reading a file:

{% highlight ruby %}
contents = IO.read("/path/to/file.txt")
{% endhighlight %}

This reads the file contents and returns it.

### Tempfiles

Just like we have temporary directories, we also have temporary files from [Tempfile](http://www.ruby-doc.org/stdlib-2.1.2/libdoc/tempfile/rdoc/Tempfile.html). We can use it for
