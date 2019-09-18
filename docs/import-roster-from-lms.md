## Importing a course roster from your Learning Management System

GitHub Classroom can automatically import your course roster from your institution's learning management
system to save you time when creating a GitHub Classroom course.

### Prerequisites

If you haven’t yet, [connect GitHub Classroom to you learning management system](/help/connect-to-lms) before proceeding.

Importing a course roster from your learning management system will only work if your learning management system's privacy settings allow GitHub Classroom to receive course roster information.

### Creating a new course roster

To import a new course roster from your learning management system:
![import roster](/images/help/lms/roster-import/import-roster.gif)  

1. [Sign in to GitHub Classroom](https://classroom.github.com/login).

2. Select the classroom you wish to import your roster into.

3. Navigate to _Classroom Settings_ within GitHub Classroom.

4. In the sidebar, select **Roster Management**. The _Add Students_ page will be displayed.

5. Click **Import from your learning management system**.

6. Select how to identify the imported students:

    - **User ID**: The Student ID as stored in your institution’s learning management system
    - **Names**: Student full names
    - **Emails**: Student emails

  **Note**: If you do not see the kind of identifier you want, you may have to enable GitHub Classroom to receive student name and email information in your learning management system’s privacy settings. See [troubleshooting](#troubleshooting) for more advice.
  {: class="flash"}

You have imported your roster into GitHub Classroom.

**Note**: If you encounter any errors, check to ensure you have enabled the roster membership service from within your learning management system. See [troubleshooting](#troubleshooting) for more advice.


### Syncing an existing course roster

After you've imported a roster, keep it up to date by syncing:
![Sync roster](/images/help/lms/roster-import/sync-roster.gif)  

1. [Sign in to GitHub Classroom](https://classroom.github.com/login).

2. Select the classroom you wish to import your roster into.

3. Navigate to _Classroom Settings_ within GitHub Classroom.

4. In the sidebar, select **Roster Management**. You are directed to your existing course roster.

5. Click **Sync from your Learning Management System**.

6. Select how to identify the imported students:

    - **User ID**: The Student ID as stored in your institution's learning management system
    - **Names**: Student full names
    - **Emails**: Student emails

    **Note:** If you do not see the kind of identifier you want, you may have to enable GitHub Classroom to receive student name and email information per your learning management system’s privacy settings. See [troubleshooting](#troubleshooting) for more advice.
    {: class="flash"}

Your roster is now up to date with your learning management system.

**Note:** If you encounter any errors, check to ensure you have enabled the roster membership service from within your learning management system. See [troubleshooting](#troubleshooting) for more advice.

### Troubleshooting

#### Unable to import students by name or email
If you’re trying to import students by their full name or email but only able to import by User ID, ensure you've enabled GitHub Classroom to retrieve student information from your learning management system. You may be able to change the privacy settings for GitHub Classroom within your learning management system by checking the configuration you set when [connecting GitHub Classroom to you learning management system](/help/connect-to-lms).

#### Roster import service is not enabled
If GitHub Classroom notifies you that it is unable to import students because it does not have access to the course roster on your learning management system, ensure you’ve configured GitHub to retrieve course membership information from your learning management system. You may be able to change the privacy settings for GitHub Classroom within your learning management system by inspecting the configuration you set when [connecting GitHub Classroom to you learning management system](/help/connect-to-lms).
