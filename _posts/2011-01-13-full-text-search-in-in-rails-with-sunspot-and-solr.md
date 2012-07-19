---
layout: post
title: Full text search in in Rails with Sunspot and Solr
tags:
- databases
- en_US
- full text search
- rails
- ruby
- ruby on rails
- solr
- sunspot
status: publish
type: post
published: true
meta:
  dsq_thread_id: '217522666'
  _edit_last: '1'
  jabber_published: '1294959146'
  email_notification: '1294959148'
  reddit: s:55:"a:2:{s:5:"count";s:1:"0";s:4:"time";s:10:"1296010245";}";
  _su_title: Full text search in in Rails with Sunspot and Solr
  _su_rich_snippet_type: none
  _su_keywords: solr, sunspot, ruby, rails, active record, java, database, text search,
    like
  _su_description: Everyone wants to take their databases to run everything as fast
    as possible. We usually say query less, add more caching mechanisms, add indexes
    to the columns being searched, but another solution is not to use the database
    at all and look for better solutions for your querying needs.
  _efficient_related_posts: a:10:{i:0;a:4:{s:2:"ID";s:3:"352";s:10:"post_title";s:41:"Ruby
    Basics - Equality operators in Ruby ";s:7:"matches";s:1:"2";s:9:"permalink";s:62:"http://techbot.me/2011/05/ruby-basics-equality-operators-ruby/";}i:1;a:4:{s:2:"ID";s:3:"162";s:10:"post_title";s:90:"Handling
    various rubies at the same time in your machine with RVM – Ruby Version Manager";s:7:"matches";s:1:"2";s:9:"permalink";s:123:"http://techbot.me/2011/01/handling-various-rubies-at-the-same-time-in-your-machine-with-rvm-%e2%80%93-ruby-version-manager/";}i:2;a:4:{s:2:"ID";s:3:"115";s:10:"post_title";s:136:"Deployment
    Recipes – Deploying, monitoring and securing your Rails application to a clean
    Ubuntu 10.04 install using Nginx and Unicorn";s:7:"matches";s:1:"2";s:9:"permalink";s:158:"http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/";}i:3;a:4:{s:2:"ID";s:3:"101";s:10:"post_title";s:75:"Asynchronous
    email deliveries using Resque and resque_action_mailer_backend";s:7:"matches";s:1:"2";s:9:"permalink";s:102:"http://techbot.me/2010/07/asynchronous-email-deliveries-using-resque-and-resque_action_mailer_backend/";}i:4;a:4:{s:2:"ID";s:2:"98";s:10:"post_title";s:81:"If
    you’re cleaning up your user’s input in your views you’re doing it wrong";s:7:"matches";s:1:"2";s:9:"permalink";s:126:"http://techbot.me/2009/11/if-you%e2%80%99re-cleaning-up-your-user%e2%80%99s-input-in-your-views-you%e2%80%99re-doing-it-wrong/";}i:5;a:4:{s:2:"ID";s:2:"93";s:10:"post_title";s:68:"Building
    your own ActiveRecord validation macros with validates_each";s:7:"matches";s:1:"2";s:9:"permalink";s:95:"http://techbot.me/2009/09/building-your-own-activerecord-validation-macros-with-validates_each/";}i:6;a:4:{s:2:"ID";s:2:"53";s:10:"post_title";s:92:"Quick
    Tip – Using to_s as a label and simplified link_to calls to your ActiveRecord
    models";s:7:"matches";s:1:"2";s:9:"permalink";s:115:"http://techbot.me/2009/06/quick-tip-using-to_s-as-a-label-and-simplified-link_to-calls-to-your-activerecord-models/";}i:7;a:4:{s:2:"ID";s:2:"45";s:10:"post_title";s:62:"Building
    a I18N aware form builder for your Rails applications";s:7:"matches";s:1:"2";s:9:"permalink";s:89:"http://techbot.me/2009/06/building-a-i18n-aware-form-builder-for-your-rails-applications/";}i:8;a:4:{s:2:"ID";s:2:"16";s:10:"post_title";s:60:"Handling
    database indexes for Rails polymorphic associations";s:7:"matches";s:1:"2";s:9:"permalink";s:87:"http://techbot.me/2008/09/handling-database-indexes-for-rails-polymorphic-associations/";}i:9;a:4:{s:2:"ID";s:2:"12";s:10:"post_title";s:39:"Including
    and extending modules in Ruby";s:7:"matches";s:1:"2";s:9:"permalink";s:66:"http://techbot.me/2008/09/including-and-extending-modules-in-ruby/";}}
  _relation_threshold: '2'
  dsq_needs_sync: '1'
---
[caption id="attachment_147" align="alignleft" width="130" caption="The book you should get to dig deeper into Solr"]<a href="http://www.amazon.com/gp/product/1847195881?ie=UTF8&amp;tag=ultimaspalavr-20&amp;linkCode=as2&amp;camp=1789&amp;creative=390957&amp;creativeASIN=1847195881"><img src="http://techbot.me/wp-content/uploads/2011/01/solr.jpg" alt="The book you should get to dig deeper into Solr" title="The book you should get to dig deeper into Solr" width="130" height="160" class="size-full wp-image-147" /></a>[/caption]<a href="http://www.slideshare.net/mauricio.linhares/full-text-search-in-in-rails-with-sunspot-and-solr?from=embed">Click here if you want to see a PDF version of this tutorial.</a>

<a href="https://github.com/mauricio/sunspot_tutorial">Full source code for this tutorial is available at GitHub.</a>

Everyone wants to take their databases to run everything as fast as possible. We usually say query less, add more caching mechanisms, add indexes to the columns being searched, but another solution is not to use the database at all and look for better solutions for your querying needs.

<!--more-->

When querying for text in our databases, we’re often doing “LIKE” searches. Like searches are only performant if we have an index in that field and the query is written in a way that the index is used. Imagine that you have a field “name” and it contains the text “Battlestar Galactica”. This query would be able to run and use the index:

<pre class="brush:sql">SELECT p.* FROM products p WHERE p.name LIKE “Battlestar%”</pre>

The database would be able to optimize this query and use the index to find the expected row. But, what if the query was like this one:

<pre class="brush:sql">SELECT p.* FROM products p WHERE p.name LIKE “%Galactica”</pre>

[caption id="attachment_135" align="alignright" width="300" caption="Your DBA getting ready to hit you"]<a href="http://techbot.me/wp-content/uploads/2011/01/morningstar.png"><img src="http://techbot.me/wp-content/uploads/2011/01/morningstar.png?w=300" alt="Your DBA getting ready to hit you" title="Your DBA getting ready to hit you" width="300" height="250" class="size-medium wp-image-135" /></a>[/caption]Database indexes usually match from left to right, so, unless you have a nasty trick under your sleeve, this query will just look at ALL the rows in the products table and perform a match on every “name” column before returning a result. And that’s Really Bad News for you, as the DBA will probably come for you holding a Morning Star to beat you badly. So, querying with “LIKE” when you what you need is full text search isn’t nice.

That’s where full text search based solutions come in for help. Tools like <a href="http://lucene.apache.org/solr/">Solr</a> allow you to perform optimized text searches, filter input, categorization and even features like Google’s “Did you mean?”.

In this tutorial you’ll learn how to add full text searching capabilities to your <a href="http://rubyonrails.org/">Rails</a> application using <a href="https://github.com/outoftime/sunspot">Sunpot</a> and Solr. We will also delve a little bit into Solr’s configuration and learn how to use specific tokenizers to clear input, perform partial matching of words and faceting results.

This project uses Rails 3 and Ruby 1.9.2, you’ll find a <a href="http://gembundler.com/">Gemfile</a> and and “.rvmrc” with all dependencies declared, it should be pretty easy to follow or setup your environment based on it (if you’re not using <a href="http://rvm.beginrescueend.com/">RVM</a>, that’s a GREAT time to learn using it).

You can possibly follow this tutorial with a previous Rails version and without Bundler or RVM, given all models and most of the code will look exactly the same in Rails 2 and Sunspot is compatible to Rails 2 too.

The source code for this example application is available at GitHub <a href="https://github.com/mauricio/sunspot_tutorial">here</a>.

<h3>Starting the engines</h3>

Download the Sunspot <a href="https://github.com/outoftime/sunspot">source code from Github</a>.

Enter the project folder and go to “sunspot/solr-1.3”, inside that folder you should see a “solr” folder, copy this folder into your project’s folder. This is where the general Solr configuration is going to live, don’t worry about these files just yet, we’ll get to them later in this tutorial.

Now create a “sunspot.yml” file under your project’s “config” folder, here’s a sample:

<h3><a href="https://github.com/mauricio/sunspot_tutorial/blob/master/config/sunspot.yml">Listing 1 – sunspot.yml</a></h3>
<pre><code>development:
  solr:
    hostname: localhost
    port: 8980
    log_level: INFO
  auto_commit_after_delete_request: true

test:
  solr:
    hostname: localhost
    port: 8981
    log_level: OFF

production:
  solr:
    hostname: localhost
    port: 8982
    log_level: WARNING
  auto_commit_after_request: true  </code></pre>

You can have different configurations for every environment you’re running. To see all configuration options, go to the Sunspot source code and head to the <em>“sunspot_rails/lib/sunspot/rails/configuration.rb”</em> file.

Now we’ll create two models, <strong>Product</strong> and <strong>Category</strong>, so let’s start by creating the migration that will setup them:

<pre class="brush:shell">rails g migration create_base_tables</pre>

<h4>Listing 2 – create_base_tables.rb</h4>
<pre class="brush:ruby">class CreateBaseTables &lt; ActiveRecord::Migration

  def self.up
    create_table :categories do |t|
      t.string :name, :null =&gt; false
    end

    create_table :products do |t|
      t.string  :name, :null =&gt; false
      t.decimal :price, :scale =&gt; 2, :precision =&gt; 16, :null =&gt; false
      t.text    :description
      t.integer :category_id, :null =&gt; false
    end

    add_index :products, :category_id

  end

  def self.down
    drop_table :categories
    drop_table :products
  end

end
</pre>

Now we move on to the basic models, starting with the <strong>Category</strong> model:

<h4>Listing 3 – category.rb</h4>
<pre class="brush:ruby">class Category &lt; ActiveRecord::Base

  has_many :products

  validates_presence_of :name
  validates_uniqueness_of :name, :allow_blank =&gt; true

  searchable :auto_index =&gt; true, :auto_remove =&gt; true do
    text :name
  end

  def to_s
    self.name
  end

end
</pre>

Here in the Category class we see our first reference to Sunspot, the “searchable” method, where we configure the fields that should be indexed by Solr. At the Category class, there’s only one field that’s useful at this moment, the “name”, so we tell Sunspot to configure the field name to be indexed as “text” (you usually don’t want your text indexed as “string”, as it will only be a hit in a full match).

The :auto_index and :auto_remove options are there to let Sunspot automatically send your model to be indexed at Solr when it is created/updated/destroyed. The default is “false” for both values, which means you have to manually send your data to Solr and unless you really want to do that, you should keep both of these values as “true” in your models.

Now lets look at the <strong>Product</strong> class:

<h4>Listing 4 – product.rb</h4>
<pre class="brush:ruby">class Product &lt; ActiveRecord::Base

  belongs_to :category

  validates_presence_of :name, :description, :category_id, :price
  validates_uniqueness_of :name, :allow_blank =&gt; true

  searchable :auto_index =&gt; true, :auto_remove =&gt; true do
    text :name, :boost =&gt; 2.0
    text :description
    float :price
    integer :category_id
  end

  def to_s
    self.name
  end

end
</pre>

In our Product class things are a little bit different, we have more fields (and more kinds) being indexed. “float” and “integer” are pretty self explanatory, but the “name” field has some black magic floating around, with the “boost” parameter. Boosting a field when indexing means that if the match is in that specific field, it has more “relevance” than if found somewhere else.

Imagine that you’re looking for Iron Maiden’s “Powerslave” album. You go to Iron Maiden’s Online Store and search for “powerslave”, hoping that the album will be the first hit, but then you see “Live After Dead” before “Powerslave”. Why did it happen? The “Live After Dead” album contains the “Powerslave” song in it’s track listing, so it’s a match as much as the real “Powerslave” album. What we need here is to tell the search tool that if a match is on an album name, it has higher relevance than if the hit is in the track listing.

Boosting allows you to reduce these issues. Some fields are inherently more important than others and you can tell that to Solr by configuring a “:boost” value for them. When something matches on them, the relevance of that match will be improved and it should come up before the other results in search.

<h3>Searching</h3>

Now let’s take a look at the ProductsController to see how we perform the search:
 
<h4>Listing 4 – products_controller.rb</h4>
<pre class="brush:ruby">class ProductsController &lt; ApplicationController

  def index
    @products = if params[:q].blank?
      Product.all :order =&gt; 'name ASC'
    else
      Product.solr_search do |s|
        s.keywords params[:q]
      end
    end
  end

end
</pre>

As you can see, searching is quite simple, you just call the solr_search method and send in the text to be searched for. One thing that I don’t like about Sunspot is that searches do not return an Array like object, you get a Sunspot::Search::StandardSearch object that has, as a property, the results array which contains the records returned by the search.

Here’s a simple way to fix this issue (I usually place the contents of this file inside an initializer in “config/initializers”):

<h4>Listing 5 – sunspot_hack.rb</h4>
<pre class="brush:ruby">::Sunspot::Search::StandardSearch.class_eval do

  include Enumerable

  delegate(
    :current_page,
    :per_page,
    :total_entries,
    :total_pages,
    :offset,
    :previous_page,
    :next_page,
    :out_of_bounds?,
    :each,
    :in_groups_of,
    :blank?,
    :[],
    :to =&gt; :results)

end
</pre>

This simple monkeypatch makes the search object itself behave like an Enumerable/Array and you can use it to navigate directly in the results, without having to call the “results” method. The methods usually used by will_paginate helpers are also included so you can pass this object to a will_paginate call in your view and it’s just going to work.

<h3>Indexing</h3>

Now that all the models are in place, we can start fine tuning the Solr indexing process. First thing to understand here is what happens when you send text to be indexed by Solr, let’s get into the tool, starting the server:

<pre class="brush:shell">rake sunspot:solr:run</pre>

This rake task starts Solr in the foreground (if you wanted to start it in the background, you’d use “sunspot:solr:start”). With Solr running, you should add some data to the database, this tutorial’s project on Github contains a <a href="https://github.com/mauricio/sunspot_tutorial/blob/master/db/seeds.rb">“seed.rb”</a> file with some basic data for testing, just copy it over your project.

Also copy the <a href="https://github.com/mauricio/sunspot_tutorial/blob/master/lib/tasks/db.rake">“lib/tasks/db.rake</a>” from the project to your project, it contains a “db:prepare” task that truncates the database, seeds it and then indexes all items in Solr and we’re doing to be reindexing data a lot.

With everything copied, run the “db:prepare” task:

<pre class="brush:shell">rake db:prepare</pre>

This will add the categories and products to your database and also index them in Solr. If this task did run successfully, head to the Solr administration interface, at this URL:

<a href="http://localhost:8980/solr/admin/schema.jsp">http://localhost:8980/solr/admin/schema.jsp</a>

Once you go to it, click on the “FIELDS”, then on “NAME_TEXT”, you should see a screen just like the one in image 1:
[caption id="" align="alignnone" width="1023" caption="Image 1 – Solr schema browser"]<img alt="Image 1 – Solr schema browser" src="http://img.skitch.com/20110113-esa6g3uwcxu1fcn93kdah2yd13.jpg" title="Image 1 – Solr schema browser" width="1023" height="718" />[/caption]

If you don’t see all the fields that are available in this image, your “rake db:prepare” command has probably failed or Solr wasn’t running when you called it.

What we see here is the information about the fields we’re indexing. This specific field contains all data from the name properties from both Category and Product classes, as you can notice from the top 10 terms.

The name field is not indexed by it’s full content, as a relational database would usually do, the text is broken into tokens, by the solr.StandardTokenizerFactory class in Solr. This class receives our text, like <a href="http://www.amazon.com/gp/product/1589944607?ie=UTF8&amp;tag=ultimaspalavr-20&amp;linkCode=as2&amp;camp=1789&amp;creative=390957&amp;creativeASIN=1589944607">“Battlestar Galactica: The Boardgame”</a> and turns it into:

<pre class="brush:ruby">[“Battlestar”, “Galactica”, “The”, “Boardgame”]</pre>

This is what gets indexed and, ultimately, searched by Solr. If you open the web application now and try to search for “battle”, you won’t have any matches. If you search for “Battlestar”, you get the two products that match the name.

Everything when indexing information in Solr revolves around building the best “tokens” available for your input. You have to teach Solr to crunch your data in a way that makes sense and makes it easy to search for, and adding filters to the indexing process does this. While in the same page as Image 1 above, click on the “DETAILS” links as shown in Image 2:

[caption id="" align="alignnone" width="553" caption="Image 2 – Viewing the analysis and search filters"]<img alt="Image 2 – Viewing the analysis and search filters" src="http://img.skitch.com/20110113-939xbwkq9ehtkea5d6q5cnksp.jpg" title="Image 2 – Viewing the analysis and search filters" width="553" height="546" />[/caption]

Each field in Solr has two analyzers, one is the “index” analyzer, that prepares the input to be indexed and the other is the “query” analyzer that prepares the search input to finally perform a search. Unless you have some special need, both of them are usually the same.

In our current configuration, we have the same two filters for both of the analyzers. The StandardFilterFactory filter removes punctuation characters from our input (the “:” in “Battlestar Galactica: The Boardgame” is not in our tokens) and the LowerCaseFilterFactory makes all input lowercased so we can search with “baTTle”, “BATTLE”, “BaTtLe” and they’re all going to work.

Before we move on to add more filters to our analyzers, let’s take a look at the analyzer screen in Solr Admin at - <a href="http://localhost:8980/solr/admin/analysis.jsp?highlight=on">http://localhost:8980/solr/admin/analysis.jsp?highlight=on</a>

In this screen we see how our input is going to be transformed into tokens by the configured analyzers.

[caption id="" align="alignnone" width="1019" caption="Image 3 – Solr analyzer page"]<img alt="Image 3 – Solr analyzer page" src="http://img.skitch.com/20110113-ncqkyrgrn4us5fbxn4p727t5f3.jpg" title="Image 3 – Solr analyzer page" width="1019" height="540" />[/caption]

In this screen we have selected the “name_text” field in Solr. In the “Field value (Index)” you enter the values you’re sending to be indexed, just like you would send from your model property, in the “Field value (Query)” you enter the values you’d use to search.

Once you type and hit “Analyze” you should see the output just below the form as we see in Image 3. This output shows how your input is transformed into tokens by the tokenizer and filters, this way you can easily experiment by adding more filters and seeing if the output really matches the way you’d expect it to. This analysis view is your best friend when debugging search/indexing related issues or trying out ways to improve the way Solr indexes and matches your data.

<h3>Customizing fields</h3>

Now that you have an idea about how the indexing and searching process work, let’s start to customize the fields in Solr, open up the “solr/conf/schema.xml” file and look for this reference:

<h4>Listing 6 – solr/conf/schema.xml except</h4>
<pre class="brush:xml">&lt;fieldtype class=&quot;solr.TextField&quot; positionIncrementGap=&quot;100&quot; name=&quot;text&quot;&gt;
      &lt;analyzer&gt;
        &lt;tokenizer class=&quot;solr.StandardTokenizerFactory&quot;/&gt;
        &lt;filter class=&quot;solr.StandardFilterFactory&quot;/&gt;
        &lt;filter class=&quot;solr.LowerCaseFilterFactory&quot;/&gt;
      &lt;/analyzer&gt;
    &lt;/fieldtype&gt;
</pre>

If you look at Image 1, where we saw the “name_text” configuration, you’ll see that the field type is “text”, this except above is the configuration for all fields of type “text”, which means that if we add more filters here we’ll affect all fields of this type. This greatly simplifies the way we configure the tool, as we don’t have to define explicit configurations for every single field that our models have, we can just reuse this same “text” config for all fields that are supposed to be indexed as text.

But that’s a lot of talking, let’s get into action!

Let’s start the job by looking at our indexed data from before:

<pre class="brush:ruby">[“battlestar”, “galactica”, “the”, “boardgame”]</pre>

The “the” is mostly useless, as it’s going to be available in almost all properties and no one is ever going to search for “the” (oh yeah, there might be that ONE guy that does it). In Information Retrieval lingo, “the” is a stop word, it usually doesn’t have meaning by itself and doesn’t represent valuable information for our indexer, removing all stop words from your input improves performance and the relevance of your results.

Given that this is a common operation, Solr already contains a filter that’s capable of removing all stop words from your data, the solr.StopFilterFactory, let’s see how we can add it to our config:

<h4>Listing 7 – solr/config/schema.xml except</h4>
<pre class="brush:xml">&lt;fieldtype class=&quot;solr.TextField&quot; positionIncrementGap=&quot;100&quot; name=&quot;text&quot;&gt;
  &lt;analyzer&gt;
    &lt;tokenizer class=&quot;solr.StandardTokenizerFactory&quot;/&gt;
    &lt;filter class=&quot;solr.StandardFilterFactory&quot;/&gt;
    &lt;filter class=&quot;solr.LowerCaseFilterFactory&quot;/&gt;
    &lt;filter class=&quot;solr.StopFilterFactory&quot; words=&quot;stopwords.txt&quot; ignoreCase=&quot;true&quot;/&gt;
    &lt;filter class=&quot;solr.ISOLatin1AccentFilterFactory&quot;/&gt;
    &lt;filter class=&quot;solr.TrimFilterFactory&quot; /&gt;
  &lt;/analyzer&gt;
&lt;/fieldtype&gt;
</pre>

If you look at the “solr/config” folder you’ll se a “stopwords.txt” file that already contains most of the common stop words in English, you can add or remove words from there as needed and if you’re not indexing English text you can just remove the English names and add your language’s stop words. Now change this in your “solr/config/schema.xml” file and stop and start Solr again and open the analyzer:

[caption id="" align="alignnone" width="1011" caption="Image 4 – Solr analyzer page "]<a href="http://img.skitch.com/20110113-8c4ynujuesm1w991nxfbs8dnme.jpg"><img alt="Image 4 – Solr analyzer page " src="http://img.skitch.com/20110113-8c4ynujuesm1w991nxfbs8dnme.jpg" title="Image 4 – Solr analyzer page " width="1011" height="710" /></a>[/caption]

As you can see, in the last step, the “the” was removed from both the index input and the query input, we’re maintaining only the pieces of information that are really useful, this makes our index smaller and also speeds up searching.

While you were not looking, we have also added two other filters, solr.ISOLatin1AccentFilterFactory, that removes accents from words in Latin based languages, like Portuguese. If the input is “não”, it becomes “nao”. And after that there’s solr.TrimFilterFactory, that removes unnecessary spaces from our tokens.

<h3>Partial matching</h3>

Another pretty common need is to be able to match only a part of a word, usually a prefix. In the beginning of the tutorial, we saw that searching for “battle” doesn’t yield any results, while “battlestar” does. This happens because Solr, by default, only sees a match if it’s a full match. The word you entered must be exactly the same as a token that’s available in the index, if there is no exact match, Solr you tell you that there are no results.

If you look at <a href="http://lucene.apache.org/java/2_9_1/queryparsersyntax.html">Lucene’s Query Parser Syntax</a>  (Solr is somewhat a web interface to Lucene) you’ll see that you can use the “*” operator to perform a partial match. We could then search for “battle*” and this would yield the results we expect, but doing this kind of partial matching is slow and could possibly become a bottleneck for your application, so we have to figure out another way to do this.

When all you need is prefixed partial matching, the solr.EdgeNGramFilterFactory is your best friend. It will break words into pieces that will then be added to the index, so it looks like you have partial matching, but in fact the partials are tokens by themselves in the index, let’s see how our config would look like in this case:

<h4>Listing 8 – solr/config/schema.xml except</h4>
<pre class="brush:xml">&lt;fieldtype class=&quot;solr.TextField&quot; positionIncrementGap=&quot;100&quot; name=&quot;text&quot;&gt;
  &lt;analyzer type=&quot;index&quot;&gt;
    &lt;tokenizer class=&quot;solr.StandardTokenizerFactory&quot;/&gt;
    &lt;filter class=&quot;solr.StandardFilterFactory&quot;/&gt;
    &lt;filter class=&quot;solr.LowerCaseFilterFactory&quot;/&gt;
    &lt;filter class=&quot;solr.StopFilterFactory&quot; words=&quot;stopwords.txt&quot; ignoreCase=&quot;true&quot;/&gt;
    &lt;filter class=&quot;solr.ISOLatin1AccentFilterFactory&quot;/&gt;
    &lt;filter class=&quot;solr.TrimFilterFactory&quot; /&gt;
    &lt;filter class=&quot;solr.EdgeNGramFilterFactory&quot;
      minGramSize=&quot;3&quot;
      maxGramSize=&quot;30&quot;/&gt;
  &lt;/analyzer&gt;
  &lt;analyzer type=&quot;query&quot;&gt;
    &lt;tokenizer class=&quot;solr.StandardTokenizerFactory&quot;/&gt;
    &lt;filter class=&quot;solr.StandardFilterFactory&quot;/&gt;
    &lt;filter class=&quot;solr.LowerCaseFilterFactory&quot;/&gt;
    &lt;filter class=&quot;solr.StopFilterFactory&quot; words=&quot;stopwords.txt&quot; ignoreCase=&quot;true&quot;/&gt;
    &lt;filter class=&quot;solr.ISOLatin1AccentFilterFactory&quot;/&gt;
    &lt;filter class=&quot;solr.TrimFilterFactory&quot; /&gt;
  &lt;/analyzer&gt;
&lt;/fieldtype&gt;
</pre>

As you can see, now we have two  sections in our , one of the analyzers is for “index” and the other is for “query”. This is needed because we don’t want to have our search parameters being transformed for a partial match. If the user is searching for “battle”, it doesn’t makes sense to show him results for “bat”, so the generation of pieces of each word should be done only when indexing information.

Now restart your Solr instance and head run again the form we had in the analyzer view, you should see something like Image 5:

[caption id="" align="alignnone" width="1330" caption="Image 5 – Analyzer output with partial matching enabled"]<a href="https://img.skitch.com/20110113-dq7u2aeafnjt7ccdq3pxub23pb.jpg"><img alt="Image 5 – Analyzer output with partial matching enabled" src="https://img.skitch.com/20110113-dq7u2aeafnjt7ccdq3pxub23pb.jpg" title="Image 5 – Analyzer output with partial matching enabled" width="1330" height="732" /></a>[/caption]

Looking at the output, “battlestar” became:

<pre class="brush:ruby">[“bat”, “batt”, “battl”, “battle”, “battles”, “battlest”, “battlesta”, “battlestar”]</pre>

Now, if you search for “battle”, you should find all products that have “battle” as a prefix in any of their words and the search input is not affected by this change.

<h2>Faceting</h2>

Faceting of results is <strong>YACF (Yet Another Cool Feature)</strong> that you have when using Solr and Sunspot. “What does that mean?”, you might ask, it means that Solr is able to organize your results based on one of it’s properties and tell you how many results did match for every property value.

“I still don’t get it”, you might be thinking now. In our Product model we’re indexing the “category_id” property, we’ll tell Sunspot to facet our search based on the “category_id” field and Sunspot will tell us how many matches each category had, even if we’re paginating the results. Let’s see how our searching code would change:
 
<h4>Listing 9 – products_controller.rb except</h4>
<pre class="brush:ruby">
  def index
    @page = (params[:page] || 1).to_i
    @products = if params[:q].blank?
      Product.paginate :order =&gt; 'name ASC', :per_page =&gt; 3, :page =&gt; @page
    else

      result = Product.solr_search do |s|
        s.keywords params[:q]
        unless params[:category_id].blank?
          s.with( :category_id ).equal_to( params[:category_id].to_i )
        else
          s.facet :category_id
        end
        s.paginate :per_page =&gt; 3, :page =&gt; @page
      end

      if result.facet( :category_id )
        @facet_rows = result.facet(:category_id).rows
      end

      result
    end
  end
</pre>

The search code really changed a lot, now if there’s a “category_id” parameter we will use that to filter our search, if there isn’t we’re going to perform faceting with the “s.facet :category_id” call. There’s also a slight change to the “product.rb” class, let’s see it:

<h4>Listing 10 – product.rb except</h4>
<pre class="brush:ruby">
  searchable :auto_index =&gt; true, :auto_remove =&gt; true do
    text :name, :boost =&gt; 2.0
    text :description
    float :price
    integer :category_id, :references =&gt; ::Category
  end
</pre>

We’ve added the “:references =&gt; ::Category” to the “:category_id” field configuration so Sunspot knows that this field is, in fact, a foreign key to another object, this will allow Sunspot to load the categories in the facets automatically for you.

The “result.facet(:category_id)” asks the search object for the array that contains the facets returned for the :category_id field in this search. Each row in this list contains an “instance” (which, in our case, is an Category object) and a “count”, that’s the number of hits in that specific facet. Once you get your hands at the rows, we can use it in our view, let’s see how we used them:
 
<h4><a href="https://github.com/mauricio/sunspot_tutorial/blob/master/app/views/products/index.html.haml">Listing 11 – products/index.html.haml except</a></h4>
<pre><code>  - if !@facet_rows.blank? &amp;&amp; @facet_rows.size &gt; 1
    %ul
      - for row in @facet_rows
        %li= link_to( "#{row.instance} (#{row.count})", products_path( :q =&gt; params[:q], :category_id =&gt; row.instance ) )</code></pre>

If there are facets available, we use them to add links that will make the user filter based on each specific facet, each row object has an instance and a count, and we use both in the interface to tell the user which category is it and how many hits it had. Look at how our user interface looks like:

[caption id="" align="alignnone" width="376" caption="Image 6 – Faceting information"]<img alt="Image 6 – Faceting information" src="https://img.skitch.com/20110113-8u9sqb5arch31japkx372dq6fs.jpg" title="Image 6 – Faceting information" width="376" height="467" />[/caption]

And now you finally have search functionality added to a Rails project, with partial matching, faceting, pagination and input cleanup. Just forget that you have ever performed a “SELECT p.* FROM products p WHERE p.name LIKE ‘%battle%’” and be happy to be using a great full text search solution.

<h2>Conclusion</h2>

Hopefully this tutorial should be enough to get you up and running with Solr, for more advanced features I’d recommend you to search on the <a href="http://wiki.apache.org/solr/FrontPage">Solr wiki</a> and buy <a href="http://www.amazon.com/gp/product/1847195881?ie=UTF8&amp;tag=ultimaspalavr-20&amp;linkCode=as2&amp;camp=1789&amp;creative=390957&amp;creativeASIN=1847195881">“Solr 1.4 – Enterprise Search Server”</a>  by David Smiley and Erick Pugh.

<h2>Related Posts</h2>

<ul>
<li><a href="http://techbot.me/2010/08/deployment-recipes-deploying-monitoring-and-securing-your-rails-application-to-a-clean-ubuntu-10-04-install-using-nginx-and-unicorn/">Deployment Recipes – Deploying, monitoring and securing your Rails application to a clean Ubuntu 10.04 install using Nginx and Unicorn</a></li>
<li><a href="http://techbot.me/2011/01/handling-various-rubies-at-the-same-time-in-your-machine-with-rvm-%E2%80%93-ruby-version-manager/">Handling various rubies at the same time in your machine with RVM – Ruby Version Manager</a></li>
<li><a href="http://techbot.me/2010/07/asynchronous-email-deliveries-using-resque-and-resque_action_mailer_backend/">Asynchronous email deliveries using Resque and resque_action_mailer_backend</a></li>
<li><a href="http://techbot.me/2008/12/sql-functions-in-where-clauses-are-evil/">SQL functions in WHERE clauses are evil</a></li>
</ul>
