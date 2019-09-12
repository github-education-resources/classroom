## Using template repositories for your assignment starter code

Importing starter code for assignments is a very useful feature and with GitHub recently shipping the template repositories, we can leverage them in GitHub Classroom to make importing starter code much easier and faster!

### How to use template repositories for an assignment?

#### Before you begin
To use template repositories for assignments, you'll need the following:

* A classroom in GitHub Classroom
* An exercise repository that you have access to containing documentation, starter code, tests, or anything else your students need to begin work on an assignment.

#### Get started

Once you log in to [GitHub Classroom](https://classroom.github.com/), select your classroom and then click on **New Assignment**. Template repositories work for both **Individual Assignments** and **Group Assignments**. You can then provide details for the assignment. Once you've filled out the details, the **Optional** section has a search bar for finding your starter code repository. When you search for your starter code repository, you will now get two options:

  * Import starter code using a template repository.
  * Import starter code using source importer.

If you choose the first option, we will use your starter code repository as a template for generating the assignment for the students.

![Searches for repository, then selects the option of Importing starter code with template repositories](https://user-images.githubusercontent.com/3170078/62091261-ee69f900-b224-11e9-96ab-b4b34cce0001.gif)

Note: For import via template repositories to work, your starter code repository _must_ be a template repository. If you own the repository or have permissions, you can do it manually from the settings page of the repository on GitHub. If you do not own the repository, you can make a fork of it and then make it a template. More details [here](https://help.github.com/en/articles/creating-a-template-repository). We are in the process of automating this for you, and will post an update on this page soon!


### What are the advantages of using template repositories?

* Importing starter code is faster, as it uses the new [template repositories API](https://developer.github.com/v3/repos/#create-repository-using-a-repository-template).
* Template repositories are far more reliable than source imports.
* Template repositories are built with the aim of distribution and management of boilerplate code and hence releasing assignments is almost instantaneous.

### What do you miss out on when you use template repositories?

Template repositories do not copy the complete commit history, but instead start with a single commit. Because of that, you miss out on the following features:

* Reference to all the original tags in the repositories.
* Ability to push updates to the student repositories.

### Recommended option for your assignment

Template repositories are the best option in _most_ cases. You may not want to use it if:

* You plan on pushing updates to the starter code repository _after_ releasing the assignment.
* You care about the full commit history of the starter code repository.
* Your repository contains very large files (individual files greater than 10mb in size)

### Helpful links:
* [Creating a template repository](https://help.github.com/en/articles/creating-a-template-repository)
* [Creating a repository from a template](https://help.github.com/en/articles/creating-a-repository-from-a-template)
* [Generate new repositories with repository templates](https://github.blog/2019-06-06-generate-new-repositories-with-repository-templates)
