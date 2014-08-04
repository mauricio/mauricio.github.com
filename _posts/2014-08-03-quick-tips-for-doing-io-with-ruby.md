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

It's a bit hidden since it isn't part of the main [Dir](http://ruby-doc.org/stdlib-2.1.2/libdoc/tmpdir/rdoc/Dir.html) documentation, but it's there, you can create temporary directories and leave the standard library delete them and it's contents for you by using `Dir.mktmpdir`:

{% highlight ruby %}
require 'tmpdir'

Dir.mktempdir("my-prefix") do |dir|
  File.open("text.txt", 'w') { |f| f.write("this is a test") }
end
{% endhighlight %}

Also, always set at least a prefix for your temp folders to make sure you can spot them if they aren't deleted or if your app crashes and doesn't remove them for some reason, at least you'll know which code failed to execute.

This also includes the `Dir.tmpdir` method that gives you the path to your operating system's temp directory.

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

### Tempfiles and StringIO

Just like we have temp directories, we also have two classes that can be used as temporary file objects, [Tempfile](http://www.ruby-doc.org/stdlib-2.1.2/libdoc/tempfile/rdoc/Tempfile.html) and [StringIO](http://ruby-doc.org/stdlib-2.1.2/libdoc/stringio/rdoc/StringIO.html). Deciding two use one or the other is rather simple, if your data fits in memory and you don't care very much about paths, just being able to read and write to an `IO` like object, `StringIO` is for you, if you need path-like behavior or if your data doesn't fit in memory, `Tempfile` should be the option.

Since they both are `IO-like` objects you can read and write to them and send them whenever the code expects to receive an `IO` object. The advantage is that both objects will be cleaned up by the environment once they are garbage collected (but you better play save and `unlink` tempfiles to avoid having too many file handles open).

In general, prefer `StringIO` and when you really have to use `Tempfile` assume it's just like any other file and make sure you `close` and `unlink` the file as soon as you're done with it.

### Use `File.join` instead of manual string concatenation

While the [File.join documentation](http://www.ruby-doc.org/core-2.1.2/File.html#method-c-join) declares the method as simply __appending File::SEPARATOR__ for every item given, the [actual implementation](https://github.com/ruby/ruby/blob/aa3b5062707b72189b42a912dc6df58ab3bb68f8/file.c#L4223-L4297) does much more than just that and your simple `Array.join` call won't be the same as what's being done there, whenever you need to build an actual path, remember to always use `File.join`:

{% highlight ruby %}
path = Path.join("Users", "mauricio", "projects", "ruby")
{% endhighlight %}

### Accessing files relative to the current Ruby file

A common problem we see in Ruby code, specially when you're building gems or writing tests is that you have to load a file that's somewhere at your project path, but you obviously can't set a full path for it as you want it to be usable out of your own machine, so you need a relative path for it. A very simple way to do this is to use the `__FILE__` special variable.

Let's look at an example file system structure:

    - root
      - lib
        - my_gem
          - operation.rb
      - config
        - items.yml

So, if you're at `operation.rb`, you can access `items.yml` with:

{% highlight ruby %}
my_gem_directory = File.dir(__FILE__)
File.join(my_gem_directory, "..", "..", "config", "items.yml")
{% endhighlight %}

This is basically saying:

* Give me the directory where `operation.rb` is;
* Go up a directory (the `..`);
* Go up another directory;
* Now that you're at `root`, give me the file `config/items.yml`;

So you can use the `__FILE__` variable as the relative path to load files you know are available at your current file sytem.

### Avoid `File.open` without a block

One of the main advantages of using a language with closures is how simple it is to pass code around to be executed by someone else and a very common use case for this is resource management. While in some languages you have to write a huge amount of boileplate to safetly write to a file and not leak the file handle, in Ruby all you have to do is:

{% highlight ruby %}
File.open("some-file.txt", "w") do |f|
  f.write("this is some text\n")
  f.write("and some more text")
end
{% endhighlight %}

The code above will open the file for writing, execute the block setting the actual `File` object at the `f` variable and once the code is finished it will flush and close the file handle, making sure I don't have to care about this.

Whenever doing file operations, always use the **block style** for open, avoid doing stuff like:

{% highlight ruby %}
file = File.open("some-file.ext", "w")
file.write("hey, this is bad!")
file.write("where's the exception handling code?")
file.close
{% endhighlight %}

While this code might look correct, the lack of exception handling would make the file handle leak and the process running this code could eventually crash with the OS complaining it had too many files open.

We could include the exception handling code and make sure it behaves just like the `File.open` that takes a block, but why should we? We already have a correct and simpler solution available, don't reinvent the wheel, just use `File.open` with blocks and let the Ruby standard library do it's job.

### Prefer `Pathname` for file path and metadata operations

[Pathname](http://www.ruby-doc.org/stdlib-2.1.2/libdoc/pathname/rdoc/Pathname.html) functions as a nicer interface to Ruby's path operations and you're better off getting used to it from now on whenever you need to do stuff with file names as in:

Creating it:

{% highlight ruby %}
require 'pathname'
path = Pathname.new("README.markdown")  
{% endhighlight %}

Getting the file extension:

{% highlight ruby %}
puts path.extname
 => ".markdown"
{% endhighlight %}

Expanding the path:

{% highlight ruby %}
full_path = path.expand_path
 => #<Pathname:/Users/mauricio/projects/ruby/mauricio.github.com/README.markdown>
{% endhighlight %}

Getting the directory the file is in:

{% highlight ruby %}
puts full_path.dirname
 => #<Pathname:/Users/mauricio/projects/ruby/mauricio.github.com>
{% endhighlight %}

And what's really important here is that most of these operations will return a `Pathname` object instead of `String` so you can easily chain a sequence of calls all operating on file/directory metadata and they will all function as expected.

### `FileUtils` probably already has what you're looking for

If what you're trying to do something that's not available at `Pathname`, `File` and `Dir`, what you're looking for is probably defined at [FileUtils](http://ruby-doc.org/stdlib-2.1.2/libdoc/fileutils/rdoc/FileUtils.html).

Many of the operations you'd usually have to manually dive down into a tree of files and directories (like `chowning` a directory and it's children) are already defined as single method calls at `FileUtils` and you should just go there, find the method and call it instead of manually writing code to recurse over the trees and calling methods.
