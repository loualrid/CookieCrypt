## Cookie Crypt

## Encrypted Cookie Two Factor Authentication for Devise

## Features

* User customizable security questions and answers
* Configurable max login attempts & cookie expiration time
* Configurable authentication styles
* Per user level of control (Allow certain ips to bypass two-factor)

## Configuration

### Initial Setup

In a Rails environment, require the gem in your Gemfile:

    gem 'cookie_crypt'

Once that's done, run:

    bundle install


### Automatic installation

In order to add encrypted cookie two factor authorization to a model, run the command:

    bundle exec rails g cookie_crypt MODEL

Where MODEL is your model name (e.g. User or Admin). This generator will add `:cookie_cryptable` to your model
and create a migration in `db/migrate/`, which will add the required columns to your table.

### NOTE!

This will create a field called "username" on the table it is creating if that field does not already exist.
The fields are security_hash, security_cycle, agent_list, and cookie_crypt_attempts_count.

Having rails generate the files will also create views in the app/views/devise/cookie_crypt directory so you can
style your two-factor pages. If you like the default look of the views, feel free to delete these files and the gem
will serve the default ones.

Run the migration with:

    bundle exec rake db:migrate

With the 1.1 update, more steps are required. After following the above steps or upgrading from a previous version, run the command:

    bundle exec rails g cookie_crypt MODEL

On your model again to generate the 1.1 cleanup and migration files. After doing this run

    bundle exec rake db:migrate

This process will move your data (in a dev environment) from the old system to the new system.

### Production Updating from 1.0 to 1.1

Assuming all files are already on the production box, run

    bundle exec rake db:migrate:up

To go forward only to the next migration, then run

    bundle exec rails g cookie_crypt MODEL

On your model to export the security question and answer data to security_hash (nothing else will be added though it may notify you of conflicts).
Do not overwrite the conflicting migration file. Then run

    bundle exec rake db:migrate:up

Again to remove the old fields.

### Customization

By default encrypted cookie two factor authentication is enabled for each user, you can change it with this method in your User model:

```ruby
  def need_two_factor_authentication?(request)
    request.ip != '127.0.0.1'
  end
```

This will disable two factor authentication for local users and just put the code in the logs.

It is recommended to take a look at the source for the views, they are not complex but the default ones may not suit your design.

### Rationalle

Cookie Crypt uses a cookie stored on a user's machine to monitor their authentication status. The first time a user passes the initial login
they are passed to the cookie crypt controller which prevents further action. They are "logged in" in the devise sense, but have an additional hook
preventing them from performing any actions that arent in the cookie crypt controller until they bypass that auth. If this is first time they are going
through cookie_crypt, the user will be presented with several labeled text boxes asking them to input two security questions and two security answers.
After inputting this information they are authenticated and redirected to the root of the application but not given an auth cookie.

It is important to note that the security answers are not saved as plaintext in the database. They are encrypted and that output is matched against
whatever the user inputs for their answers in the future.

When the user attempts to login again, they will be shown their two security questions and asked to answer them with their two security answers.
If successful, an auth cookie is generated on the user's machine based on the user's username and encrypted password. The cookie is username - application
specific. No two cookies from different users should ever be the same if the username field is unique. After receiving their auth cookie, the user's user 
agent is logged and they are sent to the root of the system as fully authenticated. If the user was unsuccessful in authenticating 3 (or more) times, they
will be locked out until their cookie_crypt_attempts_count is reset to 0.

### Two Factor Defense

So a user now has an auth cookie and the server knows it gave an auth cookie to this user that possessed this user agent, what now? If that same user with
that same agent tries to login again, they will authenticate through cookie crypt auth without any work on their part. The server simply matches the value 
of their cookie with what it expects it should be. If they match AND the user agent the user is using is in the list of agents allocated to that user,
everything is square and they are authenticated. Using the [UserAgent](https://github.com/josh/useragent) gem, incremental updates in a user's user agent will not be treated as differing agents.
The system will log the attempt as successful and update the user's agent_list with the updated agent value.

But what if they're logging in through a different machine / browser? Then they input their security answers and are given a cookie for that agent.

But what if an attacker knows the user's username and password? The attacker must also know the user's security answers to auth as the user.

But what if an attacker knows the user's username and password AND has a copy of the user's cookie in their browser? Cookie crypt detects this case and
locks out the attacker by referencing the agent_list. A user that has a cookie but not a validated agent is obviously an attacker. This case also creates a
file in Rails.root / log to notify the admins of a hacking attempt. The agent_list field stores information given out by a browser's user agent and contains a
decent enough amount of data for fingerprinting. More could be done in this regard (testing to see what fonts/plugins a browser has) but is outside the scope
of this gem and would make it more difficult for the gem to be only a minor inconvienence to the users. 

What cookie crypt doesnt prevent:

* An attacker that knows a user's username and password thats logging in from the user's machine / browser.
* An attacker that knows a user's username and password thats also spoofing the user's agent and also has the user's same auth-cookie.
* An attacker that knows a user's username, password, security questions and answers to said questions.

Afterword: Spoofing a user agent is not that difficult, any modern browser with dev tools can change its user agent rather easily. The catch is that the values
need to match with what the user already has which requires additional work on the attacker's part. Also, The system recognizes updates to both the user's OS AND 
browser.


### Whats new with the 1.1 Update
* Reworked security questions and answers to allow for more customization options
* cookie_crypt_auth_through
** :one_question_cyclical
*** The default
*** Each user must answer only one of their questions at the end of a cookie cycle to authenticate.
*** The questions are chosen cyclically, the user will not answer the same question the next time they have to auth through two-factor
*** This prevents users logging in on a new machine from always being shown the same questions and is more secure
** :one_question_random
*** The user is shown a random question that was not their previous question every time they auth through two-factor, otherwise exactly like cyclical
** :two_questions_cyclical
*** Exactly like one_question_cyclical except two questions must be answered every auth
** :two_questions_random
*** Exactly like one_question_random except two questions must be answered every auth
** :all_questions
*** This option is not advised, but is available. It is the old functionality the system had.
*** The user must answer all authentication questions every auth session
* cookie_crypt_minimum_questions
** Default is 3
** Minimum number of questions and answers the user must enter into the system on their initial attempt
** Systems upgrading from 1.0 will prompt the user to add the difference in numbers of questions and answers
* cycle_question_on_fail_count
** Default is 2
** Minimum number of failed attempts before the question(s) is(are) cycled to the next question(s)
** Works in conjunction with max_cookie_crypt_login_attempts
* enable_custom_question_counts
** Default is false
** Allows users to have more than the minimum number of security question / answer pairs.