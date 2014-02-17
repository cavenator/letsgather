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
This project uses the following:
* Rails 3.2
* Ruby 1.9.3-p194
* PostgresSQL (for database)
* Devise (for authentication)
* DelayedJob (for asynchronous jobs)
* Unicorn (web server)

This project already contains a .rvmrc file which should automatically create your ruby workspace along with your project gemset but in the event it does not, look at the .rvmrc file.  It'll let you know what ruby version to download and which gemset to create.

For Mac
------------------------------------
1. If you do not have Xcode installed, then download from the Apple Mac Store.
2. Download (RVM)[http://rvm.io/rvm/install]
3. git clone this project
4. navigate to this project (if the rvm script doesn't install the ruby version and create the gemset space for you, then you will need to do so. Look (here)[http://rvm.io/rubies/installing] for installing rubies and (here)[http://rvm.io/gemsets/creating] for creating gemsets).
5. execute 'bundle install'. This should install all of the necessary gems for use (including postressql).
6. Then, navigate to config/initializers/devise.rb file and edit the following line:  config.mailer.sender
7. Then, navigate to config/environments/development.rb file and enter your email username/password so that the emails will work. (NOTE: You will have to change your config/environments/production.rb file if you decide to promote this to a production environment).
8. Execute 'bundle exec rake db:migrate' to update your database. I believe this is all you need to do but in case I am wrong, you will need to run a rake command to create the database first before running the migration.
9. Finally, execute 'bundle exec foreman start'. You should now be able to open up a web browser and navigate to 'http://localhost:5000'. Enjoy!

For Linux
------------------------------------
1. Follow the tutorial (here)[http://gorails.com/setup/ubuntu/13.10] for all of your necessities.
2. Git clone this project.
3. navigate to this project (if the rvm script doesn't install the ruby version and create the gemset space for you, then you will need to do so. Look (here)[http://rvm.io/rubies/installing] for installing rubies and (here)[http://rvm.io/gemsets/creating] for creating gemsets).
4. execute 'bundle install'. This should install all of the necessary gems for use (including postressql).
5. Then, navigate to config/initializers/devise.rb file and edit the following line:  config.mailer.sender
6. Then, navigate to config/environments/development.rb file and enter your email username/password so that the emails will work. (NOTE: You will have to change your config/environments/production.rb file if you decide to promote this to a production environment).
7. Execute 'bundle exec rake db:migrate' to update your database. I believe this is all you need to do but in case I am wrong, you will need to run a rake command to create the database first before running the migration.
8. Finally, execute 'bundle exec foreman start'. You should now be able to open up a web browser and navigate to 'http://localhost:5000'. Enjoy!

Caveats
===================

* The Javascript logic around the party items signup for guests is probably the biggest code smell of the application. This should be refactored to use BackboneJS since it would remove the duplication, be self-documenting and provide real value to the project.
* Not everything has tests. There is sufficient test coverage on the business logic regarding users and events and the basic authentication/authorization. 
* Qunit tests for the Javascript code should be created.
* The code used for the email templates are duplicated for all templates. I couldn't get the premailer gem to work for this.
* The guest RSVP page should be converted into a single page app.  Look at the screen mockups under the public/LET'S GATHER V6&7 and look at the invite_v06.html

Wishlist of user enhancements
=========================================================================

* Import the user's email contacts into the "Invite guests" textbox so that they can send invites just like they would via email
* Facebook integration (use Facebook credentials to log into the system and import friends)
* Readonly view of past events
* User should have a profile picture
* Themes
* Upload photo(s)

