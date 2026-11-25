# Cornerstone Parked

Auto-hiding status bar pill for minimized and `special:*` Hyprland workspace windows.

- **Bar pill**: takes `0 px` when nothing is parked; appears automatically as `󰖰 N` via `Hyprland.rawEvent` (zero idle polling).
- **Clicks**: left-click opens the drawer with desktop icons and workspace tags; right-click restores all minimized windows.

## Tests

```bash
node tests/run.js
```
