# Classroom for GitHub
[![Build Status](https://travis-ci.org/education/classroom.svg?branch=master)](https://travis-ci.org/education/classroom)

> Your course assignments on GitHub

Classroom for GitHub is a [Ruby on Rails](http://rubyonrails.org/) application designed to automate repository creation and access control, making it easy to distribute starter code and collect assignments on GitHub

![Classroom for GitHub screenshot](https://cloud.githubusercontent.com/assets/123345/9819714/95b26b9c-58a7-11e5-99e9-d65996d53687.png)

## How it works

Classroom for Github automates repository creation and access control, making it easy to distribute starter code and collect assignments from students.

Assignments are the core of Classroom for GitHub. Teachers can easily create an assignment and distribute it to students using a private invitation URL. Optional starter code can be provided for individual or group work. It's even possible to delegate assignment creation and management to co-teachers and teaching assistants by adding them as organization administrators.
deploy

## Hacking on Classroom for GitHub

### Get started
New to Ruby? No worries! You can follow these instructions to install a local server.

#### Installing a Local Server

First things first, you'll need to install Ruby 2.2.3. I recommend using the excellent [rbenv](https://github.com/sstephenson/rbenv),
and [ruby-build](https://github.com/sstephenson/ruby-build)

```bash
rbenv install 2.2.3
rbenv global 2.2.3
```

Next, you'll need to make sure that you have PostgreSQL, Redis, and Memcached installed. This can be
done easily on OSX using [Homebrew](http://brew.sh)

```bash
brew install postgres redis memcached
```

Now, let's install the gems from the `Gemfile` ("Gems" are synonymous with libraries in other
languages).

```bash
gem install bundler && rbenv rehash
```

### Setup the Classroom for GitHub
Once bundler is installed go ahead and run the setup script
```
script/setup
```

### Development environment variables
We use [dotenv](https://github.com/bkeepers/dotenv) for setting our environment variables. These values need to filled in in you `.env` file (which was created by the `setup` script.

ENV Variable | Description |
:-------------------|:-----------------|
`GITHUB_CLIENT_ID`| the GitHub.com Application Client ID..
`GITHUB_CLIENT_SECRET`| the GitHub.com Application Client Secret..
`NON_STAFF_GITHUB_ADMIN_IDS` | GitHub IDs of non GitHub staff members that have staff access.

### Testing environment variables

ENV Variable | Description |
:-------------------|:-----------------|
`CLASSROOM_OWNER_ID` | The GitHub user ID of an organization admin.
`CLASSROOM_OWNER_GITHUB_TOKEN` | The [Personal Access Token](https://github.com/blog/1509-personal-api-tokens) for the owner ID
`CLASSROOM_STUDENT_ID` | Test OAuth application client ID.
`CLASSROOM_STUDENT_GITHUB_TOKEN` | The [Personal Access Token](https://github.com/blog/1509-personal-api-tokens) for the student ID
`CLASSROOM_OWNER_ORGANIZATION_ID` | GitHub ID (preferably one created specifically for testing against).
`CLASSROOM_OWNER_ORGANIZATION_LOGIN` | GitHub login (preferably one created specifically for testing against).

### Run the server

After you have everything configured all you need to do is run

```bash
script/server
```

And that's it! You should have a working instance of Classroom for GitHub located [here](http://localhost:3000)

## Deployment

We strongly encourage you to use [https://classroom.github.com](https://classroom.github.com), but if you would like your own version Classroom for GitHub can be easily deployed to Heroku.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Contributing
We'd love to have you participate. Please check out [contributing guidelines](CONTRIBUTING.md)

Shout out to [GitHub Summer of Code](https://github.com/blog/1970-students-work-on-open-source-with-github-this-summer) student, [Mark Tareshawty](http://marktareshawty.com), from [The Ohio State University](https://www.osu.edu/) for his work on Classroom for GitHub.
