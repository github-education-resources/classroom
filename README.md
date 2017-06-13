# GitHub Classroom
[![Build Status](https://travis-ci.org/education/classroom.svg?branch=master)](https://travis-ci.org/education/classroom) [![Code Climate](https://codeclimate.com/github/education/classroom/badges/gpa.svg)](https://codeclimate.com/github/education/classroom) [![Dependency Status](https://dependencyci.com/github/education/classroom/badge)](https://dependencyci.com/github/education/classroom)


## The workflow you use as a developer, scaled for the needs of students. 

Developers rarely work all by themselves, on a deadline, or ship something they’ll only use once (with no idea whether it actually works). 
 
Wouldn’t students be better served by showing versions of their work, iterating, checking in on milestones and showing off the final product? 
 
With GitHub Classroom you can set up the industry-standard workflow and free up your time to focus on teaching. 
 
*Classroom is a teacher-facing tool that uses the GitHub API to enable the GitHub workflow for education.* 
 
You create an Assignment with starter code and directions, send along one link, and students get their own “sandbox” copy of the repo to get started.
 
Set due dates, track assignments in your teacher dashboard, or integrate other tools like testing frameworks. 
 
With Classroom, you can spin up your course on GitHub and move on to the good stuff. 
 
@johndbritton, @mozzadrella, @nwoodthorpe, @tarebyte, and @wilfriedE are all maintainers. 

![GitHub Classroom screenshot](https://cloud.githubusercontent.com/assets/1311594/14748352/32f677b0-0887-11e6-9ac2-8aa06e4341fa.png)

## Why try Classroom?
 
*Spend more time with students, less on setup.* Students accept an assignment with one link, so you can get straight to the material. 
 
*Bootstrap group assignments in a snap.* Invite students to a shared repository, and cap the number of students per group. Use the same groups over and over again, or create new ones.
 
*More insight into student work than ever before.* See when students accept the assignment, and access their work from the moment they start. With version control, catch when they get stuck and help them rewind. 
 
*You are in control.* Students can work individually or in groups, in public or in private. Set permissions for teaching assistants or graders. 
 
*Scales for large courses with ease.* If you have a small course, Classroom will make your life easier and save you time. f you have hundreds of students, we have your covered: as many repositories as you need, and webhooks to integrate automated testing tools. 
 
*Works with your Learning Management System (LMS).* Students submit a link to their assignment repository to your learning management system. Give feedback through comments in GitHub, but keep grades in your LMS.
 
*You’re not alone.* The experts on the GitHub Education team are here to answer any of your questions, and we’ve got docs, best practices, and a strong community of educators to help you migrate to Classroom.
 
*Are you super-advanced?* Do you want to build your own tools? We 💖 contributions. 

## Design principles

*Classroom is a teacher-facing tool to enable the educational use of GitHub.* Every student needs feedback and support as they learn to code, and using GitHub you can give them the right advice, in the right place, at the right time. This tool makes it easier for you to use the workflow you love, but with some organization, automation and ease with your students. 
 
*Students use GitHub. They don’t use Classroom.* Experience with real-world tools gives students a leg-up once they move on from school. Invest time in the tools students can grow with, not another third-party tool with its own learning curve. 
 
*Classroom is not an LMS (Learning Management System).* If you need to use an LMS like Canvas, Moodle or Blackboard, we hear you. Students can post their repositories to your LMS. We’re going to stick with what we’re good at, which is helping people collaborate on code. 
 
*Classroom is open source.* Git and GitHub are versatile with many ways to meet your learning goals, and we want to model the open source process that makes our communities great. 

We welcome contributions aligned with the roadmap below and through answering these questions: 
 
* Does it enable the real-life experience of using GitHub as a developer? 
* Does it replicate functionality of apps, hardware or LMS? 
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
Most notebooks have a Git integration that students can push to. Future iterations may pre-populate repos with directions on set up.
 
*Hardware*
Examples: Chromebooks, Raspberry Pi, Lego
GitHub Classroom is hardware-agnostic. Shared machines or lab environments are encouraged to use cloud-based environments, like Cloud 9. Integration looks like Git and GitHub pre-loaded + embedded in hardware. 
 
*Assessment*
Examples: Pearson, Travis CI, Circle CI
For GitHub Classroom, assessment is **directly related to the real-world experience of being a developer: your code passes tests**. Configuring folders in student repositories is a priority on the roadmap.

## The technical details
Want to squash bugs and help develop new features!? Check out or [technical documentation](docs/README.md).

## Deployment

We strongly encourage you to use [https://classroom.github.com](https://classroom.github.com), but if you would like your own version GitHub Classroom can be easily deployed to Heroku.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Contributing
If you're interested in helping out with Classroom development and looking for a place to get started, check out the issues labeled [`help-wanted`](https://github.com/education/classroom/issues?q=is%3Aissue+is%3Aopen+label%3Ahelp-wanted) and feel free to ask any questions you have before diving into the code.

We'd love to have you participate. Please check out [contributing guidelines](CONTRIBUTING.md).

## Contributors
Classroom is developed by these [contributors](https://github.com/education/classroom/graphs/contributors).

Shout out to [GitHub Summer of Code](https://github.com/blog/1970-students-work-on-open-source-with-github-this-summer) student, [Mark Tareshawty](http://marktareshawty.com), from [The Ohio State University](https://www.osu.edu/) for his work on GitHub Classroom.
