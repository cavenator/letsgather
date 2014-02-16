letsgather
==========

This is my party planning app that I spent the majority of my free time on in 2013.  Its main goal is to allow hosts to easily create an invite, invite guests and to declare items (such as food, drinks, boardgames, chairs, eating utensils and so on) that are needed for the event while allowing guests to easily sign up for these items. 

Below are some of the advantages of the system:
*  Easily create items necessary for the party/event.
*  Session authentication for guests rsvping without needing to sign up for an account (like E-vite)
*  Registered guests (users with accounts who are guests to a party) can suggest items for the party and the host can approve/deny.
*  Host can promote registered users to help cohost and plan the event
*  Host can easily configure basic settings like "Notify me when guests accept/decline" as well as "Send out reminders X days from [RSVP]|[Start] Date"
*  Hosts have a dashboard view on how many items are left as well as the breakdown on items signed up for versus how many are requested to be brought.
*  Hosts can download/export the list of remaining items in a CSV format.
*  Guests can easily sign up for more than one item (or none at all) while specifying the quantity per item brought.
*  Both Hosts/Guests have filtered views to see who is coming, not coming, maybe or no response.


Scheduled jobs
====================

There are two scheduled jobs for LetsGather: One to send out RSVP reminders and the other for reminding guests of the party.  They can be executed using the following commands (I originally configured them to be run daily via Heroku Scheduler but you can use whatever is easiest for you):

*  rake scheduler:rsvp_reminders
*  rake scheduler:send_event_reminders

Installation instructions
====================================

TBD

Caveats
===================

Will define in greater detail later

Wishlist of user enhancements
=========================================================================

* Import the user's email contacts into the "Invite guests" textbox so that they can send invites just like they would via email
* Facebook integration (use Facebook credentials to log into the system and import friends)
* Readonly view of past events
* User should have a profile picture
* Themes
* Upload photo(s)

