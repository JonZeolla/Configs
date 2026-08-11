---
name: free-disk-space
description: Reclaim disk space on this Mac. Runs a fixed pre-approved cleanup sequence — the docker-cleanup-more alias, the next-gen-governance worktree cleanup skill, then `mo clean` and `mo optimize` — measuring what each stage freed, and then investigates whatever is still consuming space and reports ranked suggestions WITHOUT making any further changes until the user approves them. Use this whenever the user says they are out of disk, low on space, "disk is full", "no space left on device", "my mac is full", "free up space", "reclaim storage", "clean up my disk", or asks why storage is disappearing. Also reach for it when a build, `docker pull`, `uv sync`, or install fails with a no-space/ENOSPC error, even if the user never uses the word "disk".
---

# Free disk space

Three cleanup stages that are approved in advance, then a hard stop where you
investigate and advise but change nothing.

The split exists because the first three stages only touch things that are
rebuildable by definition — container images, merged branches, caches. Past that
point every remaining candidate is either the user's own data or something whose
value only they can judge, and a wrong `rm -rf` there costs real work. So the
back half of this skill is deliberately read-only.

Work through the stages in order. Don't skip a stage because you suspect it
won't find much; the measurements are the point, and a stage that frees nothing
is a useful finding.

## Stage 0 — Baseline

Record the starting numbers so you can report what each stage actually bought:

```bash
df -h / | tail -1
du -sh ~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw 2>/dev/null
```

Keep the available-space figure. You'll re-measure after each stage.

## Stage 1 — Docker

Run the user's shell function:

```bash
docker-cleanup-more
```

Give this a 10-minute timeout. Pruning images on a large daemon genuinely takes
minutes, and killing it partway leaves the reclaim incomplete.

It's a zsh function defined in `~/.zshrc` and the Bash tool's shell loads it. It
is a superset of the companion `docker-cleanup` alias: stopped containers, all
unused images with no age filter, all build cache, the cache of every
docker-container buildx builder, and anonymous volumes. If it ever comes back
"command not found", run the equivalent inline rather than substituting something
weaker:

```bash
docker system df
docker container prune -f
docker image prune -a -f
docker builder prune -af
for b in $(docker buildx ls | tail -n +2 | grep -v '\\_' | awk '$2=="docker-container"{sub(/\*$/,"",$1); print $1}'); do
  docker buildx prune -af --builder "$b"
done
docker volume prune -f
docker system df
```

Two deliberate omissions, both of which belong in your Stage 4 suggestions rather
than being "fixed" here:

- **Named volumes.** The volume prune has no `-a`, so it clears anonymous volumes
  only. Named ones are local database state — pgvector, postgres — and dropping
  them costs real data. If they're large and the user wants them gone, that's a
  suggestion for them to approve, not a default.
- **Docker-driver builders.** The loop only covers `docker-container` builders
  because those hide cache in a volume nothing else reaches. Docker-driver
  builders share the daemon cache already pruned above, and pruning one that's
  bound to a different context just errors.

Re-measure `df -h /` before moving on.

## Stage 2 — Worktrees

Invoke the `cleanup-worktrees` skill. It removes per-branch checkouts whose PRs
are confirmed merged on GitHub, which is why it's safe to run unattended — it
proves the merge before deleting anything.

It needs to run inside the repo:

```
/Users/jonzeolla/src/zenable/next-gen-governance
```

If the session's working directory is elsewhere, `cd` there first. If that path
doesn't exist on this machine, skip the stage and say so in the report rather
than substituting a hand-rolled `git worktree remove` loop.

Re-measure.

## Stage 3 — Mole

In this order:

```bash
mo clean </dev/null
mo optimize </dev/null
```

`mo clean` is the disk-space one (caches, logs, temp files, leftovers from
uninstalled apps); `mo optimize` refreshes caches and repairs safe maintenance
issues. Both run fine non-interactively with stdin redirected.

**Mole exits non-zero on a perfectly normal run.** It returns 1 whenever any
individual item was skipped, unavailable, or failed, which is nearly every run —
a healthy run routinely reports something like "12 unchanged | 3 skipped | 1
unavailable | 2 failed". Read the summary block, not the exit status. Only treat
it as a real failure if the run produced no summary at all.

Mole may ask for sudo. If a call appears to hang, that's the likely reason —
report it and let the user run it themselves rather than trying to work around
the prompt.

Re-measure.

## Stage 4 — Investigate, report, stop

Read-only from here. Run whatever diagnostics you need, then present findings and
wait. Do not delete, prune, uninstall, or move anything in this stage, no matter
how obviously reclaimable it looks — the user asked to see the options first, and
the value of that is lost if you've already acted on the easy ones.

### Where to look

Start broad, then drill into whatever is biggest. Don't run all of these
reflexively; follow the space.

```bash
df -h /                                    # what's actually free now
du -sh ~/Library/Caches/* 2>/dev/null | sort -rh | head -20
du -sh ~/Downloads ~/Desktop ~/Documents 2>/dev/null
du -sh ~/src/*/ 2>/dev/null | sort -rh | head -15
```

`du` on a targeted directory then drilling into the biggest entry is the fastest
way to find the space. Two tools that look attractive here are traps: `mo analyze`
is an interactive TUI that can't render in this context, and its `-json` form
scans the whole disk while printing nothing until it finishes, so it reads as a
hang. Likewise `find ~ -size +1G` walks every file in the home directory and takes
minutes. If you want either one, run it in the background with a generous timeout
rather than blocking on it — but targeted `du` usually answers the question first.

Docker, for what Stage 1 deliberately left behind:

```bash
docker system df -v                        # per-image, per-volume, per-cache
docker volume ls                           # named volumes -- the local DB data
```

Named volumes are the main Docker candidate to surface here. Report each one's
size and what it holds, because "your local pgvector database, 373 MB" and "an
orphaned volume from a compose stack you deleted last year" deserve very
different answers from the user.

Developer caches and build output, which accumulate silently:

- `~/Library/Developer/Xcode/DerivedData`, `iOS DeviceSupport`, simulators
- `~/Library/Caches/Homebrew` and `brew cleanup -n` to preview
- `~/.cache/uv`, `~/.npm`, `~/.cargo/registry`
- stale `.venv` and `node_modules` trees under `~/src`

Time Machine local snapshots deserve a specific check — they consume real space
while being invisible to most tools, and people are routinely surprised:

```bash
tmutil listlocalsnapshots / 2>/dev/null
```

And for individual offenders, once `du` has narrowed things to a directory worth
walking:

```bash
find <that-dir> -xdev -type f -size +1G 2>/dev/null | head -20
```

### Gotchas that will otherwise mislead you

**`Docker.raw` is a sparse file.** `ls -lh` reports the apparent size — commonly
600G — while the real allocation is a fraction of that. Always use `du -sh` on it,
and never report the `ls` number as consumption.

**Freeing space inside the Docker VM doesn't immediately shrink `Docker.raw`.**
Docker Desktop reclaims it via TRIM on its own schedule. If the user needs the
host space back right away, restarting Docker Desktop is the lever.

**`docker buildx rm <builder>` does not delete that builder's state volume.** The
volume survives, and a recreated builder with the same name silently re-attaches
to it — so the cache you thought you deleted is still there and still counted.
This is why Stage 1 clears these builders with `docker buildx prune --builder`
instead: it empties the cache in place, with no volume surgery and nothing else
at risk. Only if that leaves a `buildx_buildkit_*_state` volume still holding
gigabytes is the heavier path — remove builder, prune the volume, recreate —
worth proposing, and it goes in the suggestions for approval because the same
volume prune would take the user's named database volumes with it.

**`docker system df` understates RECLAIMABLE for build cache.** Cache shared with
images that still exist isn't counted as reclaimable, so a cache that looks like
40MB of slack can be over 100GB once the stale images are gone. Re-check after
pruning images rather than trusting the first reading.

### Report format

Lead with the number the user cares about — how much you freed and what's free
now — then the ranked options.

```
Freed X GB. Now Y GB available (was Z GB).

  Stage 1 docker-cleanup-more   — freed A GB
  Stage 2 worktree cleanup      — freed B GB (or: skipped, reason)
  Stage 3 mo clean + optimize   — freed C GB

Remaining, largest first:
  1. <what it is> — <size> — <exact command> — <what breaks / what's lost>
  2. ...
```

Every suggestion needs the exact command you'd run, the realistic reclaim, and
the cost of being wrong — "rebuilds on next build" and "this is your local
database, it's gone" are very different risks and the user is choosing between
them. Rank by size, but call out anything cheap and safe near the top even if
it's small.

Then stop and wait. When the user picks, run exactly what they approved and
nothing adjacent.
