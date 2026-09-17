# Perch

A featherweight, borderless Pomodoro HUD and focus timer for Windows, written in the [Tungsten](https://github.com/LeTrollologist/Tungsten) systems programming language.

Perch floats quietly in the corner of your screen—always on top, minimal distraction, zero fluff.

![Perch Preview](assets/preview.png)

---

## Highlights

- **Floating HUD**: Borderless, topmost overlay that sits right where you want it without stealing focus.
- **3-Stage Cycle**: Seamlessly transitions between **Focus** (25m), **Short Break** (5m), and **Long Break** (15m) with distinct color themes.
- **Session Progress Tracker**: Visual completion indicators (`● ● ○ ○`) track sets of focus sessions until your next extended break.
- **Mouse Wheel Time Tweaks**: Scroll up/down over the HUD to adjust remaining time on the fly by +/- 1 minute.
- **Instant Alarm Dismissal**: When the timer reaches 00:00, the HUD flashes red and chimes periodically; any click or hotkey silences and acknowledges the alarm.
- **Configurable Settings & Hotkeys**: Customize durations, alert audio, and custom keybindings via `perch.ini`. Press `S` to instantly open and edit your configuration.
- **Zero Baggage**: No webview, no electron, no frameworks. Pure native Win32 GDI calls compiled into a single self-contained binary.

---

## Stats

| Metric | Perch |
| :--- | :--- |
| **Language** | [Tungsten](https://github.com/LeTrollologist/Tungsten) |
| **Binary Size** | ~60 KB |
| **RAM Footprint** | < 2 MB |
| **Startup Time** | < 1 ms |
| **External Dependencies** | Zero (Native Win32 only) |

---

## Controls & Custom Bindings

All controls and keybindings can be customized in `perch.ini`.

### Mouse Controls

| Action | Control |
| :--- | :--- |
| **Pause / Resume** | Left Click |
| **Reset Timer** | Right Click (resets current mode & reloads settings) |
| **Cycle Mode** | Middle Click (cycles Focus → Short Break → Long Break) |
| **Adjust Time** | Mouse Wheel Up (+1m) / Mouse Wheel Down (-1m) |
| **Reposition HUD** | `Shift` + Left Click Drag (drag anywhere across displays) |
| **Quick Exit** | Double Right Click |

### Keyboard Shortcuts (Configurable)

| Key | Default Key | Action |
| :--- | :---: | :--- |
| `key_pause` | `Space` (32) | Pause / Resume current countdown |
| `key_reset` | `R` (82) | Reset timer to full duration & reload settings |
| `key_cycle_mode` | `M` (77) | Switch to next interval mode |
| `key_settings` | `S` (83) | Open `perch.ini` in text editor |
| `key_quit` | `Q` (81) / `Esc` (27) | Dismiss alarm / Clean exit |

---

## Configuration (`perch.ini`)

Perch automatically creates a well-commented `perch.ini` file in the application directory on first launch:

```ini
[Timer]
; Durations in minutes
focus_mins = 25
short_break_mins = 5
long_break_mins = 15

; Completed focus sessions before automatically suggesting a long break
sessions_until_long_break = 4

; Audio alarm sound on completion (1 = enabled, 0 = silent)
sound_enabled = 1

; Auto-start next countdown on interval switch (1 = auto, 0 = manual start)
auto_start = 0

[Display]
width = 175
height = 54
margin_top = 20
margin_right = 20

[Bindings]
; Windows Virtual-Key codes:
key_pause = 32
key_reset = 82
key_cycle_mode = 77
key_settings = 83
key_quit = 81
```

---

## Building from Source

Requires the [Tungsten](https://github.com/LeTrollologist/Tungsten) compiler (`tgc.exe`).

Clone the repository and compile using `build.bat`:

```cmd
git clone https://github.com/LeTrollologist/Perch.git
cd Perch
build.bat
```

Or invoke the Tungsten compiler directly:

```powershell
..\Tungsten\bin\tgc.exe build perch.tg -o perch.exe
```

---

## License

[MIT](LICENSE) © [LeTrollologist](https://github.com/LeTrollologist)
