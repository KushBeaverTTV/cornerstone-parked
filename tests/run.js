const assert = require("node:assert/strict")
const P = require("../Parked.js")

assert.equal(P.spaceLabel("special:minimized"), "Minimized")
assert.equal(P.spaceLabel("special:classifiedbench"), "classifiedbench")
assert.ok(P.appIconCandidates("chrome-muse.ai__-Default", "Chat").includes("google-chrome"))

const parsed = P.parseParked(JSON.stringify([
  { address: "0x1", workspace: { name: "1" }, class: "foot", title: "term" },
  { address: "0x2", workspace: { name: "special:classifiedbench" }, class: "Classified", title: "Classified", focusHistoryID: 1 },
  { address: "0x3", workspace: { name: "special:minimized" }, class: "discord", title: "Discord", focusHistoryID: 2 }
]))
assert.equal(parsed.length, 2)
assert.equal(parsed[0].address, "0x3")    // minimized sorted first
assert.equal(parsed[1].spaceLabel, "classifiedbench")
assert.equal(P.parseParked("{"), null)

console.log("PASS cornerstone.parked unit tests")
