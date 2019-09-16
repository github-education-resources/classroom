## Configuring GitHub Classroom with GitHub Enterprise

These steps will walk you through the process of configuring GitHub Classroom to work with GitHub Enterprise.

### Prerequisites

1. An up-to-date version of GitHub Enterprise
1. An admin user and admin permissions for your organization on GitHub Enterprise

### Step by step installation guide

1. Log into your GitHub Enterprise instance.
1. Next you’ll want to create a local version of GitHub Classroom. Go to the organization’s page, click `Settings` and then click `Oauth Apps` in the sidebar.

![enterprise Oauth](/images/help/enterprise/oauth.png)


#### Create the Classroom Enterprise application

1. Click **New OAuth App** in the top right
1. Set `Application name` to `Classroom Enterprise`
1. Set `Homepage URL` to the URL of your local GitHub Classroom installation
1. Set `Application description` to `GitHub Classroom for GitHub Enterprise`
1. Set `Authorization callback URL` to the URL of your local GitHub Classroom installation with `/auth/github/callback`
1. Click `Register application`


#### Configure the GitHub Classroom `.env`

Now that you have an OAuth Application registered in your GitHub Enterprise instance you want your local GitHub Classroom instance to use it. Go to the page for your newly created application and find the `Client ID` and `Client Secret`:
![enterprise secrets](/images/help/enterprise/secrets.png)

In your `.env` set the following:

```
GITHUB_ENTERPRISE_URL=https://<your-enterprise-hostname>
GITHUB_CLIENT_ID=<client_id_from_above>
GITHUB_CLIENT_SECRET=<client_secret_from_above>
```

You should be able to restart your local GitHub Classroom instance and register.
