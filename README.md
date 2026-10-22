# My Charm: a swinging desktop charm for Mac

**My Charm** is a free, open-source macOS menu bar app that hangs a lucky charm from the top of your screen on a physics-driven string. Flick it, drag it, or let it sway while you work.

It ships with an **evil eye (Nazar)** and a **Nimbu Mirch (lemon and green chillies)** charm, and you can turn **any image into a charm** in seconds: a photo, a logo, a pet, a lucky symbol. A free, build-it-yourself alternative to paid screen-charm apps.
- Free and open source
- Runs fully offline, no account, no tracking
- Native Swift/AppKit, no dependencies, uses barely any CPU when the charm is at rest

---

## Features

| | |
|---|---|
| **Physics swing** | Verlet-rope simulation. Drag the charm and let go to flick it, or hover over it to brush it along. |
| **Click-through** | Only the charm catches the mouse. Everything else on screen works normally. |
| **Charm library** | Built-in NAZAR and NIMBU_MIRCH, plus any images you add. |
| **Custom charms** | Use any PNG/JPG/HEIC. Transparent PNGs look best. |
| **String styles** | Classic Thread, Silver Chain, Gold Chain. |
| **Adjustable** | Sliders for charm size, string length, and position across the screen. |
| **Focus timer** | 5 / 15 / 25 / 45 / 60 minute sessions with a countdown in the menu bar. When time's up the charm swings and a wind chime plays. |
| **Launch at login** | One click from the menu. |
| **Command-line charm picker** | `bash charm.sh NIMBU_MIRCH` |

All settings are remembered between launches.

---

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel Mac
- Xcode **Command Line Tools** (about 1 GB, free). Full Xcode is not needed.

---

## Install

```bash
# 1. Install the Command Line Tools (skip if you already have them)
xcode-select --install

# 2. Download the code
git clone https://github.com/VaibhavBeriwal14/My-Charm-For-Mac.git
cd My-Charm-For-Mac

# 3. Build
bash build.sh

# 4. Run
open "build/My Charm.app"
```

You should see the charm hanging just below the menu bar, and a ✦ icon in the menu bar.

**Keep it permanently** (optional):

```bash
mv "build/My Charm.app" /Applications/
```

Then open it from Applications and choose **✦ → Launch at Login**.

> Once built, the app runs on its own. You don't need Terminal or the Command Line Tools to keep using it.

---

## Usage

Click the **✦** icon in the menu bar:

| Menu item | What it does |
|---|---|
| Hide / Show Charm | Hides the charm without quitting |
| Reset Swing | Stops the charm and lets it hang straight |
| Charm ▸ | Pick a charm, add an image, or open the charms folder |
| String ▸ | Classic Thread / Silver Chain / Gold Chain |
| Charm Size / String Length / Position | Live sliders |
| Focus Timer ▸ | Start a session, stop it, or test the chime |
| Launch at Login | Start automatically when you log in (app must be in /Applications) |
| Quit My Charm | Quit |

### Choosing a charm from Terminal

```bash
bash charm.sh NIMBU_MIRCH
bash charm.sh NAZAR
bash charm.sh            # defaults to NAZAR
```

`charm.sh` restarts the app with the charm you name. Names aren't case-sensitive. It uses `/Applications/My Charm.app` if it exists, otherwise the copy in `build/`.

You can also pass the charm straight to the app:

```bash
open "build/My Charm.app" --args --charm NIMBU_MIRCH
```

---

## Adding your own charms

A charm is just an image. Its **filename becomes its name**: `HAMSA.png` shows up as `HAMSA`.

**Tip:** use a transparent PNG with the subject cropped tight. The top edge of the image is where the string attaches. Any size works, though about 300–600 px tall looks sharp on Retina screens.

### Option 1: from the app (no rebuild)

**✦ → Charm → Add Image…** and pick one or more images. They're copied to
`~/Library/Application Support/MyCharm/Charms/` and appear in the menu straight away.

### Option 2: drop into the folder (no rebuild)

**✦ → Charm → Open Charms Folder**, and copy images in. They appear the next time you open the menu. To remove a charm, delete its file from this folder.

### Option 3: bundle it into the app (rebuild needed)

Put the image in this repo's `Charms/` folder and run `bash build.sh` again. Use this if you want the charm to ship with the app, for example in a pull request.

---

## Project structure

```
my-charm/
├── Sources/
│   ├── main.swift          # app entry point
│   ├── AppDelegate.swift   # overlay window, menu bar, focus timer, launch arguments
│   ├── CharmView.swift     # drawing (string, chain, charm) and mouse handling
│   ├── Rope.swift          # Verlet rope physics
│   ├── CharmLibrary.swift  # loads bundled + user charms
│   ├── Settings.swift      # saved preferences
│   └── Chime.swift         # synthesised wind chime, no audio file needed
├── Charms/                 # images bundled into the app
├── Info.plist
├── build.sh                # builds "build/My Charm.app"
└── charm.sh                # restart the app with a chosen charm
```

### Tweaking the physics

In `Sources/Rope.swift`:

- `gravity` sets how heavy the swing feels
- `damping` sets how long it keeps swinging (closer to `1.0` swings longer)
- `count` sets the number of rope segments

Rebuild with `bash build.sh` after any code change.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `xcrun: error: invalid active developer path` | Run `xcode-select --install` |
| Build fails after a macOS/Xcode update | `sudo xcode-select --reset`, then build again |
| "Unknown charm" printed | Check the name matches the image filename. Run the app and look under **✦ → Charm** for the exact names |
| Launch at Login shows an error | Move the app into `/Applications` first |
| Charm not visible | **✦ → Show Charm**, then **Reset Swing**, and check the Position slider |
| macOS says the app can't be opened | Right-click the app → **Open**. This only happens if you downloaded a pre-built `.app` rather than building it yourself |

### Uninstall

```bash
pkill -x MyCharm
rm -rf "/Applications/My Charm.app"
rm -rf ~/Library/Application\ Support/MyCharm
defaults delete com.vaibhav.mycharm
```

---

## Contributing

Pull requests are welcome, especially new charms (add them to `Charms/`) and new string styles.

## License

[MIT](LICENSE)
