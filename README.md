# USAGE-Linux-CIS-341
USAGE application project for Linux and CIS 341 (System Administration)

```text
USAGE-daemon/
├── config
│   ├── sysaudit.cfg                     # Default configuration file
│   └── sysaudit.cfg.example             # Fully documented template
├── cron/                              # Automated cron jobs related to the system
├── deploy/                            # The "installation" folder that contains set up scripts.
│   └── install.sh                     # Automated deploy script creating dirs & users, "run once" philosophy
|                                      # Potentially more files relating to user set up due to our modular assignment of responsibility
├── docs/                              # "Presentation"/Docs
│   ├── ARCHITECTURE.?                 # Component diagrams, data flow, pipeline maps
│   ├── BOTTLENECKS.?                  # Performance profiling & optimization analysis
│   ├── PRESENTATION.?                 # Final presentation slide deck
│   └── screenshots/                   # Verification proofs, test runs, CLI traces
├── src/                               # USAGE engine main.sh and other files
├── systemd/                           # Systemd.service and .timer files if we do not use cron to run the automated jobs
├── tests/                             # Testing suites within
├── .gitignore                         # Add any undesired files here, they will be excluded from upload
├── Makefile                           # If necessary / desired
└── README.md                          # Quickstart, project overview
```

## TO GROUP MEMBERS

### Setting up github with ssh so you don't have to log-in

To generate an ssh-key on the system you're working on (these instructions are for linux):

```ssh-keygen -t ed25519 -C "your_email@example.com"```

This command generates an ed25519 flavour ssh-key with the email as a comment. Change "your_email" to literally anything, I usually label mine [VM-NAME]-GHKEY, but emails are standard. It's just for you.

```cat ~/.ssh/id_ed25519.pub```

Cat the key to get the full string, and copy it.

Go to your [Github SSH Key settings](https://github.com/settings/keys), add a new key, and paste in the text from your terminal to the 'key' box. Now you don't have to log-in every time.

#### I know you've all heard that part from professors, so the next steps are probably more useful.

Make sure you clone the repository using the SSH clone link!! git@github.com:Gredrah/USAGE-Linux-CIS-341.git

```bash
git clone git@github.com:Gredrah/USAGE-Linux-CIS-341.git
cd USAGE-Linux-CIS-341
```

By cloning it directly from github, you don't have to configure an upstream url. All you have to do is run the standard ```git push``` or ```git pull``` commands within the repo to update your branch.

### The Daily Git Workflow (Feature Branching)

To keep our code organized and avoid breaking the `main` branch, we are using feature branches. Here is your daily workflow whenever you sit down to work:

Always start by making sure your local `main` branch is synced with the repository:
```bash
git checkout main
git pull origin main
```

#### Switch to Your Feature Branch
If you are creating your branch for the very first time, use -b to create and switch to it:
```
git checkout -b feature/your-feature-name
```
If you already created it previously, just switch to it without the -b:
```
git checkout feature/your-feature-name
```

#### Write Code and Commit
Write your code, test it locally, and save your files. When you have a working chunk of code, stage and commit it:

```
git add .
git commit -m "Added the configuration parser logic"
```
(1: Make frequent, small commits at stages you know the code compiles. It makes it much easier to track down bugs later, and sync your branch at a good state.)

(2: ```Git add .``` is the equivalent of selecting the "plus" or adding a file to be included in the commit. Use . to add the local directory, or the filename for a specific file)

#### Setting your user and email
Before you make a commit, command-line git wants to know who you are. For our purposes in a private repo, this would be fine to use a regular email and name. However, best practice is to not release these publicly on the internet.

My paranoid self likes to do things the safe way, by using my github username as my commit name, and setting my email to my github private email address.

You can locate your github email address under Settings > Emails and looking for the private email address in the bottom box. I've provided a screenshot.

<img width="947" height="165" alt="image" src="https://github.com/user-attachments/assets/c03ee8b2-53cb-48e5-bb66-6ed3bd0a056f" />

Once you have the email, set your name and email as follows (**DO NOT COPY**, this includes my email and user as an example):
```
git config --global user.email "99298563+Gredrah@users.noreply.github.com"
git config --global user.name "Gredrah"
```
You only need to do this once per user per system.

#### Push Your Updates to GitHub
Send your committed code to the cloud. If this is the very first time pushing this branch, you need to set the upstream link. Every time after that, you're clear after checking out your specific branch to work on.

```
git push -u origin feature/your-feature-name
```
```
git push
```

#### Open a Pull Request (PR)
When a feature you're working on is at a stage you want it in the main branch:

    Go to our repository page on GitHub.

    You will see a yellow banner at the top saying you recently pushed a branch. Click Compare & pull request.

    Write a brief description of what you built.

    Click Create pull request.

Once your PR is open, the team can review the code, and we will merge it into main together.

#### Testing Environment
If you want a clean environment to test it in, you can use the lab machines I've configured at [guac.gredra.com](https://guac.gredra.com)

Sign in with your UFV email and you should have a free system I can reset anytime if anything goes wrong. Let me know if they aren't running and you need one.
