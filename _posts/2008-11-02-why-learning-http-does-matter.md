---
layout: post
title: Why learning HTTP does matter
tags:
- useful
---

It's interesting to notice that there's so many people working with web applications that don't understand the basics of the Internet and the HTTP protocol. You might find applications that exhibit bizarre behaviors anywhere, people just forget to read the specs or sleep during the HTTP protocol classes at college.

One of the most harmful exhibitions of this lack of knowledge is the “POST fever”. Every form in the application performs a POST, no matter what it's doing or the side effects involved in it, it just works that way and people just don't have a reason not to go like that, usually, if you ask them, they'll probably say “oh, someone told me that the GET method has size limit in it's parameters size”.

## But, what's so bad about it?

If you take a look at the [HTTP RFC](http://www.w3.org/Protocols/rfc2616/rfc2616.html), you will find that the `GET` method is described as a [“safe”](http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.1.1) method. Safe, in the HTTP context, means that you should be able to perform `GETs` to a web application and this should have no side effects on it, it should not change the resource you are requesting, because the whole idea of the `GET` method is that you should just `GET` a copy of the resource at that specific URL, you're not doing anything funny with it, you should just receive it anywhere and anytime you want to.

But if you look at the `POST` method description, it's defined as an “unsafe” method. If you send a `POST` to a URL you might be definitely changing something and generating an evil side effect that might render the whole application useless and bring Skynet and the Terminators to lay Armageddon on Earth. Or you might just be creating a new resource, as a blog posting like this one.

The obvious difference is that `POSTs` can (and usually should) change the state of something at the server side, while a `GET` should never do something like that. If you're keen to SQL databases, `GETs` are just like “select” commands and `POSTs` like “insert” commands. Have you ever seen an “insert” returning a result set or a “select” inserting data? Me neither :)

But bear with me, it `GETs` even worse. Imagine that you're the owner of that evil website that I said that just uses `POSTs` in it's forms and one of those forms is a search form. Users will use it to search for your products and add them to their shopping carts. A user wants to buy the new AC/DC records but he's not sure about it's name, so he just types AC/DC and hits enter.

Voila!

There, at the top of the list, is “Black Ice”, their new record (Have you already bought yours?). He clicks on the link and while he's viewing the CD page he remembers that he hasn't bought the “Stiff Upper Lip” album. “Let me hit the back button and look for it too”, thinks the poor user and when he hit the button, the browser shows an interesting message:

“The browser will need to send data to the server to perform this action. Are you sure you want to do this?”

The user looks terrified to the message. “What have I done? Will they bill me for this? Are they going to send me the new Britney Spears album 'cos I'm trying to hit the back button?”

As the HTTP protocol mandates, `POSTs` are not safe and the tools (usually, our browsers) should tell the user that something bad might happen if they try to `POST` by accident and that's exactly what happens if you try to hit the back button after a `POST`. In this example, the user wouldn't be doing anything wrong, but instead of coming back to a search page, he could be at a “add client” page and a “back” would make him re-create the last client he sent to the database, which isn't really interesting.

Worse, if you're using `POST` in a search form, they aren't going to be able to use the back button (and the usability gurus say that it's the most used feature in browsers) and they aren't going to be able to bookmark the search results! Can you imagine something worse than that? You are keeping people from expressing their love for you website by posting it in their del.icio.us favorites!

Now, the reasoning is simple, if you're not changing anything at the server side, you should always perform `GETs`. They don't break the back button, they let the users bookmark their pages and they aren't going to make the browser show the user any funny messages. If you're changing state at the server side you should definitely use `POST` (and the other `HTTP` methods that are designed to change state, like `PUT` and `DELETE`), `GET` requests should NEVER change any state at the server side.

And before I forget, after every successful `POST` you should `REDIRECT` the user to a new page and not just render the page for him in response for the `POST`. Redirecting the user to the “response” page keeps the user from hitting the “back” button and re-entering the data they have already sent during the last `POST`.
