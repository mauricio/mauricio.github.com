---
layout: post
title: Transitioning projects to a new team
subtitle: Tips and tricks on how to make these events less painful
keywords: architecture, management, leadership, transitions, growth
tags:
- useful
---

If you've been long enough on the same team or job, you've been either the recipient or the originator of a transition. Maybe the team mission has changed, people have moved, or you are moving somewhere else, a new job or a new team and existing software need a new home. Frequently, this is a short engagement. Someone is leaving, so they schedule a couple of meetings to _share knowledge_, write a bunch of docs, and that's it.

But it doesn't have to be like this. We're just going through disbanding a team and finding new homes for our existing projects, and we're trying to make this less frustrating for everyone involved. Our main goal with this process is to make it easier for the other side to learn and maintain these systems.

The process involves:
What to do before the transition starts;
The actual transition work;
What happens once the transition completes;

## Pre-transition

The first question you should ask of every project planned for transition is *do we need this?*. You're going to invest time in moving a resource to another team that will also have to invest in understanding and maintaining it, most likely without any previous experience. Can you kill it now and not even move?

Can you replace it with some other tool that is already available, a SaaS solution, or some other integration that would require less work than keeping the whole thing running?

Looking for an existing solution for the problem so you don't have to maintain it could be better than keeping a project alive. You'll have to invest time in setting up the project for the new team, and they will have to learn how it works and then maintain it (the most expensive part of running software). If you can use a tool that someone else will support at an acceptable price, a better solution might be to go that route instead of keeping the project alive.

If there's no other available solution or it would be too risky for the business to outsource this to another company, it's time to prepare the transition work.

Start by building an inventory of all the pieces to be moved. Source code repositories, dashboards, databases, deployments, CI pipelines, service accounts, tokens, and any other resource that the service uses. The more stuff you can find and document, the less risky the move, especially for service accounts and tokens. It's surprisingly common for service resources to be tied directly to *personal* accounts, and when you move ownership somewhere else, the service breaks, and no one knows why.

With the inventory in hand, it's time for a cleanup. Are there any resources that belong to specific people instead of a shared service account or shared roles? If there are, it's time to move them into a shared service account or roles. This will make the transition more manageable as the new team will join the service account or role and own the resources.

Shore up documentation, playbooks, incident reviews, and standard practices the team performs. All teams have rituals to deal with their day-to-day work that might not be documented. This is the time to turn these rituals into well-defined processes the new people should know. It doesn't mean they will have to perform the same practices the same way. You're just letting them know how the team operates right now.

Is there a typical sequence of steps people usually follow when they think an incident is going on? Make it a playbook. Got a specific sequence you perform database maintenances? Document it. Are deployments supposed to run in a particular order? Either encode that on your CI config or document it.

Review existing documentation to verify it's still valid and up to date. As projects age, explanations, diagrams and the like grow stale, this is the time for you to update or delete documentation that is not valid anymore. Old or wrong documentation is generally worse than not having any documentation at all. Code that performs complex computation should also be documented and thoroughly tested with examples of known failure scenarios. The new people joining have no context on the existing code or the decisions that led to its current state. Make sure it is clear why it does the work the way it does.

Define them now if you don't have clearly defined [SLOs](https://en.wikipedia.org/wiki/Service-level_objective). Odds are you have clear expectations for what the service has to do and how long it takes to do the work (including alerting when it's not doing that on time), but you might not have them written down. Make them visible now, so the new team knows what to expect when they take this on.

## Transitioning

So there's no way for you to throw this project in the trash, eh? Time to move it elsewhere. Build a timeline with the work that needs to be done for transition. There will be meetings, coding, presentations, so make sure you're accounting for them and, most importantly, it should have an end date. The time by which the project now belongs to the new team.

While _knowledge sharing_ sessions are somewhat helpful, what is useful is to work on actual code building real stuff on the project. Find features that touch the code and have people on both teams pair up on building them, with the person on the original team as passengers.

You want the new team to get as much exposure to the codebase as possible, so make sure the work is done mainly with guidance from the current team but not active work. This will force the new team to go through a development environment setup and, hopefully, a complete release cycle. Building the feature, producing artifacts, and pushing them to production.

If there are on-call rotations, start with the new folks as secondaries but always reach out to them if incidents happen during working hours. You also want them to have exposure to the project when stuff goes sideways to learn how to debug issues and react to incidents.

Suppose incidents are infrequent enough that you don't expect them to happen during the transition, roleplay something that has occurred recently. When roleplaying, make the new team the drivers. You provide the problem and let them ask questions on what is going on to get more information and respond to their actions. Your main goal here is to let them feel the system and associate how the pieces fit together to make it work.

Start moving resource ownership to the new team. Source code, machines, tokens, teams, should all either include the new team or be moved to be owned by them. It's essential to move resources now, during the transition, as outages or issues caused by these moves will be easier to fix while the old team is still active and working on the code. If you let this happen only after all the work is done, there might be surprising behavior lurking around. Also, don't move it all at once. Move resources one at a time, make sure they work at their new home, and go to the next one. Making multiple changes at once on a project is a surefire way to cause issues.

Present the new people to the teams you're used to interacting with as the project's new owners. The existing team needs to make it visible that new people are working on this, and they are the ones that people should communicate with instead of their usual contacts. There is always a lot of informal communication between teams, and it's crucial to get the new folks into the flow, get them invited to scheduled meetings, and present them to people frequently in contact.

## After transitioning

At this point, the old team has disengaged from the project entirely. They should not be on call and should not be involved in the day-to-day operation. You want a clean break for the old team because you want them to focus on the new work they're doing and not worry about _what is going on at the old thing_.

That's why it's essential to have a firm date to when it ends, so the people leaving don't feel like they have to wear multiple hats because they left this other project behind. It doesn't mean they shouldn't engage when needed, answer questions, or help out, but they should no longer have to worry about what's going on at the old project.

I hope these tips can lead you to better transitions in and out of projects!