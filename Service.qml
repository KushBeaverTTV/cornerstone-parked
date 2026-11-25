import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "Parked.js" as Parked

// Single session-wide service for Cornerstone Parked: watches Hyprland events
// (zero idle polling) to track windows parked in `special:*` workspaces
// (special:minimized, special:classifiedbench, etc.) and restores or closes them.
Item {
  id: service

  property var shell: null
  readonly property string pluginId: "cornerstone.parked"

  property var windows: []
  readonly property int count: windows.length
  readonly property int minimizedCount: windows.filter(function(w) { return w.minimized }).length

  function refresh() {
    if (!listProc.running) listProc.running = true
  }

  function restore(address) {
    var a = String(address || "")
    if (!/^0x[0-9a-fA-F]+$/.test(a)) return
    Quickshell.execDetached(["sh", "-c",
      'here=$(hyprctl activeworkspace -j 2>/dev/null | jq -r ".id"); ' +
      'printf "%s" "$here" | grep -qxE "[0-9]+" || exit 1; ' +
      't="window = \\"address:$1\\""; ' +
      'hyprctl dispatch "hl.dsp.window.move({ workspace = \\"$here\\", $t })" >/dev/null 2>&1 || hyprctl dispatch movetoworkspacesilent "$here,address:$1" >/dev/null; ' +
      'hyprctl dispatch "hl.dsp.focus({ $t })" >/dev/null 2>&1 || hyprctl dispatch focuswindow "address:$1" >/dev/null',
      "sh", a])
    settle.restart()
  }

  function restoreAllMinimized() {
    var list = windows.filter(function(w) { return w.minimized })
    for (var i = 0; i < list.length; i++) restore(list[i].address)
  }

  function closeWindow(address) {
    var a = String(address || "")
    if (!/^0x[0-9a-fA-F]+$/.test(a)) return
    Quickshell.execDetached(["sh", "-c",
      'hyprctl dispatch "hl.dsp.window.close({ window = \\"address:$1\\" })" >/dev/null 2>&1 || hyprctl dispatch closewindow "address:$1" >/dev/null',
      "sh", a])
    settle.restart()
  }

  Process {
    id: listProc
    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parsed = Parked.parseParked(this.text)
        if (parsed !== null) service.windows = parsed
      }
    }
  }

  Timer {
    id: settle
    interval: 180
    onTriggered: service.refresh()
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var n = event ? String(event.name || "") : ""
      if (n === "openwindow" || n === "closewindow" || n === "movewindow" || n === "movewindowv2"
          || n === "windowtitle" || n === "windowtitlev2" || n === "activespecial") {
        settle.restart()
      }
    }
  }

  Component.onCompleted: refresh()

  IpcHandler {
    target: "cornerstone-parked"

    function toggle(): string { if (service.shell) service.shell.toggle(service.pluginId); return "ok" }
    function refresh(): string { service.refresh(); return "ok" }
  }
}
