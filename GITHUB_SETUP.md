# Putting Downstack on GitHub

The editable project is ready to be a repository. Use the **contents of the source folder** as the repository root, with `project.godot`, `scripts`, `tests`, `assets` and this README at the top level. No game rewrite is needed.

The supplied ignore rules exclude Godot's generated cache, exported executables, local preferences and credentials. Keep the original assets, `.import` settings and `.uid` files. The project already includes its MIT license and third-party notices.

## First upload

1. Connect/sign in to the GitHub account that should own Downstack.
2. Create a repository named `downstack`, choosing private or public. Leave its README, license and ignore-template initialization off because these files are already supplied.
3. Add this source folder as the local project, commit it and push it to the repository.
4. Tag the tested version `v0.8.0`. Upload `Downstack_Windows_0.8.zip` as a Release asset so players can download the game; the source repository holds editable files.

With Git and GitHub CLI installed, the equivalent commands from the source folder are:

```text
git init -b main
git add .
git commit -m "Import Downstack 0.7"
gh auth login
gh repo create downstack --private --source=. --remote=origin --push
git tag v0.8.0
git push origin v0.8.0
```

The example creates a **private** repository in the authenticated account. Choose its owner and visibility before running it. If a repository named `downstack` already exists, use that repository's actual remote instead of creating another one. Configure your Git author name/email if Git requests them.

After upload, use branches/commits for changes and Releases for tested Windows downloads. The README documents local test and export commands. Automated GitHub Actions builds can be added later; no workflow or hosted repository was created as part of this download.

References: [GitHub repository quickstart](https://docs.github.com/en/repositories/creating-and-managing-repositories/quickstart-for-repositories), [GitHub CLI repository creation](https://cli.github.com/manual/gh_repo_create), [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases).
