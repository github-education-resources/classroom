# Classroom for GitHub
[![Build Status](https://travis-ci.org/education/classroom.svg?branch=master)](https://travis-ci.org/education/classroom)

> Your course assignments on GitHub

Classroom for GitHub is a [Ruby on Rails](http://rubyonrails.org/) application designed to automate repository creation and access control, making it easy to distribute starter code and collect assignments on GitHub

![Classroom for GitHub screenshot](https://cloud.githubusercontent.com/assets/123345/9819714/95b26b9c-58a7-11e5-99e9-d65996d53687.png)

## How it works

Classroom for Github automates repository creation and access control, making it easy to distribute starter code and collect assignments from students.

Assignments are the core of Classroom for GitHub. Teachers can easily create an assignment and distribute it to students using a private invitation URL. Optional starter code can be provided for individual or group work. It's even possible to delegate assignment creation and management to co-teachers and teaching assistants by adding them as organization administrators.
deploy

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Hacking on Classroom for GitHub
If you want to hack on Classroom for GitHub locally, we try to make bootstrapping the project as painless as possible. To start hacking, clone and run:
```
script/bootstrap
```

ENV Variable | Description |
:-------------------|:-----------------|
`GITHUB_CLIENT_ID`| GitHub login name (preferably one created specifically for testing against).
`GITHUB_CLIENT_SECRET`| Password for the test GitHub login.
`CLASSROOM_OWNER` | [Personal Access Token](https://github.com/blog/1509-personal-api-tokens) for the test GitHub login.
`CLASSROOM_OWNER_ID` | Test OAuth application client id.
`CLASSROOM_OWNER_GITHUB_TOKEN` | Test OAuth application client secret.
`CLASSROOM_STUDENT` | [Personal Access Token](https://github.com/blog/1509-personal-api-tokens) for the test GitHub login.
`CLASSROOM_STUDENT_ID` | Test OAuth application client id.
`CLASSROOM_STUDENT_GITHUB_TOKEN` | Test OAuth application client secret.
`CLASSROOM_MEMBER_ORGANIZATION` | Test OAuth application client secret.
`CLASSROOM_OWNER_ORGANIZATION` | Test OAuth application client secret.
`CLASSROOM_OWNER_ORGANIZATION_ID` | Test OAuth application client secret.
`NON_STAFF_GITHUB_ADMIN_IDS` | Test OAuth application client secret.

## Contributing
We'd love to have you participate. Please check out [contributing guidelines](CONTRIBUTING.md)

Shout out to [GitHub Summer of Code](https://github.com/blog/1970-students-work-on-open-source-with-github-this-summer) student, [Mark Tareshawty](http://marktareshawty.com), from [The Ohio State University](https://www.osu.edu/) for his work on Classroom for GitHub.
