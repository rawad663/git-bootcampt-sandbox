# CTServ Git Bootcamp — Sandbox

Five hands-on labs. Everything runs locally. Labs 1–4 need no network, no
GitHub account, and no permissions. Nothing outside this folder is ever
touched, so break things freely — that is the point.

## Setup (do this BEFORE the day, not on the day)

**Everyone**, whatever machine you are on, runs the labs in **bash**.


| Machine | How to get a bash prompt                                                                                       |
| ------- | -------------------------------------------------------------------------------------------------------------- |
| Windows | Install [Git for Windows](https://git-scm.com/download/win). Right-click this folder → **Open Git Bash here**. |
| macOS   | Terminal. If `git --version` prompts you, accept the developer tools install.                                  |
| Linux   | Terminal. `sudo apt install git` if needed.                                                                    |


Then:

```bash
cd path/to/git-bootcamp-sandbox
chmod +x bootcamp.sh
./bootcamp.sh doctor
```

`doctor` must come back all green before the session starts. If it does not, let a team-lead know.

## Using it

```bash
./bootcamp.sh start 1      # build lab 1 and print the brief
cd labs/lab1/client-portal # do the work here
./bootcamp.sh rules 1      # reread the brief without rebuilding the lab
./bootcamp.sh verify 1     # check yourself
./bootcamp.sh reset 1      # wipe it and start over, any time
```

`reset` is free and unlimited. If a lab gets into a state you do not understand, resetting and redoing it is a better use of five minutes than untangling it — the second run is where the learning sticks.

Lab 4 also has:

```bash
./bootcamp.sh teammate     # simulates a colleague pushing to origin
```



## The labs


| Lab | Topic                   | Ends when you can                                          |
| --- | ----------------------- | ---------------------------------------------------------- |
| 1   | First repository        | Start a repo and keep secrets and `node_modules` out of it |
| 2   | Branching and conflicts | Resolve a conflict without discarding anyone's work        |
| 3   | Undo and recovery       | Recover a commit that has been "deleted"                   |
| 4   | Remotes                 | Explain the difference between `fetch` and `pull`          |
| 5   | GitHub                  | Open, review, and merge a pull request                     |


Lab 5 runs against the real CTServ GitHub organisation and is checked by your
pair, not by a script.

## If you get stuck

In order:

1. `git status`. It is not decoration — it almost always tells you the next
  command, in plain English.
2. `git log --oneline --graph --all` — see the shape of what you have made.
3. Ask the person next to you.
4. Ask the room.

There is no penalty for any of these and no prize for finishing first.