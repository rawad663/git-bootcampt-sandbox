# Git cheat sheet — CTServ!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Organised by *what you are trying to do*.

## Before anything else

```
git status                       what state am I in? read this constantly
git log --oneline --graph --all  the shape of the history
```

If you only remember two commands, remember these two.

## Saving work

```
git add <file>            stage a specific file
git add .                 stage all files
git commit -m "msg"       commit what is staged
git commit --amend        fix the LAST commit (message or contents)
```

`--amend` rewrites history. Safe before you push. Not safe after.

## Looking around

```
git diff                  what have I changed but not staged?
git diff --staged         what is about to be committed?
git show <sha>            what did that commit actually change?
git log -- <file>         history of one file
git blame <file>          who last touched each line, and in which commit
```



## Branching

```
git switch -c feature/x   create a branch and move onto it
git switch main           move to an existing branch
git branch                list local branches
git branch -d feature/x   delete a merged branch
git merge feature/x       bring feature/x into the branch you are ON
```

You merge *into* the branch you are standing on. Check `git status` first.

## Conflicts

```
git status                lists exactly which files conflict
                          -- edit the files, delete the <<<< ==== >>>> markers
git add <file>            mark each one resolved
git commit                finish the merge
git merge --abort         put everything back the way it was
```

"Accept ours" and "accept theirs" are usually both wrong. A conflict means
two intentions collided and only a human knows what the code should say.

## Undoing


| You want to                            | Command                       | Safe on shared branches? |
| -------------------------------------- | ----------------------------- | ------------------------ |
| Discard uncommitted changes to a file  | `git restore <file>`          | yes                      |
| Unstage a file, keep the changes       | `git restore --staged <file>` | yes                      |
| Fix the last commit                    | `git commit --amend`          | **no**                   |
| Undo a commit that others already have | `git revert <sha>`            | yes                      |
| Move your branch back, discard commits | `git reset --hard <sha>`      | **no**                   |
| Park work temporarily                  | `git stash` / `git stash pop` | yes                      |
| Copy one commit onto this branch       | `git cherry-pick <sha>`       | yes                      |


`revert` **adds a new commit that undoes an old one.** `reset` **pretends the old
one never happened.** On anything you have pushed, use `revert`.

## When you think you have lost work

```
git reflog
```

Every position `HEAD` has been in, for the last 90 days — including commits
that no branch points at any more. Find the SHA, then:

```
git switch -c rescue <sha>     put it on a new branch
git cherry-pick <sha>          or copy just that commit to where you are
```

**Committed work is essentially never lost.** Uncommitted work genuinely can
be. That asymmetry is the whole argument for committing early and often.

## Remotes

```
git fetch                 download what changed on the server. Changes nothing locally.
git pull                  fetch + merge into your branch
git push                  send your commits up
git push -u origin <br>   first push of a new branch; sets up tracking
```

`fetch` is always safe. `pull` changes your working files.

## Commands to be careful with

```
git push --force          can delete a colleague's commits from the server
git reset --hard          discards uncommitted work with no undo
git clean -fd             deletes untracked files with no undo
```

Use `git push --force-with-lease` instead of `--force` if you must. It
refuses when someone else has pushed since you last looked.

## CTServ conventions

```
main                      what is releasable
feature/<ticket>-<slug>   your work
hotfix/<ticket>-<slug>    urgent client fix
git tag -a v1.5.0 -m "…"  a release. Annotated (-a), always.
```

A commit message answers **why**. The diff already says what.

Bad:  `fix bug`
Good: `Stop double-charging when an appointment is rescheduled twice`