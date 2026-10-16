import QtQuick
import Quickshell
import Quickshell.Io

// Headless. Keeps the plugin-update cache fresh so the Omarchy menu's
// "Plugin Updates" row can appear without the menu waiting on the network.
// It only fetches: updates are applied by `omarchy-plugin-updates apply`,
// which hands each one to `omarchy plugin update` (diff + confirm).
Item {
  id: root

  // Injected by the omarchy-shell host.
  property var shell: null

  // Resolved from this file, not hardcoded: `omarchy plugin add` names the
  // directory by manifest id, whatever the repo is called.
  readonly property string helperPath: String(Qt.resolvedUrl("bin/omarchy-plugin-updates")).replace(/^file:\/\//, "")
  readonly property string cachePath: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/omarchy-plugin-updates.json"

  function check() {
    if (!checkProc.running) checkProc.running = true
  }

  Process {
    id: checkProc
    command: ["bash", root.helperPath, "check", "--quiet"]
    // 2 = no remote reachable; right after login that is usually the network.
    onExited: function(exitCode) {
      if (exitCode === 2) retryTimer.restart()
    }
  }

  // First check shortly after login, then on the same 6 h cadence as
  // Omarchy's own update indicator.
  Timer {
    interval: 90000
    running: true
    onTriggered: root.check()
  }

  Timer {
    interval: 6 * 3600 * 1000
    running: true
    repeat: true
    onTriggered: root.check()
  }

  Timer {
    id: retryTimer
    interval: 15 * 60000
    onTriggered: root.check()
  }

  FileView {
    id: cacheFile
    path: root.cachePath
    blockLoading: true
    printErrors: false
  }

  IpcHandler {
    target: "emanuel.plugin-updates"

    function check(): void { root.check() }
    function status(): string {
      cacheFile.reload()
      return cacheFile.text() || "{}"
    }
  }
}
