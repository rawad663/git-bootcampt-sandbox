#!/usr/bin/env bash
# CTServ Git Bootcamp — sandbox driver
# Usage:  ./bootcamp.sh start 1     build lab 1 and drop you in it
#         ./bootcamp.sh rules 1     reprint lab 1's brief without rebuilding it
#         ./bootcamp.sh verify 1    check your work on lab 1
#         ./bootcamp.sh reset 1     wipe lab 1 and rebuild it
#         ./bootcamp.sh teammate    (lab 4 only) simulate a colleague pushing
#         ./bootcamp.sh doctor      check your machine is ready
#
# Everything lives under ./labs/ . Nothing outside this folder is touched.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABS="$ROOT/labs"

# ---------- output helpers ----------
if [ -t 1 ]; then
  R=$'\033[31m'; G=$'\033[32m'; Y=$'\033[33m'; B=$'\033[1m'; N=$'\033[0m'
else
  R=""; G=""; Y=""; B=""; N=""
fi
ok()   { echo "  ${G}PASS${N}  $1"; }
bad()  { echo "  ${R}FAIL${N}  $1"; [ $# -gt 1 ] && echo "        ${Y}hint:${N} $2"; FAILED=$((FAILED+1)); }
head1(){ echo; echo "${B}$1${N}"; echo; }

# ---------- git seeding helpers ----------
gitq() { git -C "$1" "${@:2}" >/dev/null 2>&1; }

init_repo() {   # init_repo <dir>
  mkdir -p "$1"
  gitq "$1" init
  gitq "$1" symbolic-ref HEAD refs/heads/main
  gitq "$1" config user.name  "CTServ Bootcamp"
  gitq "$1" config user.email "bootcamp@ctserv.local"
  gitq "$1" config commit.gpgsign false
  gitq "$1" config core.autocrlf false
}

commit_all() { # commit_all <dir> <message>
  gitq "$1" add -A
  git -C "$1" -c user.name="CTServ Bootcamp" -c user.email="bootcamp@ctserv.local" \
      commit -q -m "$2" >/dev/null 2>&1
}

# ---------- the fictional CTServ project ----------
scaffold_app() { # scaffold_app <dir>
  local d="$1"
  mkdir -p "$d/src" "$d/logs" "$d/node_modules/left-pad"
  cat > "$d/package.json" <<'EOF'
{
  "name": "client-portal",
  "version": "1.4.0",
  "description": "CTServ client portal — appointment + billing front end",
  "main": "src/app.js",
  "scripts": { "start": "node src/app.js", "test": "node src/test.js" },
  "dependencies": { "express": "^4.18.2" }
}
EOF
  cat > "$d/src/app.js" <<'EOF'
const express = require('express');
const { loadConfig } = require('./config');
const app = express();

const config = loadConfig();

app.get('/health', (req, res) => {
  res.json({ status: 'ok', version: config.version });
});

app.get('/appointments', (req, res) => {
  res.json({ appointments: [] });
});

app.listen(config.port, () => {
  console.log(`client-portal listening on ${config.port}`);
});
EOF
  cat > "$d/src/config.js" <<'EOF'
function loadConfig() {
  return {
    port: process.env.PORT || 3000,
    version: '1.4.0',
    clientCode: process.env.CLIENT_CODE || 'DEMO'
  };
}

module.exports = { loadConfig };
EOF
  cat > "$d/README.md" <<'EOF'
# client-portal

Appointment and billing front end. Deployed on-premise, one instance per client.

## Running locally

    npm install
    npm start
EOF
  # junk that must NOT be committed
  cat > "$d/.env" <<'EOF'
DB_PASSWORD=hunter2
CLIENT_CODE=STMARY
API_KEY=sk-do-not-commit-me
EOF
  echo '{"name":"left-pad","version":"1.3.0"}' > "$d/node_modules/left-pad/package.json"
  echo "2026-08-24 12:04:11 GET /health 200" > "$d/logs/debug.log"
}

# =====================================================================
# LAB 1 — solo git: init, ignore, stage, commit, amend
# =====================================================================
start_1() {
  local d="$LABS/lab1/client-portal"
  rm -rf "$LABS/lab1"; mkdir -p "$LABS/lab1"
  scaffold_app "$d"
  cat > "$LABS/lab1/BRIEF.md" <<'EOF'
LAB 1 — Your first repository
=============================
You have a copy of client-portal that has never been under version control.

  1. Turn this folder into a git repository, with the default branch named main.
  2. Three things here must NEVER be committed: node_modules/, .env, logs/.
     Write a .gitignore that excludes them.
  3. Commit everything that SHOULD be tracked as your first commit.
  4. Bump "version" to 1.5.0 in BOTH package.json and src/config.js.
     Commit that as a second commit.
  5. You mistyped the message on that second commit. Fix the message
     WITHOUT creating a third commit.

Check yourself:   ./bootcamp.sh verify 1
Reread this:      ./bootcamp.sh rules 1
EOF
}

verify_1() {
  local d="$LABS/lab1/client-portal"
  [ -d "$d/.git" ] || { bad "the folder is a git repository" "run: git init"; return; }
  ok "the folder is a git repository"

  local br; br=$(git -C "$d" symbolic-ref --short HEAD 2>/dev/null)
  [ "$br" = "main" ] && ok "default branch is 'main'" \
    || bad "default branch is 'main' (found '${br:-none}')" "git branch -m main"

  local n; n=$(git -C "$d" rev-list --count HEAD 2>/dev/null || echo 0)
  [ "$n" -ge 2 ] && ok "at least 2 commits ($n found)" \
    || bad "at least 2 commits (found $n)" "git commit twice — see steps 3 and 4"

  git -C "$d" ls-files --error-unmatch .gitignore >/dev/null 2>&1 \
    && ok ".gitignore is tracked" || bad ".gitignore is tracked" "git add .gitignore"

  local leaked=""
  for f in .env logs/debug.log node_modules/left-pad/package.json; do
    git -C "$d" ls-files --error-unmatch "$f" >/dev/null 2>&1 && leaked="$leaked $f"
  done
  [ -z "$leaked" ] && ok "no secrets, logs or dependencies tracked" \
    || bad "no secrets, logs or dependencies tracked —$leaked is tracked" \
           "git rm --cached the file, then add it to .gitignore"

  for f in src/app.js src/config.js package.json README.md; do
    git -C "$d" ls-files --error-unmatch "$f" >/dev/null 2>&1 \
      && ok "$f is tracked" || bad "$f is tracked" "git add $f"
  done

  git -C "$d" show HEAD:package.json 2>/dev/null | grep -q '1\.5\.0' \
    && git -C "$d" show HEAD:src/config.js 2>/dev/null | grep -q '1\.5\.0' \
    && ok "version 1.5.0 is committed in both files" \
    || bad "version 1.5.0 is committed in both files" "edit both, then git add + git commit"

  [ -z "$(git -C "$d" status --porcelain 2>/dev/null)" ] \
    && ok "working tree is clean" \
    || bad "working tree is clean" "git status will show what is still uncommitted"

  git -C "$d" reflog 2>/dev/null | grep -qi 'amend' \
    && ok "you amended a commit instead of adding a new one" \
    || bad "you amended a commit instead of adding a new one" \
           "git commit --amend -m \"your better message\""
}

# =====================================================================
# LAB 2 — branching, merging, and a real conflict
# =====================================================================
start_2() {
  local d="$LABS/lab2/client-portal"
  rm -rf "$LABS/lab2"; mkdir -p "$LABS/lab2"
  scaffold_app "$d"
  rm -rf "$d/node_modules" "$d/logs" "$d/.env"
  printf 'node_modules/\n.env\nlogs/\n' > "$d/.gitignore"
  init_repo "$d"
  cat > "$d/src/invoice.js" <<'EOF'
// Invoice rendering for the client portal.

function formatInvoice(invoice) {
  const lines = [];
  lines.push(`Invoice ${invoice.number}`);
  lines.push(`Client:  ${invoice.client}`);
  lines.push(`Total:   ${invoice.total.toFixed(2)}`);
  return lines.join('\n');
}

module.exports = { formatInvoice };
EOF
  commit_all "$d" "Initial import of client-portal"

  # A colleague's branch that rewrites the SAME line you are about to touch.
  gitq "$d" checkout -b feature/invoice-tax
  cat > "$d/src/invoice.js" <<'EOF'
// Invoice rendering for the client portal.

function formatInvoice(invoice) {
  const lines = [];
  lines.push(`Invoice ${invoice.number}`);
  lines.push(`Client:  ${invoice.client}`);
  lines.push(`Tax:     ${invoice.tax.toFixed(2)}`);
  lines.push(`Total:   ${(invoice.total + invoice.tax).toFixed(2)}`);
  return lines.join('\n');
}

module.exports = { formatInvoice };
EOF
  commit_all "$d" "Include tax in the invoice total"
  gitq "$d" checkout main

  cat > "$LABS/lab2/BRIEF.md" <<'EOF'
LAB 2 — Branching, merging, and your first conflict
===================================================
main has one file that matters: src/invoice.js
There is also a colleague's branch, feature/invoice-tax, which changes how
the Total is calculated. Do not look at it yet.

  1. From main, create a branch called  feature/invoice-currency
  2. On that branch, change the Total line in src/invoice.js so it prints the
     currency code, like:   Total:   USD 45.00
     Commit it.
  3. Switch back to main and merge feature/invoice-tax into main.
     Notice what git calls this merge, and why no commit was created.
  4. Now merge feature/invoice-currency into main. This WILL conflict:
     you and your colleague both rewrote the same line.
     Resolve it so the final Total line does BOTH things — includes the tax
     in the amount AND shows the currency code. Complete the merge.
  5. Delete both feature branches.

Check yourself:   ./bootcamp.sh verify 2
Reread this:      ./bootcamp.sh rules 2

Panicking mid-conflict?   git merge --abort   puts everything back.

The lesson of step 4: "accept ours" and "accept theirs" are usually BOTH
wrong. A conflict is git telling you two intentions collided and only a
human knows what the code should say.
EOF
}

verify_2() {
  local d="$LABS/lab2/client-portal"
  [ -d "$d/.git" ] || { bad "lab 2 repo exists" "run ./bootcamp.sh start 2"; return; }
  local f="$d/src/invoice.js"

  local br; br=$(git -C "$d" symbolic-ref --short HEAD 2>/dev/null)
  [ "$br" = "main" ] && ok "you are on main" || bad "you are on main (on '${br:-detached HEAD}')" "git switch main"

  if [ -f "$d/.git/MERGE_HEAD" ]; then
    bad "the merge is finished" "resolve the file, git add it, then git commit"
  else
    ok "no merge left half-finished"
  fi

  if grep -qE '^(<<<<<<<|=======|>>>>>>>)' "$f" 2>/dev/null; then
    bad "no conflict markers left in src/invoice.js" "delete the <<<<<<< ======= >>>>>>> lines, keep the code you want"
  else
    ok "no conflict markers left in src/invoice.js"
  fi

  grep -q 'Tax:' "$f" 2>/dev/null \
    && ok "the Tax breakdown line survived" \
    || bad "the Tax breakdown line survived" "you resolved the conflict by discarding your colleague's work"

  grep -q 'invoice.total + invoice.tax' "$f" 2>/dev/null \
    && ok "the total still includes the tax" \
    || bad "the total still includes the tax" "the resolved line must keep (invoice.total + invoice.tax)"

  grep -q 'USD' "$f" 2>/dev/null \
    && ok "the currency code is on the Total line" \
    || bad "the currency code is on the Total line" "you resolved the conflict by discarding your own work"

  local parents; parents=$(git -C "$d" rev-list --parents -n1 HEAD 2>/dev/null | wc -w)
  [ "$parents" -ge 3 ] && ok "HEAD is a merge commit (it has two parents)" \
    || bad "HEAD is a merge commit" "a conflicted merge always ends in a merge commit"

  git -C "$d" log main --oneline 2>/dev/null | grep -qi 'tax in the invoice total' \
    && ok "the tax work is in main's history" || bad "the tax work is in main's history" "git merge feature/invoice-tax"

  local left; left=$(git -C "$d" for-each-ref --format='%(refname:short)' 'refs/heads/feature/*' 2>/dev/null | wc -l)
  [ "$left" -eq 0 ] && ok "feature branches cleaned up" \
    || bad "feature branches cleaned up ($left still there)" "git branch -d feature/invoice-tax feature/invoice-currency"
}

# =====================================================================
# LAB 3 — undo and recovery
# =====================================================================
start_3() {
  local d="$LABS/lab3/client-portal"
  rm -rf "$LABS/lab3"; mkdir -p "$LABS/lab3"
  scaffold_app "$d"
  rm -rf "$d/node_modules" "$d/logs" "$d/.env"
  printf 'node_modules/\n.env\nlogs/\n' > "$d/.gitignore"
  init_repo "$d"
  cat > "$d/src/audit.js" <<'EOF'
// Every write to a patient record must be written to the audit log.
function writeAudit(userId, action, recordId) {
  console.log(JSON.stringify({ userId, action, recordId, at: Date.now() }));
}
module.exports = { writeAudit };
EOF
  commit_all "$d" "Initial import of client-portal"

  echo "// sync worker" > "$d/src/sync.js"
  commit_all "$d" "Add sync worker skeleton"

  # the commit that will be rescued from the reflog
  cat > "$d/src/sync.js" <<'EOF'
// sync worker
const MAX_RETRIES = 5;

async function syncWithRetry(fn) {
  for (let i = 0; i < MAX_RETRIES; i++) {
    try { return await fn(); } catch (e) { if (i === MAX_RETRIES - 1) throw e; }
  }
}

module.exports = { syncWithRetry, MAX_RETRIES };
EOF
  commit_all "$d" "Add retry to sync worker"
  local rescue; rescue=$(git -C "$d" rev-parse HEAD)

  # "someone" threw it away with a hard reset — now it is dangling but in the reflog
  gitq "$d" reset --hard HEAD~1

  # the bad commit that must be reverted
  cat > "$d/src/audit.js" <<'EOF'
// Every write to a patient record must be written to the audit log.
function writeAudit(userId, action, recordId) {
  // temporarily disabled - too noisy in St Mary staging
}
module.exports = { writeAudit };
EOF
  commit_all "$d" "Disable audit logging"
  echo "" >> "$d/README.md"; echo "(c) 2026 CTServ" >> "$d/README.md"
  commit_all "$d" "Bump copyright year"
  echo "console.log('ready');" >> "$d/src/app.js"
  commit_all "$d" "Log startup readiness"

  # leave uncommitted work in the tree for the stash exercise
  cat >> "$d/src/config.js" <<'EOF'

// half-finished: per-client feature flags
function featureFlags() {
}
EOF

  echo "$rescue" > "$LABS/lab3/.rescue"
  cat > "$LABS/lab3/BRIEF.md" <<'EOF'
LAB 3 — Undoing things without losing work
==========================================
Three separate rescues. Read all three before you start.

  1. THE BAD COMMIT.
     Someone committed "Disable audit logging". For a hospital client that is
     a compliance incident. Two commits have landed on top of it, so you
     cannot just delete it — the history is already shared.
     Undo its EFFECT while keeping it in the history.

  2. THE LOST COMMIT.
     A commit called "Add retry to sync worker" was thrown away with
     git reset --hard. It is not in git log. It is not gone.
     Find it and get it back onto main.

  3. THE INTERRUPTION.
     src/config.js has half-finished work in it. Your lead needs you on
     something else right now, and you refuse to commit broken code.
     Park the change so the working tree is clean, then bring it back.

Check yourself:   ./bootcamp.sh verify 3
Reread this:      ./bootcamp.sh rules 3

The tool you need for #2 is the single most important safety net in git.
If you have never used it, ask before you google it.
EOF
}

verify_3() {
  local d="$LABS/lab3/client-portal"
  [ -d "$d/.git" ] || { bad "lab 3 repo exists" "run ./bootcamp.sh start 3"; return; }

  # 1 - revert
  git -C "$d" show HEAD:src/audit.js 2>/dev/null | grep -q 'console.log' \
    && ok "audit logging works again" \
    || bad "audit logging works again" "git revert the bad commit"
  git -C "$d" log --oneline 2>/dev/null | grep -qi 'disable audit logging' \
    && ok "the bad commit is still in the history (you reverted, not rewrote)" \
    || bad "the bad commit is still in the history" \
           "you erased shared history — undo with the reflog and use git revert instead"

  # 2 - reflog rescue
  local rescue; rescue=$(cat "$LABS/lab3/.rescue" 2>/dev/null)
  if [ -n "$rescue" ] && git -C "$d" merge-base --is-ancestor "$rescue" HEAD 2>/dev/null; then
    ok "the lost commit is back on main (original commit recovered)"
  elif git -C "$d" log --oneline 2>/dev/null | grep -qi 'retry to sync worker'; then
    ok "the lost commit is back on main (recovered as a copy)"
  else
    bad "the lost commit is back on main" "git reflog — then cherry-pick or merge the SHA you find"
  fi
  grep -q 'MAX_RETRIES' "$d/src/sync.js" 2>/dev/null \
    && ok "src/sync.js has the retry logic in the working tree" \
    || bad "src/sync.js has the retry logic" "the commit is recovered but not checked out"

  # 3 - stash
  # A popped stash deletes refs/stash and its reflog, but the stash commit
  # itself lingers as an unreachable object until gc. That is our proof.
  local stashed="no"
  [ -f "$d/.git/logs/refs/stash" ] && stashed="yes"
  git -C "$d" fsck --unreachable --no-progress 2>/dev/null \
    | awk '$2=="commit"{print $3}' \
    | while read -r c; do git -C "$d" log -1 --format='%s' "$c" 2>/dev/null; done \
    | grep -q '^WIP on ' && stashed="yes"
  [ "$stashed" = "yes" ] \
    && ok "you used the stash" \
    || bad "you used the stash" "git stash — then git stash pop when you are ready"
  grep -q 'featureFlags' "$d/src/config.js" 2>/dev/null \
    && ok "the parked work came back" \
    || bad "the parked work came back" "git stash pop"
}

# =====================================================================
# LAB 4 — remotes
# =====================================================================
start_4() {
  local base="$LABS/lab4"
  rm -rf "$base"; mkdir -p "$base"
  local seed="$base/.seed" origin="$base/origin.git"

  scaffold_app "$seed"
  rm -rf "$seed/node_modules" "$seed/logs" "$seed/.env"
  printf 'node_modules/\n.env\nlogs/\n' > "$seed/.gitignore"
  init_repo "$seed"
  commit_all "$seed" "Initial import of client-portal"
  echo "// billing" > "$seed/src/billing.js"
  commit_all "$seed" "Add billing module"

  git init --bare -q "$origin" 2>/dev/null
  git -C "$origin" symbolic-ref HEAD refs/heads/main
  gitq "$seed" remote add origin "$origin"
  gitq "$seed" push origin main

  # a teammate commit lands BEFORE you clone is boring; land it after, in cmd_teammate.
  git clone -q "$origin" "$base/client-portal" 2>/dev/null
  gitq "$base/client-portal" config user.name  "CTServ Bootcamp"
  gitq "$base/client-portal" config user.email "bootcamp@ctserv.local"
  rm -rf "$seed"

  cat > "$base/BRIEF.md" <<'EOF'
LAB 4 — Working with a remote
=============================
origin.git next to this file is a bare repository. It is standing in for
GitHub — same commands, no network, no account.

You already have a clone in client-portal/.

  1. Create a branch  feature/statement-pdf  and make a commit on it.
     Push it to origin and set it to track origin.
  2. Run  ./bootcamp.sh teammate
     That pushes a commit to origin/main behind your back, exactly like a
     colleague would. Get that commit into your local main.
  3. Now make a commit of your own on local main, then run
     ./bootcamp.sh teammate  again. Your main and origin/main have now
     DIVERGED. Reconcile them and push. Do not force push.
  4. Answer for yourself, out loud: what is the difference between
     git fetch and git pull? Ask if you cannot.

Check yourself:   ./bootcamp.sh verify 4
Reread this:      ./bootcamp.sh rules 4

EXPECT THIS IN STEP 3:
  fatal: Need to specify how to reconcile divergent branches.

Git is not broken and you did nothing wrong. Git is refusing to guess
whether you want a merge or a rebase. For today, choose merge:

  git pull --no-rebase origin main

Do NOT reach for git push --force to make the message go away. Force
pushing to a shared branch deletes your colleague's work from the server.
It is the one command that can genuinely lose someone else's day.
EOF
}

cmd_teammate() {
  local base="$LABS/lab4" origin="$LABS/lab4/origin.git"
  [ -d "$origin" ] || { echo "${R}Lab 4 is not set up. Run ./bootcamp.sh start 4${N}"; return 1; }
  local tmp; tmp=$(mktemp -d)
  git clone -q "$origin" "$tmp/wc" 2>/dev/null
  gitq "$tmp/wc" config user.name  "Elie"
  gitq "$tmp/wc" config user.email "elie@ctserv.local"
  local n; n=$(git -C "$tmp/wc" rev-list --count main)
  echo "// teammate change $n" >> "$tmp/wc/src/billing.js"
  git -C "$tmp/wc" add -A >/dev/null 2>&1
  git -C "$tmp/wc" commit -q -m "Fix rounding on billing totals (from Elie)" >/dev/null 2>&1
  git -C "$tmp/wc" push -q origin main >/dev/null 2>&1
  rm -rf "$tmp"
  echo "${G}Elie just pushed a commit to origin/main.${N} Your local repo does not know yet."
  echo "Try:  git status    then    git fetch    then    git status"
}

verify_4() {
  local d="$LABS/lab4/client-portal" origin="$LABS/lab4/origin.git"
  [ -d "$d/.git" ] || { bad "lab 4 clone exists" "run ./bootcamp.sh start 4"; return; }

  git -C "$origin" show-ref --verify --quiet refs/heads/feature/statement-pdf \
    && ok "feature/statement-pdf was pushed to origin" \
    || bad "feature/statement-pdf was pushed to origin" "git push -u origin feature/statement-pdf"

  local up; up=$(git -C "$d" for-each-ref --format='%(upstream:short)' refs/heads/feature/statement-pdf 2>/dev/null)
  [ -n "$up" ] && ok "the branch tracks origin (upstream = $up)" \
    || bad "the branch tracks origin" "push it with -u, or: git branch -u origin/feature/statement-pdf"

  local tm; tm=$(git -C "$origin" log main --oneline 2>/dev/null | grep -ci 'from Elie')
  [ "$tm" -ge 2 ] || bad "you ran ./bootcamp.sh teammate twice (found $tm teammate commits)" \
                         "re-read steps 2 and 3"
  [ "$tm" -ge 2 ] && ok "both teammate commits are on origin/main"

  local mine; mine=$(git -C "$origin" log main --oneline 2>/dev/null | grep -cvi 'from Elie')
  [ "$mine" -ge 3 ] && ok "your own commit reached origin/main" \
    || bad "your own commit reached origin/main" "commit on main, reconcile with origin, then git push"

  local lo ro
  lo=$(git -C "$d" rev-parse main 2>/dev/null)
  git -C "$d" fetch -q origin >/dev/null 2>&1
  ro=$(git -C "$d" rev-parse origin/main 2>/dev/null)
  [ "$lo" = "$ro" ] && ok "local main and origin/main are identical" \
    || bad "local main and origin/main are identical" "git pull, then git push"

  git -C "$d" log main --oneline 2>/dev/null | grep -qi 'from Elie' \
    && ok "the teammate's work is in your local main" \
    || bad "the teammate's work is in your local main" "git pull"
}

# =====================================================================
# LAB 5 — GitHub (checklist only; needs the real org)
# =====================================================================
start_5() {
  mkdir -p "$LABS/lab5"
  cat > "$LABS/lab5/BRIEF.md" <<'EOF'
LAB 5 — GitHub
==============
This one runs against the real CTServ GitHub organisation, in pairs.
There is no ./bootcamp.sh verify 5 — your pair verifies you.

  1. Clone the training repo your instructor gives you.
  2. Branch, make a small change, push the branch.
  3. Open a Pull Request. Write a description that answers WHY, not WHAT.
     The diff already says what.
  4. Swap with your pair. Review their PR: leave at least one comment
     on a specific line, and one suggestion.
  5. Get your PR approved, then merge it.
  6. Now try to push a commit directly to main. Read the error carefully.
     That error is branch protection, and it is the whole point.
  7. Look at the Actions tab. Find the check that ran on your PR.

Discuss as a group before you leave:
  - What did GitHub give us that plain git did not?
  - What did GitHub NOT give us? (Hint: nothing in git or GitHub knows
    which version St Mary is running. That is our problem to solve.)

Reread this:      ./bootcamp.sh rules 5
EOF
}

# =====================================================================
# driver
# =====================================================================
cmd_doctor() {
  head1 "Checking your machine"
  FAILED=0
  if command -v git >/dev/null 2>&1; then
    ok "git is installed ($(git --version | awk '{print $3}'))"
  else
    bad "git is installed" "Windows: https://git-scm.com/download/win   macOS: xcode-select --install"
  fi
  local v maj min
  v=$(git --version 2>/dev/null | awk '{print $3}')
  maj=${v%%.*}; min=$(echo "$v" | cut -d. -f2)
  if [ -n "$maj" ] && { [ "$maj" -gt 2 ] || { [ "$maj" -eq 2 ] && [ "${min:-0}" -ge 23 ]; }; }; then
    ok "git is new enough for switch/restore (2.23+)"
  else
    bad "git 2.23 or newer" "upgrade git — today's labs use git switch and git restore"
  fi
  [ -n "$(git config --global user.name 2>/dev/null)" ] \
    && ok "user.name is set ($(git config --global user.name))" \
    || bad "user.name is set" "git config --global user.name \"Your Name\""
  [ -n "$(git config --global user.email 2>/dev/null)" ] \
    && ok "user.email is set ($(git config --global user.email))" \
    || bad "user.email is set" "git config --global user.email \"you@ctserv.com\""
  echo
  [ "$FAILED" -eq 0 ] && echo "${G}Ready.${N} Start with: ./bootcamp.sh start 1" \
                      || echo "${Y}$FAILED thing(s) to fix before we start.${N}"
}

cmd_start() {
  local n="$1"
  case "$n" in
    1|2|3|4|5) "start_$n" ;;
    *) echo "Labs are 1 to 5."; exit 1 ;;
  esac
  head1 "Lab $n is ready"
  cat "$LABS/lab$n/BRIEF.md"
  echo
  if [ -d "$LABS/lab$n/client-portal" ]; then
    echo "${B}cd labs/lab$n/client-portal${N}"
  elif [ "$n" = "4" ]; then
    echo "${B}cd labs/lab4/client-portal${N}"
  fi
}

# Reprints the brief for a lab without rebuilding it, so the rules can be
# reread mid-lab without losing work.
cmd_rules() {
  local n="$1"
  case "$n" in
    1|2|3|4|5) ;;
    *) echo "Labs are 1 to 5."; exit 1 ;;
  esac
  local brief="$LABS/lab$n/BRIEF.md"
  [ -f "$brief" ] || { echo; echo "Lab $n is not set up yet. Run:  ./bootcamp.sh start $n"; return 1; }
  head1 "Lab $n rules"
  cat "$brief"
}

cmd_verify() {
  local n="$1"
  [ "$n" = "5" ] && { echo; echo "Lab 5 is verified by your pair, not by a script. See labs/lab5/BRIEF.md"; return; }
  FAILED=0
  head1 "Verifying lab $n"
  "verify_$n"
  echo
  if [ "$FAILED" -eq 0 ]; then
    echo "${G}${B}Lab $n complete.${N}"
  else
    echo "${Y}$FAILED check(s) still failing. Nothing is broken — fix and run it again.${N}"
    echo "Start over with:  ./bootcamp.sh reset $n"
  fi
}

case "${1:-help}" in
  start)    cmd_start "${2:?which lab? e.g. ./bootcamp.sh start 1}" ;;
  rules)    cmd_rules "${2:?which lab? e.g. ./bootcamp.sh rules 1}" ;;
  verify)   cmd_verify "${2:?which lab? e.g. ./bootcamp.sh verify 1}" ;;
  reset)    cmd_start "${2:?which lab?}" ;;
  teammate) cmd_teammate ;;
  doctor)   cmd_doctor ;;
  *)
    cat <<EOF

CTServ Git Bootcamp sandbox

  ./bootcamp.sh doctor        check your machine is ready
  ./bootcamp.sh start N       set up lab N (1-5) and print the brief
  ./bootcamp.sh rules N       reprint lab N's brief without rebuilding it
  ./bootcamp.sh verify N      check your work
  ./bootcamp.sh reset N       wipe lab N and start it over
  ./bootcamp.sh teammate      lab 4 only: simulate a colleague pushing

Nothing outside this folder is ever touched. Break things freely.

EOF
    ;;
esac
