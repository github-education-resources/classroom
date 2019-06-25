## Controlling assignment repo settings with the Probot Settings app

You may want to provide default settings for your assignment repos. For example, you may want to turn off issues, predefine pull request labels, or protect a branch. When Classroom imports and copies your starter repo, it does not copy your repo's settings. Instead, use the Probot [Settings app](https://probot.github.io/apps/settings/).

[Probot](https://probot.github.io/) is a a project, a framework, and a collection of free apps to automate things on GitHub. Probot apps listen to repo events, like the creation of new commits, comments, and issues, and automatically does something in response. You can use [Probot apps created by the community](https://probot.github.io/apps/), such as the Settings app or [make your own](https://probot.github.io/docs/).

### Add the Settings app to your organization

Adding the Probot Settings app to your organization turns it on for any repo in the organization with a `.github/settings.yml` file, including student assignment repos created in the future. Here's how you set it up:

1. Add the Probot Settings app to the GitHub organization you use with Classroom. Go to [the Settings app page](https://github.com/apps/settings) and click **+ Add to GitHub**. When asked, make sure to give it access to all the repositories in the organization.

   <div class="d-flex flex-justify-around">
     <img src="/images/help/probot-settings.gif" class="border" style="width: 75%;">
   </div>

2. Add a `.github/settings.yml` file to your starter repo. See the [probot/settings README](https://github.com/probot/settings#github-settings) for a complete list of settings.

   **Warning:** Classroom automatically adds teachers and teaching assistants to repos. Avoid using the collaborators setting with Classroom.
   {: class="warning"}

3. Use a starter repo that contains a `.github/settings.yml` file when creating your assignment in GitHub Classroom.

### Learn more

* [Probot](https://probot.github.io/)
