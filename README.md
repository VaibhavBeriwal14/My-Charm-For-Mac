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
| **Focus timer** | 5 / 15 / 25 / 45 / 60 minute sessions. The countdown shows in the menu bar **and on a little widget hanging under the charm** that swings, tilts and drags along with it. When time's up the charm swings, a wind chime plays, and the widget says *Done!* |
| **Launch at login** | One click from the menu. |
| **Command-line charm picker** | `bash charm.sh NIMBU_MIRCH` |

All settings are remembered between launches.

---

## Install (one line)

Open **Terminal** (press ⌘ Space, type *Terminal*, press Return), paste this, and press Return:

```bash
curl -fsSL https://raw.githubusercontent.com/VaibhavBeriwal14/My-Charm-For-Mac/main/install.sh | bash
```

That's it. The charm appears at the top of your screen within a few seconds, and a ✦ icon shows up in the menu bar.

- Installs **My Charm** into your Applications folder and starts it
- Turns on **Launch at Login**, so the charm comes back after a restart (switch off in the ✦ menu)
- Leaves nothing in your Downloads folder
- No Xcode, git or developer tools needed
- **To update**, run the same command again

**Start with a specific charm:**

```bash
curl -fsSL https://raw.githubusercontent.com/VaibhavBeriwal14/My-Charm-For-Mac/main/install.sh | bash -s -- NIMBU_MIRCH
```

Requirements: macOS 13 Ventura or later, on an Apple Silicon or Intel Mac.

> Curious what the installer does? Read [`install.sh`](install.sh). It's short and commented.

---

## Build from source (for developers)

Needs the Xcode **Command Line Tools** (about 1 GB, free). Full Xcode is not needed.

```bash
xcode-select --install        # skip if already installed
git clone https://github.com/VaibhavBeriwal14/My-Charm-For-Mac.git
cd My-Charm-For-Mac
bash build.sh
bash charm.sh                 # runs it; also updates /Applications if you installed there
```

Every push to `main` that changes the app code automatically builds a universal (Apple Silicon + Intel) app and publishes it as a [GitHub Release](../../releases). The one-line installer always downloads the newest release.

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
My-Charm-For-Mac/
├── .github/workflows/release.yml  # auto-builds a release on every push
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
├── install.sh              # one-line installer (curl … | bash)
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
| Launch at Login shows an error | Make sure the app is in `/Applications` (the one-line installer does this) |
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
