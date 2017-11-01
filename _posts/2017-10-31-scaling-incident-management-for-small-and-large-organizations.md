---
layout: post
title: Scaling incident management for small and large organizations
category: engineering
tags:
 - process
 - tips
year: 2017
month: 10
day: 21
published: true
type: markdown
---

* TOC
{:toc}

# Introduction

This write-up is a way of managing incidents and outages (there are many other
ways).  An incident or outage can be anything which negatively affects
productivity or costs a company's revenue.  Such as a website being down.  I
will mainly be discussing the process and not tools.  I will assume the
following tools are available.

- An [issue tracker][tool-its] (typically used to track work in an
  organization).

- Communication channels (typically instant messaging chat or email mailing
  lists).  Whatever the norms are for an organization to communicate internally
  to employees and externally to customers.  Collaboration tools fall under this
  category.

Coordinating incident management may not always be straightforward for young
organizations.  In my experience, I've been a part of good incident management
and also participated in bad incident management.  This post is about some of my
highlights for incident management.  Here are some points to think about:

- Teams within an organization should work together to help speed the resolution
  of an outage and help take stress off of the individual who is resolving the
  outage.

- Assign roles to different people so that they can work asynchronous to each
  other where possible.

- Adhere to the duties of the role.  Concentration and focus can quickly and
  easily be taken away from resolving an incident.  It helps to define roles,
  assign roles, and when a person is assigned a role they avoid going outside of
  their boundaries to help maintain focus to a speedy resolution.

# Defining roles

Here are some ideas for roles which can operate independently by different
people.  **Note:** some people can take on multiple roles where it makes sense
or based on the size of the team.  The idea here is to scale these roles out to
even major outages.  Each role does not necessarily need to be comprised of
people from the same team.

- `Incident Lead` - Defines communication channels and engages stakeholders for
  appropriate action and updates.  Also assigns roles when needed.

- `Technical Lead` - The person leading the charge on fixing the problem.
  They're in the terminal, looking at any logs, and actively resolving the
  outage.

- `Technical Assist` - A support role and backup for the `Technical Lead`.
  Supports troubleshooting by assisting the `Technical Lead` when asked to do
  things.  Perhaps, troubleshooting a different route than the `Technical Lead`
  without adversely affecting their efforts.

- `Scribe` - Keeps minute notes for ongoing events and tags a timestamp with
  each event so that a timeline of events is documented.

- `Communication Lead` - Fields all end user questions in chat channels and
  email.  Summarizes regular status and updates to users every 30-60 minutes and
  communicates the news to users via a pre-determined communication channel.

- `Testers` - Tests and validates solutions.  Runs tests and gathers feedback
  when requested by the `Technical Lead` or `Technical Assist`.  These should be
  separate people than the `Technical` roles because they have a fresh mind when
  approaching and validating the problem.

# Duties by role

### Incident Lead

The `Incident Lead` helps coordinate and organize the overall effort for
managing the incident.  Duties for the `Incident Lead` include:

- Opens an incident issue if one doesn't already exist.  Classifies and
  identifies the priority of the incident depending on who is blocked and how.
  Add issue tags and links to related issues.  Creates a shared chat channel
  where different team roles can get updates and collaborate.

- Identifies stakeholders and engages them.  Stakeholders being people involved
  with or affected by the issue.  Once stakeholders are identified, then
  communication channels can be agreed on.

- Defines communication channels.  Open video conference meetings when necessary
  to communicate with higher ups or encourages pairing sessions where
  appropriate between other roles.  Decides on the main point of contact channel
  for regular information updates by the `Scribe` to affected stakeholders. For
  example, a mailing list or a specific chat channel.

- There should only be one main point of contact channel and all other places
  the initial incident is announced should be directed to that main point of
  contact channel for status updates.

- If the team hasn't organized into roles, then the `Incident Lead` should help
  with this transition.  Ask the team who wants to be in what role or start
  assigning people to the role for them to perform the duties of that role.

- When all appropriate roles have been assigned to people the `Incident Lead`
  documents this in the incident ticket (perhaps with a table).

### Technical Lead

Duties for the `Technical Lead` include:

- Reviews logs related to the outage.

- Discusses with `Technical Assist` or other Engineers to help form a better
  picture of the outage.

- Engages the `Technical Assist` to run off and troubleshoot or perform
  asynchronous technical tasks outside of what the `Technical Lead` is working
  on where it makes sense to parallelize on work.

- Drafts a solution to the outage with the `Technical Assist` based on
  information gathered.

- Implementor for the fix to the outage.

### Technical Assist

Duties for the `Technical Assist` include:

- Reviews logs related to the outage.

- Discusses findings with the `Technical Lead`.

- When requested, performs tasks assigned by the `Technical Lead`.  If the
  `Technical Assist` cannot directly perform the assigned task, then it is the
  responsibility of the `Technical Assist` to coordinate with other people.
  This is important because it allows the `Technical Lead` to focus on their
  issue at hand.

- For large teams, the `Technical Assist` is in charge of coordinating multiple
  people who would assist in tasks assigned by the `Technical Lead` or
  `Technical Assist`.

- Ask the `Technical Lead` to bring them up to speed where necessary so they can
  continue to provide support and aide.

- Communicates with the `Scribe` any updates when requested or even as events
  unfold.  The `Technical Lead` should not be bothered with requests for status
  updates where possible.

### Scribe

Duties for the `Scribe` include:

- Keeps a timeline of notable events both internal and external to the team.
  Basically, lurk on the conversation between all roles in the team as well as
  pay attention to events outside of the team.

- Notable events should be recorded with a timestamp of roughly when the notable
  event occurred.  This does not have to be exact, but reasonably accurate.

- At the end of the outage, the `Scribe` should draft a "Summary Timeline" of
  events only noting the most major and relative events of the outage.

- If no notable events have been reported by the `Technical Lead` or `Technical
  Assist` within 30-60 minutes then the `Script` should actively ask the
  `Technical Assist` for a status update.

- The `Scribe` communicates to the `Communication Lead` roles and updates them
  of notable events (or to state that there is no update since the last known
  update).

- Based on the timeline of events, the `Scribe` should calculate some statistics
  for the incident.  This helps the team measure their success when handling
  incidents.  In the future, these metrics can help define a service level
  agreement for a service as well.  Some recommended statistics:

  - If known, the total time between when an outage first occurred until when
    the outage was _discovered_.  Also loosely known as the [mean time to
    detect][MTTD].

  - If known, total time when the outage first occurred until when the outage
    was resolved.

  - Total time when the outage was _discovered_ until when the outage was
    resolved.  Also loosely known as the [mean time to resolution][MTTR].

- The `Scribe` must post in the incident ticket a comment including the
  following.  A single comment is all that is needed.

  - Statistics for the outage.

  - A summary of the timeline of events (overview).

  - A full timeline of events.

### Communication Lead

The `Communication Lead` can be more than one person depending on the
stakeholders of an outage identified by the `Incident Lead`.  This is mainly
because there may be different audiences, which need to be updated regularly.
Audiences may include:

- Customers or users internal to the company.

- Customers or users external to the company.

- Upper management.

Duties for the `Communication Lead` include:

- Do not communicate status updates more frequently than every 30 minutes.
  However, if there has been no communication to audiences within 60 minutes,
  then an update **should** be communicated.

- When ready to communicate, the `Communication Lead` should reach out to the
  `Scribe` for the latest timeline of events, updates, and status relating to
  the ongoing incident since they last communicated to audiences.

- Rather than communicating the timeline from the `Scribe` literally, the
  `Communication Lead` should massage the information from the `Scribe` and
  draft an appropriate message for the intended audience.

- The `Communication Lead` should keep notes on when they communicate with
  audiences (a timestamp), what was said to the audience (a quote), and where
  the message was communicated (the channels used to field the communication).
  This will collectively be referred to as the timeline of communications.

- When the incident is over, the `Communication Lead` should post a single
  comment on the incident issue the noting the timeline of communications.  This
  is necessary because it serves as a reference in the incident.  If the
  communication is too large to post as a single comment, then a separate
  "communication issue" should be created; the communication issue linked to the
  incident issue; and commented on the incident issue that the linked issue is
  for documenting the timeline of communications.

# Managing an incident

A typical oversimplified timeline for an incident goes like this:

1. An outage occurs or something which blocks people from working (or users from
   using).

2. There is a delay between the outage occurring and somebody noticing there's a
   problem.  This may be an automated monitoring alarm going off or, in the
   worst case, a user reports the issue.

3. Some troubleshooting occurs to discover a fix for the outage.

4. The outage is resolved by implementing the fix.

While all of the above is going on, different audiences want to know what is
going on depending on how they're affected by the outage.  Imagine trying to
address the above timeline while also juggling the following:

- People will ask for status updates.  The longer an outage occurs, the more
  noisy audiences will be about wanting to know what is going on and staying
  updated.

- Some people will want to know the root cause of the outage and ask about it.
  This root cause may not be directly related or relevant to implementing a fix
  for the outage.

- Other people will want to help but don't know how to contribute so they ask
  the person working on the outage.

All of the above points serve to distract and slow down resolving an incident.
Which, prolongs the pain and stress felt by the individual who is working on a
fix.  It also prolongs the pain and stress felt by the audiences who are
adversely affected by the outage.

### Recommended process for managing an incident

When an incident is discovered the following **should** occur simultaneously:

- An `Incident Lead` should be identified and engaged.  The `Incident Lead` then
  takes over to help perform their assigned duties (such as assigning roles to
  other people).  Usually the `Technical Lead` is engaged first when they're the
  author, but they should immediately delegate to someone else being the
  `Incident Lead` so they can start focusing on a resolution.

- The technical roles (`Technical Lead`, `Technical Assist`, and anyone
  coordinated by the `Technical Assist`) should work on the actual incident.
  Their focus should only be on resolving the incident as quickly as possible.
  It is the job of the other roles to remove outside distractions.

- The `Scribe` lurks on the conversation of the other roles and performs their
  note taking duties.  If necessary, the `Scribe` may engage the `Technical
  Assist`.

- The `Communication Lead` handles internal and external communication to
  different audiences.  They should only engage the `Scribe` for updates and
  status because they are recording noteworthy events.

At the end of the outage, the `Testers` are engaged to validate an outage is
truly over and help bring a fresh perspective.  This fresh perspective is
important because they are less likely to make mistakes when validating since
they weren't directly involved with the implementation of fixing the outage.

# After an incident concludes

After an incident is resolved, teams usually meet to discuss (not always the
same day) the summarized timeline of events recorded by the `Scribe`.
Evaluating events after an incident or outage is typically what is called a
"postmortem review" in IT.  The purpose of discussing this is to bring involved
parties together to understand the following:

- The root cause of the problem.

- Attempt to come up with actionable feedback (also called action items) in
  which a team or organization can help prevent an outage for the same reason
  from occurring in the future.

- Reviewing how the incident was handled via process.  This is an opportunity to
  reflect and improve how incidents are managed going forward.  Incident
  management can be refined over time as a team learns to work together on
  incidents.

# Summary

By defining roles and assigning people to different duties the stress of
managing an incident can be less of a burden on a single individual.  It helps
to balance the stress across multiple people so that a team can stay focused on
resolving problems which block other people (like customers).  Down time can
affect organization reputation, customer confidence, engineering productivity,
and can even be translated into cost for such losses (lost money).

It makes sense to try to formalize an organizational process (and even within a
team) to resolve incidents as quickly as possible.  Hopefully, I've helped your
team or company get better at incident management if you decide to incorporate
some of these ideas.

[MTTD]: http://kpilibrary.com/kpis/mean-time-to-detect-mttd-2
[MTTR]: https://www.metricnet.com/mean-time-to-resolve/
[tool-its]: https://en.wikipedia.org/wiki/Issue_tracking_system
