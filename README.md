# Plugin Updates

Tells you when your git-installed Omarchy shell plugins have upstream changes,
and lets you review and install them the Omarchy way: through
`omarchy plugin update`, which shows the diff and asks before applying each
one. There is no bar widget. Updates show up in the Omarchy menu and at the
end of `omarchy update`:

```
SUPER+SPACE → Plugin Updates          (only while updates are waiting)
SUPER+SPACE → Update → Plugins
SUPER+SPACE → Setup → Plugins → Update Plugins
omarchy update  →  … → "Plugin updates"
```

It watches the same plugins `omarchy plugin update` does: every directory in
`~/.config/omarchy/plugins/` that is a git checkout with an `origin`. It only
ever runs `git fetch origin HEAD`. Nothing in your plugin directories changes
until you confirm an update.

## How it works

- **Background check.** A headless `service` plugin runs
  `omarchy-plugin-updates check` 90 seconds after login and every 6 hours,
  the same cadence as Omarchy's own update indicator. It retries in 15 minutes
  if no remote was reachable. Results go to
  `~/.cache/omarchy-plugin-updates.json`.
- **Menu.** The root "Plugin Updates" row has a `when:` guard,
  `omarchy-plugin-updates pending -q`. It reads that cache and never touches
  the network, so opening the menu stays instant. It also notices updates you
  already installed by hand. The Update and Setup rows are always there and
  check the remotes when you pick them.
- **`omarchy update`.** A `post-update` hook runs `apply` in the update
  terminal. With `omarchy update -y`, which promises not to ask anything, it
  only lists what is waiting. The hook never fails the system update.
- **Applying.** `apply` lists each pending plugin's new commits, then hands
  each one to `omarchy plugin update <id>`: diff, confirm, fast-forward,
  validate, and roll back on failure. A plugin with local commits can't be
  fast-forwarded, so it is skipped with a note.

## Install (Omarchy)

```bash
omarchy plugin add https://github.com/Emanuel4100/omarchy-plugin-updates.git --enable
ln -sf ~/.config/omarchy/plugins/emanuel.plugin-updates/bin/omarchy-plugin-updates ~/.local/bin/
omarchy hook install post-update ~/.config/omarchy/plugins/emanuel.plugin-updates/extras/plugin-updates.hook
```

Then paste [`extras/omarchy-menu.jsonc`](extras/omarchy-menu.jsonc) into
`~/.config/omarchy/extensions/omarchy-menu.jsonc`. Nothing writes to that file
automatically. New root rows land after System, because the menu has no
ordering field.

Requires `git`, `jq`, and `flock`. All three come with Omarchy.

## Usage

```bash
omarchy-plugin-updates check [--quiet] [--offline] [id]   # fetch, then list what's new
omarchy-plugin-updates pending [-q]                       # from the cache, no network
omarchy-plugin-updates apply [id]                         # review and install, one by one
omarchy-shell emanuel.plugin-updates check                # ask the service to check now
omarchy-shell emanuel.plugin-updates status               # the cache, as JSON
```

`check` and `pending` exit 0 when updates are waiting and 1 when there are
none, like `omarchy-update-available`. `check` exits 2 when no remote could be
reached.

## Files

- `manifest.json`: plugin manifest (`kinds: ["service"]`)
- `Service.qml`: the background check timers and the IPC target
- `bin/omarchy-plugin-updates`: check, pending, apply, and the post-update
  logic. Symlink it into `~/.local/bin`.
- `extras/omarchy-menu.jsonc`: menu rows to paste into your extensions file
- `extras/plugin-updates.hook`: the `post-update` hook. It only calls the
  CLI, so fixes arrive with plugin updates.

## License

MIT
