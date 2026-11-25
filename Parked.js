// Pure parsing & formatting helpers for Cornerstone Parked.

function spaceLabel(wsName) {
  var s = String(wsName || "")
  if (s === "special:minimized") return "Minimized"
  if (s.indexOf("special:") === 0) return s.slice(8)
  return s
}

function appIconCandidates(cls, title) {
  var out = []
  function add(v) {
    var s = String(v || "").trim()
    if (!s) return
    if (out.indexOf(s) === -1) out.push(s)
    var slug = s.toLowerCase().replace(/[^a-z0-9._-]+/g, "-").replace(/^[-.]+|[-.]+$/g, "")
    if (slug && out.indexOf(slug) === -1) out.push(slug)
  }
  var c = String(cls || "")
  add(c)
  if (/^chrome-muse\.ai/i.test(c)) { add("muse-agent"); add("google-chrome") }
  else if (/^chrome-127\.0\.0\.1/i.test(c)) { add("cornerstone-hq"); add("google-chrome") }
  else if (/^chrome-/i.test(c)) add("google-chrome")
  else if (/discord/i.test(c)) add("discord")
  add(title)
  return out
}

function parseParked(text) {
  var list
  try { list = JSON.parse(String(text || "")) } catch (e) { return null }
  if (!Array.isArray(list)) return null
  var out = []
  for (var i = 0; i < list.length; i++) {
    var w = list[i]
    var ws = w && w.workspace ? String(w.workspace.name || "") : ""
    if (ws.indexOf("special:") !== 0) continue
    var addr = String(w.address || "")
    if (!/^0x[0-9a-fA-F]+$/.test(addr)) continue
    out.push({
      address: addr,
      workspace: ws,
      spaceLabel: spaceLabel(ws),
      minimized: ws === "special:minimized",
      appClass: String(w["class"] || w.initialClass || "").slice(0, 80),
      title: String(w.title || w["class"] || "Window").slice(0, 120),
      focusHistoryID: Number(w.focusHistoryID) || 0
    })
  }
  out.sort(function(a, b) {
    if (a.minimized !== b.minimized) return a.minimized ? -1 : 1
    if (a.workspace !== b.workspace) return a.workspace.localeCompare(b.workspace)
    return a.focusHistoryID - b.focusHistoryID
  })
  return out
}

if (typeof module !== "undefined") {
  module.exports = {
    spaceLabel: spaceLabel,
    appIconCandidates: appIconCandidates,
    parseParked: parseParked
  }
}
