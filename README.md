# GitHub Classroom
[![Build Status](https://travis-ci.org/education/classroom.svg?branch=master)](https://travis-ci.org/education/classroom) [![Code Climate](https://codeclimate.com/github/education/classroom/badges/gpa.svg)](https://codeclimate.com/github/education/classroom)

## Table of Contents

- [The workflow you use as a developer, scaled for the needs of students.](#the-workflow-you-use-as-a-developer-scaled-for-the-needs-of-students)
- [Why try Classroom?](#why-try-classroom)
- [Design principles](#design-principles)
- [GitHub Classroom and the edtech ecosystem](#github-classroom-and-the-edtech-ecosystem)
- [The technical details](#the-technical-details)
- [Deployment](#deployment)
- [Help wanted](#help-wanted)
- [Contributors](#contributors)

## The workflow you use as a developer, scaled for the needs of students.

Developers rarely work all by themselves, on a deadline, or ship something they’ll only use once (with no idea whether it actually works).

Wouldn’t students be better served by showing versions of their work, iterating, checking in on milestones and showing off the final product?

With GitHub Classroom you can set up the industry-standard workflow and free up your time to focus on teaching.

*Classroom is a teacher-facing tool that uses the GitHub API to enable the GitHub workflow for education.*

You create an Assignment with starter code and directions, send along one link, and students get their own “sandbox” copy of the repo to get started.

Set due dates, track assignments in your teacher dashboard, or integrate other tools like testing frameworks.

With Classroom, you can spin up your course on GitHub and move on to the good stuff.

[@johndbritton](https://github.com/johndbritton), [@mozzadrella](https://github.com/mozzadrella), [@d12](https://github.com/d12), and [@tarebyte](https://github.com/tarebyte), are all maintainers.

![GitHub Classroom screenshot](https://cloud.githubusercontent.com/assets/1311594/14748352/32f677b0-0887-11e6-9ac2-8aa06e4341fa.png)

## Why try Classroom?

*Spend more time with students, less on setup.* Students accept an assignment with one link, so you can get straight to the material.

*Bootstrap group assignments in a snap.* Invite students to a shared repository, and cap the number of students per group. Use the same groups over and over again, or create new ones.

*More insight into student work than ever before.* See when students accept the assignment, and access their work from the moment they start. With version control, catch when they get stuck and help them rewind.

*You are in control.* Students can work individually or in groups, in public or in private. Invite teaching assistants or graders to view the assignments.

*Scales for large courses with ease.* If you have a small course, Classroom will make your life easier and save you time. If you have hundreds of students, we have you covered: as many repositories as you need, and webhooks to integrate automated testing tools.

*Works with your Learning Management System (LMS).* Students submit a link to their assignment repository to your learning management system. Give feedback through comments in GitHub, but keep grades in your LMS.

*You’re not alone.* The experts on the GitHub Education team are here to answer any of your questions, and we’ve got [docs](https://github.com/education/classroom/tree/master/docs), best practices, and a strong community of educators to help you migrate to Classroom.

*Are you super-advanced?* Do you want to build your own tools? We 💖 contributions. Please check out [contributing guidelines](CONTRIBUTING.md).

## Design principles

*Classroom is a teacher-facing tool to simplify the educational use of GitHub.* Every student needs feedback and support as they learn to code, and using GitHub you can give them the right advice, in the right place, at the right time. Classroom makes it easier to use the workflow you love, with some automation and ease for student use.

*Students use GitHub. They don’t use Classroom.* Experience with real-world tools gives students a leg-up once they move on from school. Invest time in the tools students can grow with, not another third-party tool with its own learning curve.

*Classroom is not an LMS (Learning Management System).* If you need to use an LMS like Canvas, Moodle or Blackboard, we hear you. Students can post their repositories to your LMS. We’re going to stick with what we’re good at, which is helping people collaborate on code.

*Classroom is open source.* Git and GitHub are versatile with many ways to meet your learning goals, and we want to model the open source process that makes our communities great.

We welcome contributions aligned with the roadmap below and through answering these questions:

* Does it enable the real-life experience of using GitHub as a developer?
* Does it replicate functionality that's best left to the expertise of content platforms, hardware or LMS?
* How many support tickets and questions will the feature address?

### Who is Classroom for?
Anyone teaching computer science in a high school, university or informal environment.
Folks who might also find Classroom useful:
* Higher ed statistics and data science teachers
* Higher ed biology and the hard sciences

## GitHub Classroom and the edtech ecosystem

In case you’re wondering “How does Classroom interact with my favorite app/my notebook/my LMS” here’s the tl;dr on how those pieces fit together:

*Apps and content platforms*

Examples: Codecademy, Skillshare, Udemy, Udacity

Apps offer premium content and interactive exercises. GitHub Classroom offers *real-world experience* with code. Classroom, as a teacher-facing application will eventually surface best-in-class content for top courses (notes / lectures / problem sets) but not produce original content.

*Learning Management system/LMS*

Examples: Blackboard, Moodle, Canvas. Google Classroom

Teachers often use a learning management system in keeping with student privacy regulations. Classroom has a lightweight integration with LMS ecosystem--students can submit a link to their repositories. LTI compliance and Google Classroom integration will make the app more extensible.

*Notebooks*

Examples: BlueJ, Jupyter, RStudio

Most notebooks have a Git integration that students can push to. Future iterations may pre-populate repos with robust directions on set up.

*Hardware*

Examples: Chromebooks, Raspberry Pi, Lego

GitHub Classroom runs in Unix environments and Windows. Shared machines or lab environments are encouraged to use cloud-based environments, like Cloud 9. Integration looks like Git and GitHub pre-loaded + embedded in hardware.

*Assessment*

Examples: Pearson, Travis CI, Circle CI

For GitHub Classroom, assessment is **directly related to the real-world experience of being a developer: your code passes tests**. Configuring folders in student repositories is a priority on the roadmap.

## The technical details
GitHub Classroom is a [Ruby on Rails](http://rubyonrails.org/) application.

New to Ruby? No worries! You can follow these instructions to install a local server.

#### macOS

If you're using macOS and running the Homebrew package manager you're all set to go! Head down to [Setup Classroom](#setup-github-classroom)

#### Linux

##### Installing Docker and Docker Compose

We use Docker and docker-compose so that we don't have to setup our external dependencies on our machines.

Here is the installation guide for Ubuntu: https://docs.docker.com/install/linux/docker-ce/ubuntu/

##### Installing Rbenv

First things first, you'll need to install Ruby. We recommend using the excellent [rbenv](https://github.com/sstephenson/rbenv), and [ruby-build](https://github.com/sstephenson/ruby-build).

##### Install PostgreSQL

In order to install the `pg` gem you have to have PostgreSQL on your system, all you need to do is install it via your package manager of choice.

If you're running an Debian/Ubuntu based GNU/Linux for example run: `apt-get install nodejs postgresql redis-server memcached`.

#### Windows

We really don't have a good story for running this on Windows, but Pull Requests are welcome :smile:

### Setup GitHub Classroom

We follow the [script to rule them all](https://github.com/github/scripts-to-rule-them-all) principle, so all you need to do is run:

```
script/setup
```

Once that's done the script will kindly remind you to fill out you `.env` file inside the repository, this is the breakdown.

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

#### Optional
If you'd like to receive webhooks from GitHub you can run:

```bash
script/ngrok
```

And update the `WEBHOOK_URL` in your .env file.

And if you want to play with features that are still in development run:

``
./bin/rake enable_features
``

#### Necessary
After that, you may start the rails server in a separate terminal with:

```bash
script/server
```

Aaand that's it! You should have a working instance of GitHub Classroom located [here](http://localhost:5000)

## Deployment
We strongly encourage you to use [https://classroom.github.com](https://classroom.github.com), but if you would like your own version GitHub Classroom can be easily deployed to Heroku.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

There are a few environment variables you will need to know in order to get Classroom working on production.

### Production environment variables

ENV Variable | Description |
:-------------------|:-----------------|
`AIRBRAKE_PROJECT_ID` | the ID for application in airbrake.io, if set Airbrake will be enabled
`AIRBRAKE_PROJECT_KEY` | the PROJECT_KEY in airbrake.io, if set Airbrake will be enabled
`CANONICAL_HOST` | the preferred hostname for the application, if set requests served on other hostnames will be redirected
`GOOGLE_ANALYTICS_TRACKING_ID` | identifier for Google Analytics in the format `UA-.*`
`PINGLISH_ENABLED` | Enable the `/_ping` endpoint with relevant health checks
`MOTD` | Show the message of the day banner at the top of the site

## Help wanted
If you're interested in helping out with Classroom development and looking for a place to get started, check out the issues labeled [`help-wanted`](https://github.com/education/classroom/issues?q=is%3Aissue+is%3Aopen+label%3A%22%3Ahand%3A+help-wanted%22) and feel free to ask any questions you have before diving into the code.

## Contributors
Classroom is developed by these [contributors](https://github.com/education/classroom/graphs/contributors).

Shout out to [GitHub Summer of Code](https://github.com/blog/1970-students-work-on-open-source-with-github-this-summer) student, [Mark Tareshawty](http://marktareshawty.com), from [The Ohio State University](https://www.osu.edu/) for his work on GitHub Classroom.
