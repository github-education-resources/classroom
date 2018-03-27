Like professional developers working together on code, students can use [GitHub Classroom](https://classroom.github.com/) to collaborate on group projects in a shared repository. In this post, we’ll walk you through how teachers can work with GitHub teams and use GitHub Classroom to create group exercises, assign teams, and reuse existing student teams.

### Before you begin
Before you create a group exercise, you’ll need the following:

- A GitHub organization [with a discount for private repositories](https://education.github.com/discount_requests/new) and access to GitHub Classroom

- An exercise (a repository that you have access to, which contains documentation, starter code, tests, or anything else your students need to begin work on an assignment)

- A list of students, or unique identifiers like their email addresses

### Get started
To get started, log in to [GitHub Classroom](https://classroom.github.com/), choose one of your classrooms, then click the **New assignment** button followed by **Create group assignment**. This brings you to the “New group assignment” page where you can provide the details of an assignment. If you don’t see your classroom listed, [double check that you’ve granted that organization access to GitHub Classroom](https://help.github.com/articles/approving-oauth-apps-for-your-organization/).

![a mouse cursor clicks on a GitHub Classroom classroom, then clicks the "New assignment button", then clicks the “Create group assignment” button, text begins to appear in the first text field. The animation loops from the beginning](https://user-images.githubusercontent.com/1874003/37045015-f8ea30f4-2132-11e8-90a9-e60fb8cd06c6.gif)

Then set up your group assignment just like you’d setup an individual assignment. Pick a name for your exercise, a starter repository to share, and a deadline.

### Create and use groups
When creating a new exercise, you can choose whether to reuse a set of groups from a previous assignment or name a set of new groups. If you’re reusing existing groups, then select a set of teams from the “Choose an existing set of groups” drop-down list.

If your students are going to form a new set of teams, enter a name for the set of teams in the “Create a new set of teams” field. It’s helpful to name your set of teams after their intended duration. For example, if you want to use a set of teams for one assignment, name it after that assignment. If you’d like to reuse a set of teams for a whole semester, name it after the semester or course.

When you’ve completed the form, click the “Create Assignment” button. Now it’s time to invite your students to the assignment.

### Form student groups
On the assignment page, you’ll find a unique invitation link. Share this link with your students through your learning management system, course homepage, or however you distribute assignments. Keep in mind that anyone with the link can use it, so be careful where you share it.

If you’re using a new set of groups for this exercise, and you’d like to assign students to specific group, give your students a list of people who should join each group, along with the group’s name.

Once your students have clicked the link, they may be asked to join a group (if you’re not reusing an existing set of groups). It looks like this:

![a mouse cursor clicks on an invite link for an assignment, a list of GitHub Classroom groups appears, the cursor clicks on the "Create a new groups" field, "Team 2" is entered into the text field, the cursor clicks the “Create groups” button, and the “You are ready to go!” page appears. The animation loops from the beginning](https://user-images.githubusercontent.com/1874003/37045016-f8fd099a-2132-11e8-9c24-060cc4125bf8.gif)

There are three common cases when organizing students into teams:

- There are no groups yet. The student will have to enter the name of a new group to create it
- There are one or more groups already formed. The student clicks on the existing group they want to join
- A student needs to create a new group. The student enters the name of a new group to create it

### Classroom groups and GitHub teams
When students join their group in Classroom, _[a team]_(https://help.github.com/articles/about-teams/) is created on GitHub.com in your GitHub organization. Teams have pretty nifty functionality, including threaded comments and emoji support.

If you create a team for your students on GitHub.com, that team will not appear in Classroom. If you’d like to use Classroom to distribute shared repositories, then use group assignments in Classroom, not teams on GitHub.com.

When you use group assignments in Classroom, each team of students will get access to one shared repository for the exercise. Every student will be able to push and pull to their team’s repository. We recommend assigning one student per team to act as project manager to resolve conflicts or merge pull requests. If your students are new to resolving conflicting changes, they can [check out our documentation](https://services.github.com/on-demand/merge-conflicts/) to learn to manage merge conflicts.

### Get deeper insight into group participation
Once your students are sorted into teams, they can start collaborating on the assignment like they would in any other repository: by pushing commits and branches, opening and reviewing pull requests, or using issues. Similarly, all of their commit history is available for you to review.

As students finish up their assignments, you can see the work they’ve done in two ways. Examine the current state of the files to see the finished product or look through the repository’s history to see how students worked together. GitHub’s “Insights” tab provides you with a picture of how your students worked together. For example, “Pulse” data gives you a timeline of your students’ pull requests, issues, and conversations, while “Contributors” graphs visualize your students’ additions and deletions.

Once students complete their projects, there are a few ways to deliver feedback, including:

- Going to the list of commits and making comments on individual commits
- Weighing in on a per-line basis (if students used pull requests)
- If you find that students make a similar error over and over, creating a canned reply and opening an issue directly from the plus sign (“+”) in the code view
If you chose to use private repositories for your assignment, your feedback will be confidential, so only you and the students in the group will see it.

### Create a group exercise
Ready to give a group assignment? [Get started right away in GitHub Classroom](https://classroom.github.com/). Or check out [this discussion in the GitHub Education Community](https://education.github.community/t/using-existing-teams-in-group-assignments/6999) on how student groups can work with GitHub teams in Classroom.
