# GitHub Classroom
[![Build Status](https://travis-ci.org/education/classroom.svg?branch=master)](https://travis-ci.org/education/classroom) [![Code Climate](https://codeclimate.com/github/education/classroom/badges/gpa.svg)](https://codeclimate.com/github/education/classroom)

GitHub Classroom is a [Ruby on Rails](http://rubyonrails.org/) application designed to automate repository creation and access control, making it easy for teachers to distribute starter code and collect assignments on GitHub

![GitHub Classroom screenshot](https://cloud.githubusercontent.com/assets/1311594/14748352/32f677b0-0887-11e6-9ac2-8aa06e4341fa.png)

## How it works

Assignments are the core of GitHub Classroom. Teachers can easily create an assignment and distribute it to students using a private invitation URL. Optional starter code can be provided for individual or group work. It's even possible to delegate assignment creation and management to co-teachers and teaching assistants by adding them as organization administrators.

## Hacking on GitHub Classroom

### Help wanted

If you're interested in helping out with Classroom development and looking for a place to get started, check out the issues labeled [`help-wanted`](https://github.com/education/classroom/issues?q=is%3Aissue+is%3Aopen+label%3Ahelp-wanted) and feel free to ask any questions you have before diving into the code.

### Get started
New to Ruby? No worries! You can follow these instructions to install a local server.

#### Installing a Local Server

First things first, you'll need to install Ruby 2.3.3. We recommend using the excellent [rbenv](https://github.com/sstephenson/rbenv),
and [ruby-build](https://github.com/sstephenson/ruby-build)

```bash
rbenv install 2.3.3
rbenv global 2.3.3
```

Next, you'll need to make sure that you have Nodejs, PostgreSQL, Redis, Memcached, and Elasticsearch installed. This can be done easily :
* For OSX using [Homebrew](http://brew.sh) : You don't have to do anything! When you run `script/setup` later on this will be taken care of for you.
* For Linux : `apt-get install nodejs postgresql redis-server memcached`. For Elasticsearch, follow the instructions on [their website](https://www.elastic.co/guide/en/elasticsearch/reference/current/install-elasticsearch.html).

You will want to set PostgreSQL to autostart at login via launchctl, if not already. See `brew info postgresql`. Redis and memcached may be setup similarly via launchctl or setup project wide by using foreman, described below.

Now, let's install the gems from the `Gemfile` ("Gems" are synonymous with libraries in other
languages).

```bash
gem install bundler && rbenv rehash
```

### Setup GitHub Classroom

If you are using Linux, configure PostgreSQL :

* Edit `/etc/postgresql/9.3/main/postgresql.conf` and uncomment `#unix_socket_permissions = 0777`
* Create a user and give him the rights to create a database : `su postgres -s /bin/bash -c "psql -c 'CREATE USER classroom_user; ALTER USER classroom_user CREATEDB'"` (Change `classroom_user` to the username that will run the classroom server)

Once bundler is installed (and PostgreSQL correctly configured for Linux users) go ahead and run the `setup` script :

```
script/setup
```

### Production environment variables
ENV Variable | Description |
:-------------------|:-----------------|
`AIRBRAKE_PROJECT_ID` | the ID for application in airbrake.io, if set Airbrake will be enabled
`AIRBRAKE_PROJECT_KEY` | the PROJECT_KEY in airbrake.io, if set Airbrake will be enabled
`CANONICAL_HOST` | the preferred hostname for the application, if set requests served on other hostnames will be redirected
`GOOGLE_ANALYTICS_TRACKING_ID` | identifier for Google Analytics in the format `UA-.*`
`PINGLISH_ENABLED` | Enable the `/_ping` endpoint with relevant health checks
`MOTD` | Show the message of the day banner at the top of the site

### Development environment variables
These values must be present in your `.env` file (created by `script/setup`).

ENV Variable | Description |
:-------------------|:-----------------|
`CLASSROOM_WEBHOOK_URL_PREFIX` | Ngrok url to receive webhooks (run `./script/ngrok`).
`GITHUB_CLIENT_ID`| the GitHub Application Client ID.
`GITHUB_CLIENT_SECRET`| the GitHub Application Client Secret.
`NON_STAFF_GITHUB_ADMIN_IDS` | GitHub `user_ids` of users to be granted staff level access.

To obtain your `GitHub Client ID/Secret` you need to [register a new OAuth application](https://github.com/settings/applications/new).

After you register your OAuth application, you should fill in the homepage url with `http://localhost:5000` and the authorization url with `http://localhost:5000/auth/github/callback`.

To obtain your GitHub User ID for the `NON_STAFF_GITHUB_ADMIN_IDS` field, go to `https://api.github.com/users/your_username`

### Testing environment variables
If you want to make a functionality change to the application you will need to write tests to accompany that change. In order to do this, the test values in the .env file must be filled in.

GitHub Classroom uses [VCR](https://github.com/vcr/vcr) for recording and playing back API fixtures during test runs. These cassettes (fixtures) are part of the Git project in the `spec/support/cassettes` folder. If you're not recording new cassettes you can run the specs with existing cassettes with:

```bash
script/test
```

GitHub Classroom uses environmental variables for storing credentials used in testing, these values are located in your `.env` file (created by `script/setup`).
If you are recording new cassettes, you need to make sure all of these values are present.

ENV Variable | Description |
:-------------------|:-----------------|
`TEST_CLASSROOM_OWNER_GITHUB_ID` | The GitHub `user_id` of an organization admin.
`TEST_CLASSROOM_OWNER_GITHUB_TOKEN` | The [Personal Access Token](https://github.com/blog/1509-personal-api-tokens) for the classroom owner
`TEST_CLASSROOM_STUDENT_GITHUB_ID` | Test OAuth application client ID.
`TEST_CLASSROOM_STUDENT_GITHUB_TOKEN` | The [Personal Access Token](https://github.com/blog/1509-personal-api-tokens) for the student
`TEST_CLASSROOM_OWNER_ORGANIZATION_GITHUB_ID` | GitHub ID (preferably one created specifically for testing against).
`TEST_CLASSROOM_OWNER_ORGANIZATION_GITHUB_LOGIN` | GitHub login (preferably one created specifically for testing against).

To obtain these values you will need:

* A teacher (your primary GitHub account)
* A student (another Github account, created for this purpose)
* An organisation that the teacher is an owner of, but the student does not belong to.

It is best if you create your own organization for testing purposes, if you have done so:

To obtain the `OWNER_GITHUB_ID` value, you can go to `https://api.github.com/users/organization_owner_username`.

To obtain the `OWNER_GITHUB_TOKEN` value, you will need to generate a [personal access token](https://github.com/blog/1509-personal-api-tokens).

To get the `STUDENT_GITHUB_ID` value you will need to create another user account on GitHub and get the ID by going to `https://api.github.com/users/student_username`

To get the `STUDENT_GITHUB_TOKEN` value you will need to generate another [personal access token](https://github.com/blog/1509-personal-api-tokens) for the student account.

To obtain the `OWNER_ORGANIZATION_GITHUB_ID/LOGIN` you can go to `https://api.github.com/orgs/organization_name`.

Now you should have all of the values filled in, great job!

### Running the application

Foreman is setup to manage redis, memcached, sidekiq, and elasticsearch in development mode. Postgresql must be running prior executing foreman.

After that, you may start the rails server in a separate terminal with:

```bash
script/server
```

And another terminal with:

```bash
script/ngrok
```

That's it! You should have a working instance of GitHub Classroom located [here](http://localhost:5000)

## Deployment

We strongly encourage you to use [https://classroom.github.com](https://classroom.github.com), but if you would like your own version GitHub Classroom can be easily deployed to Heroku.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Contributing
We'd love to have you participate. Please check out [contributing guidelines](CONTRIBUTING.md).

## Contributors
Classroom is developed by these [contributors](https://github.com/education/classroom/graphs/contributors).

Shout out to [GitHub Summer of Code](https://github.com/blog/1970-students-work-on-open-source-with-github-this-summer) student, [Mark Tareshawty](http://marktareshawty.com), from [The Ohio State University](https://www.osu.edu/) for his work on GitHub Classroom.
