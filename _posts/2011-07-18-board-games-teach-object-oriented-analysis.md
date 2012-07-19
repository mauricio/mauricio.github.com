---
layout: post
title: Using board games to teach object oriented analysis
tags:
- analysis
- Education
- education. board games
- en_US
- object oriented design
status: publish
type: post
published: true
meta:
  _su_keywords: board games, object oriented design, analysis, education
  _su_description: Board games are a great source for problems if you're trying to
    come up with a model for an object oriented analysis and design class
  _edit_last: '1'
  _su_title: ! 'Using board games to teach object oriented analysis '
  _su_rich_snippet_type: none
  dsq_thread_id: '361602744'
  _efficient_related_posts: a:0:{}
  _relation_threshold: ''
---
Just when I arrived from Cambridge back home <a href="http://www.linkedin.com/in/erikobrito">the coordinator</a> at <a href="http://www.faculdadeidez.com.br/">the college</a> where I usually teach after-grad courses mailed me asking if I’d be available to pick up an “Object Oriented Analysis and Design” class. I was still unpacking my stuff but I just said yes. Why not? It’s something I really like to teach and talk about, could be great to get me back to teaching after 5 months away from classes.

While preparing the material, I started thinking about how to add something unusual. It wasn’t long until I looked at my wardrobe and saw the pile of board game boxes in there. I looked at them and thought, I can get them to model the games themselves!

<!--more-->

<h3>Meeting board games</h3>

[caption id="attachment_395" align="alignleft" width="600" caption="Ticket to Ride: Europe team learning how the game goes"]<a href="http://techbot.me/wp-content/uploads/2011/07/ticket-to-ride-team-in-action.jpg"><img src="http://techbot.me/wp-content/uploads/2011/07/ticket-to-ride-team-in-action.jpg" alt="Ticket to Ride: Europe team learning how the game goes" title="Ticket to Ride: Europe team learning how the game goes" width="600" height="449" class="size-full wp-image-395" /></a>[/caption]I started on European style board games on 2007, when doing a presentation at the <a href="http://blog.fragmental.com.br/2007/02/05/erecompal-2007/">ERECOMP-Alagoas</a> with <a href="http://fragmental.tw/">Phil Calçado</a>. After the event we headed back to the hotel and instead of doing nothing we went out to drink something and talk and he said he had met his wife at a <a href="http://www.amazon.com/gp/product/B004DZ8WYE/ref=as_li_ss_tl?ie=UTF8&tag=ultimaspalavr-20&linkCode=as2&camp=217145&creative=399369&creativeASIN=B004DZ8WYE">Carcassonne</a> table, an European board game his friends discovered and everyone was having fun. 

I can’t say I was board games fan in the past, mostly because all I knew about them was Risk and Monopoly and you just get bored after playing them for a while. But Phil said these European board games were different, so, why not try them? After the event I found a shop and got Settlers of Catan and Carcassonne. When they arrived, it was like an addiction, we were playing Settlers every weekend and from that time to today the board games collection has grown from those two to more than 10 different games games and their expansions (Dominion alone is now at six boxes).

<h3>How come you’re using board games on classes?</h3>

[caption id="attachment_397" align="alignleft" width="600" caption="Settlers of Catan team picking up resources"]<a href="http://techbot.me/wp-content/uploads/2011/07/settlers-team-in-action.jpg"><img src="http://techbot.me/wp-content/uploads/2011/07/settlers-team-in-action.jpg" alt="Settlers of Catan team picking up resources" title="Settlers of Catan team picking up resources" width="600" height="449" class="size-full wp-image-397" /></a>[/caption]Why use board games, you might ask. The course itself is an after-grad course (we call it specialization here in Brazil, it would be something like a graduate school in the US), classes happen every 15 days, on Friday nights from 6:30 to 10:30 and Saturdays from 8:00 to 12:00 and again from 13:00 to 17:00. So students see the same teacher and the same class for 12 hours straight over one weekend.

As you might imagine, 12 hours straight of the same teacher talking about the same subject is not the definition of fun, so you have to come up with unorthodox solutions in your class to keep everyone interested in what you’re talking. You need to engage the students on whatever you’re teaching so they’re not drifting away to sleep after lunch on a Saturday afternoon.

I had a problem, coming up with an interesting topic to use as an example. I couldn’t just bring a shallow model, as it would not fit the idea that was to exercise analysis and design but I couldn’t just bring up something that was too difficult or needed too much background to understand. Also, it had to be something the students could easily relate to and enjoy modeling.

Thing is, board games were the best choice ever.

<h3>First contact</h3>

[caption id="attachment_398" align="alignleft" width="600" caption="Modeling, Modeling, Modeling..."]<a href="http://techbot.me/wp-content/uploads/2011/07/settlers-team-playing.jpg"><img src="http://techbot.me/wp-content/uploads/2011/07/settlers-team-playing.jpg" alt="Modeling, Modeling, Modeling..." title="Modeling, Modeling, Modeling..." width="600" height="449" class="size-full wp-image-398" /></a>[/caption]As expected, the students had no previous experience with any of the two board games I got in, <a href="http://www.amazon.com/gp/product/B000W7JWUA/ref=as_li_ss_tl?ie=UTF8&tag=ultimaspalavr-20&linkCode=as2&camp=217145&creative=399369&creativeASIN=B000W7JWUA">“Settlers of Catan”</a> and <a href="http://www.amazon.com/gp/product/B000809OAO/ref=as_li_ss_tl?ie=UTF8&tag=ultimaspalavr-20&linkCode=as2&camp=217145&creative=399369&creativeASIN=B000809OAO">“Ticket to Ride: Europe”</a> (well, not all of them, <a href="http://twitter.com/#!/lilamoura">one is a close friend of mine</a> that has played most of them, but she has never played “Ticket to Ride”, as I just brought it from the US, so it was her first experience with it also). 

The plan is that they have to build a model that’s going to be used to implement these games in the computer, so they have to understand the game rules, themes and development. The fact that they have no previous experience with these games helps simulate the issues we face daily while building software for real. We have to learn the domain as we go, things change and new rules show up at any time.

They had no access to the game rules, I was the only source of information and I intentionally did not give them all the information required to play the game. Information was given in pieces and while they started playing the games to get a feel of them I would come in and bring a new rule. When they got stuck or had no idea how to move forward, they came to me and asked how that would go, as they would ask a client how a feature is supposed to work. While asking and playing the games, they were taking notes and starting to think about how the game is supposed to be modelled. After playing the games for half an hour or a little bit more, they started the real fight, turning those notes into the model.

<h3>Modeling in action</h3>

[caption id="attachment_399" align="alignleft" width="600" caption="&quot;This is how the train goes!&quot;"]<a href="http://techbot.me/wp-content/uploads/2011/07/ticket-to-ride-team-modelling.jpg"><img src="http://techbot.me/wp-content/uploads/2011/07/ticket-to-ride-team-modelling.jpg" alt="&quot;This is how the train goes!&quot;" title="&quot;This is how the train goes!&quot;" width="600" height="449" class="size-full wp-image-399" /></a>[/caption]As simple as these games look like when you’re playing, bringing this simplicity into a computer is not really that, well, simple. Rules that just make sense when you’re playing the game become sources of complexity in a model, just like the Train Station rule on “Ticket to Ride”. In the game, you’re building rail roads connecting two cities with your own trains, but you can place a train station in a city and use someone else’s trains as if your own if they’re connected to your Train Station. But then these Train Station connections are not valid for the “European Express” objective and they also mean you gave up on points at the end of the game.

Rules that are just common sense for us, players, are not that easy to come by to computers. They have to be told what to do and how to do it and this is where modeling these games is a real challenge that goes really beyond the usual “mapping from the database” we see on nowadays “enterprise” applications. These games have rich models, their own internal language and behaviors, which makes them even more interesting to a design class, as you have many different issues to solve and you’re possibly having fun by doing it about a game.

<h3>Does it work?</h3>

So far, I would say it met my objectives. The students were highly engaged in trying to figure out how to make those rules become objects in a system (and they also loved to meet and play the games! ☺ ). Some specific cases led to interesting discussions, like how can we implement the “action” during a turn on “Ticket to Ride: Europe”, as each player can perform one of four really different actions (pick cards, pick destination tickets, claim routes or place a train station) and how to model the “Settlers of Catan” game board in a way it would be possible to place terrains and also make sure the settlements and roads would be correctly placed.

They are going to be working on refining the models and in 15 days we will meet again for the final presentation and some “show me the code” about how these games could be implemented. I hope that by the end of this class they will have an improved background on object oriented analysis and built on top of real world knowledge, not only reading books or listening to a teacher talking about objects, relationships and design patterns.

My mother, an elementary school teacher, always tried to do something different for her children, with new games, songs, drawings and activities that went beyond the usual “talk, read and write” and she can barely use a computer. Today we have so many different possibilities and materials but we keep ourselves stuck into the “Power point bullets”, confined in a sequential list of topics.

We can do better. We can improve. We just have to try.

<strong>And stay tuned to the results of this crazy experience, I will be sure to post my findings here as soon as the class ends.</strong>
