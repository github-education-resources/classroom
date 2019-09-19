## Controlling assignment repository settings with the Probot Settings app

You may want to provide default settings for your assignment repositories. For example, you may want to turn off issues, predefine pull request labels, or protect a branch. When GitHub Classroom imports and copies your starter repository, it does not copy your repository's settings. Instead, use the Probot [Settings app](https://probot.github.io/apps/settings/).

[Probot](https://probot.github.io/) is a a project, a framework, and a collection of free apps to automate things on GitHub. Probot apps listen to repository events, like the creation of new commits, comments, and issues, and automatically does something in response. You can use [Probot apps created by the community](https://probot.github.io/apps/), such as the Settings app or [make your own](https://probot.github.io/docs/).

### Add the Settings app to your organization

Adding the Probot Settings app to your organization turns it on for any repository in the organization with a `.github/settings.yml` file, including student assignment repositories created in the future. Here's how you set it up:

1. Add the Probot Settings app to the GitHub organization you use with GitHub Classroom. Go to [the Settings app page](https://github.com/apps/settings) and click **+ Add to GitHub**. When asked, make sure to give it access to all the repositories in the organization.

![probot settings](/images/help/probot-settings.gif)


2. Add a `.github/settings.yml` file to your starter repository. See the [probot/settings README](https://github.com/probot/settings#github-settings) for a complete list of settings.

   **Warning:** GitHub Classroom automatically adds teachers and teaching assistants to repositories. Avoid using the collaborators setting with GitHub Classroom.
   {: class="warning"}

3. Use a starter repository that contains a `.github/settings.yml` file when creating your assignment in GitHub Classroom.

### Learn more

* [Probot](https://probot.github.io/)
