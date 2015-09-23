# Classroom for GitHub
[![Build Status](https://travis-ci.org/education/classroom.svg?branch=master)](https://travis-ci.org/education/classroom)

Classroom for GitHub is a [Ruby on Rails](http://rubyonrails.org/) application designed to automate repository creation and access control, making it easy for teachers to distribute starter code and collect assignments on GitHub

![Classroom for GitHub screenshot](https://cloud.githubusercontent.com/assets/123345/9819714/95b26b9c-58a7-11e5-99e9-d65996d53687.png)

## How it works

Assignments are the core of Classroom for GitHub. Teachers can easily create an assignment and distribute it to students using a private invitation URL. Optional starter code can be provided for individual or group work. It's even possible to delegate assignment creation and management to co-teachers and teaching assistants by adding them as organization administrators.

## Hacking on Classroom for GitHub

### Get started
New to Ruby? No worries! You can follow these instructions to install a local server.

#### Installing a Local Server

First things first, you'll need to install Ruby 2.2.3. We recommend using the excellent [rbenv](https://github.com/sstephenson/rbenv),
and [ruby-build](https://github.com/sstephenson/ruby-build)

```bash
rbenv install 2.2.3
rbenv global 2.2.3
```

Next, you'll need to make sure that you have PostgreSQL, Redis, and Memcached installed. This can be
done easily on OSX using [Homebrew](http://brew.sh)

```bash
brew install postgresql redis memcached
```

You will want to set postgresql to autostart at login via launchctl, if not already. See `brew info postgresql`. Redis and memcached may be setup similarly via launchctl or setup project wide by using foreman, described below.

Now, let's install the gems from the `Gemfile` ("Gems" are synonymous with libraries in other
languages).

```bash
gem install bundler && rbenv rehash
```

### Setup Classroom for GitHub
Once bundler is installed go ahead and run the `setup` script
```
script/setup
```

### Development environment variables
These values must be present in your `.env` file (created by `script/setup`).

ENV Variable | Description |
:-------------------|:-----------------|
`GITHUB_CLIENT_ID`| the GitHub Application Client ID.
`GITHUB_CLIENT_SECRET`| the GitHub Application Client Secret.
`NON_STAFF_GITHUB_ADMIN_IDS` | GitHub `user_ids` of users to be granted staff level access.

### Testing environment variables
Classroom for GitHub uses [VCR](https://github.com/vcr/vcr) for recording and playing back API fixtures during test runs. These cassettes (fixtures) are part of the Git project in the `spec/support/cassettes` folder. If you're not recording new cassettes you can run the specs with existing cassettes with:

```bash
script/test
```

Classroom for GitHub uses environmental variables for storing credentials used in testing, these values are located in your `.env` file (created by `script/setup`).
If you are recording new cassettes, you need to make sure all of these values are present.

ENV Variable | Description |
:-------------------|:-----------------|
`TEST_CLASSROOM_OWNER_ID` | The GitHub `user_id` of an organization admin.
`TEST_CLASSROOM_OWNER_GITHUB_TOKEN` | The [Personal Access Token](https://github.com/blog/1509-personal-api-tokens) for the classroom owner
`TEST_CLASSROOM_STUDENT_ID` | Test OAuth application client ID.
`TEST_CLASSROOM_STUDENT_GITHUB_TOKEN` | The [Personal Access Token](https://github.com/blog/1509-personal-api-tokens) for the student
`TEST_CLASSROOM_OWNER_ORGANIZATION_ID` | GitHub ID (preferably one created specifically for testing against).
`TEST_CLASSROOM_OWNER_ORGANIZATION_LOGIN` | GitHub login (preferably one created specifically for testing against).

### Running the application

Foreman is setup to manage redis, memcached, and sidekiq in development mode. Postgresql must be running prior executing foreman. It assumes that redis and memcached are not already running on the system. Alternatively, you may run `script/sidekiq`, if you you to have redis and memcached always running system wide. To execute foreman, and this application's dependencies, run:

```bash
script/workers
```

After that, you may start the rails server in a seperate terminal with:

```bash
script/server
```

And that's it! You should have a working instance of Classroom for GitHub located [here](http://localhost:3000)

## Deployment

We strongly encourage you to use [https://classroom.github.com](https://classroom.github.com), but if you would like your own version Classroom for GitHub can be easily deployed to Heroku.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Contributing
We'd love to have you participate. Please check out [contributing guidelines](CONTRIBUTING.md).

## Contributors
Classroom is developed by these [contributors](https://github.com/education/classroom/graphs/contributors).

Shout out to [GitHub Summer of Code](https://github.com/blog/1970-students-work-on-open-source-with-github-this-summer) student, [Mark Tareshawty](http://marktareshawty.com), from [The Ohio State University](https://www.osu.edu/) for his work on Classroom for GitHub.
