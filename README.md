# VigoBeatz SampQOL Stems + Grid64 Mod

**Unofficial MPC Sample modification — BETA**

Adds a four-part **stem separation** workflow (drums, bass, vocals, and other) and **1/64 grid zoom** to a compatible installation of **SampQOL OS v0.3.0**.

Developed by **VigoBeatz LLC**  
[Website](https://vigobeatzmpc.web.app) · [YouTube](https://www.youtube.com/vigobeatz)

> **Beta notice:** The macOS installer launcher has been opened successfully, and the installer has undergone simulated SD-card tests. Windows installation and operation on an actual MPC Sample have not yet been fully verified. **Use a spare SD card and back up your projects and card first.**

## Download the mod

**All installer files and the mod payload are already in this repository.** You do **not** need to download a separate payload.

1. At the top of this repository, click the green **Code** button.
2. Select **Download ZIP**.
3. Extract the ZIP fully to a folder on your computer.
4. Follow the instructions below for your operating system.

Alternatively, clone the repository:

```sh
git clone https://github.com/AldanisVigo/VigoBeatz-SampQOL-Stems-Grid64-Mod.git
```

**Important:** Keep the extracted folder structure intact. The installation scripts expect `manifest.json` and the `payload/` directory alongside them. Do not move the script out of the extracted folder or run it from inside an unextracted ZIP.

### What's in this repository?

```text
VigoBeatz-SampQOL-Stems-Grid64-Mod/
├── Install-Mac.command       # macOS launcher
├── installer-mac.pl          # macOS installation and restore logic
├── Install-Windows.ps1       # Windows PowerShell installer
├── manifest.json            # Version checks and file hashes
├── payload/
│   ├── patches/             # Version-specific patches
│   └── new/                 # Added mod files and stem components
└── README.md
```

The repository provides **the mod and its installer, not the full original SampQOL OS**. You must install an authentic, unmodified SampQOL OS v0.3.0 on your SD card first.

## Requirements

- **Akai MPC Sample**.
- SD card containing **stock (unmodified) SampQOL OS v0.3.0**.
- A computer running **macOS or Windows** and an SD card reader.
- Enough free space for the stem models, mod files, and backup.
- A **separate full backup** of your SD card before installation.

The installation scripts require **no Python, Tkinter, or third-party installer application**. macOS uses its shell and system Perl; Windows uses PowerShell. The **MPC-side** stem processing payload contains native code and audio model files; “script-only” refers to the installer on your computer.

The installer checks original file hashes and will reject incompatible or previously modified SampQOL versions rather than patching them blindly.

## Installation — macOS

1. Install **unmodified SampQOL OS v0.3.0** onto the SD card using its official instructions.
2. **Back up** the entire SD card on your Mac.
3. Download this repository using **Code → Download ZIP** and extract it completely.
4. Insert the SampQOL SD card into your Mac. Its path will usually look like `/Volumes/NO NAME` (your card name may differ).
5. Open the extracted folder and double-click **`Install-Mac.command`**. If macOS blocks the script, follow the security instructions below.
6. At the prompt, enter the **root of the SD card** (for example, `/Volumes/NO NAME`), **not** `/Volumes/NO NAME/autorun`.
7. Type **`INSTALL`** and press Return.
8. Allow the checks, backup, patching, and verification to complete. Look for a **SUCCESS** message before ejecting the card.
9. Eject the SD card safely and test it on your MPC Sample.

### macOS says it can't verify the script

Downloaded `.command` scripts sometimes trigger macOS security checks. **Do not disable Gatekeeper globally.** After reviewing the script, you can:

- Open **System Settings → Privacy & Security** and use **Open Anyway**, if macOS offers it; or
- Open **Terminal**, navigate to the extracted repository folder, and run:

```sh
sh ./Install-Mac.command
```

The script still runs normally and prompts for the SD card location. macOS requires `/usr/bin/perl` and standard modules used by `installer-mac.pl`; it will report an error if they are not available.

## Installation — Windows

1. Install **unmodified SampQOL OS v0.3.0** onto the SD card using its official instructions.
2. **Back up** the entire SD card on your PC.
3. Download this repository using **Code → Download ZIP** and extract it completely.
4. Insert the SD card and note its drive letter (such as `E:`).
5. Open **PowerShell** in the extracted repository folder.
6. Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Windows.ps1
```

7. Enter the **root of the SD card** (for example, `E:\`) and type **`INSTALL`** when prompted.
8. Wait for the **SUCCESS** message, safely eject the card, and test it on your MPC Sample.

**Security note:** The `-ExecutionPolicy Bypass` switch applies only to the PowerShell process launched by that command; it does not permanently change your system-wide PowerShell settings. Review downloaded scripts before executing them. Windows installation is **beta/unverified**.

## Restoring original SampQOL files (uninstall)

The installer creates an on-card backup at:

```text
VigoBeatz-Backup-SampQOL-v0.3.0/
```

To undo the mod:

1. Insert the same SD card and open the same installer folder on your computer.
2. Launch **`Install-Mac.command`** on macOS or run **`Install-Windows.ps1`** on Windows using the instructions above.
3. Enter the SD card root.
4. When asked for an action, type **`RESTORE`** instead of `INSTALL`.
5. Wait for the restoration message before safely ejecting the card.

Restoration reverts the files backed up during installation and removes files created by the mod. **Do not delete the backup folder until you are sure you won't need it.** Keep your separate full SD-card backup as an additional safeguard.

## How to use / verify the features

**Stem separation:** The intended mod workflow generates four parts: **drums**, **bass**, **vocals**, and **other**. On the installed card, the stem-processing workflow uses a `Stems/` working area and can report status to `Stems/STATUS.txt`. Exact UI controls and pad assignments must be verified on actual MPC Sample hardware; do not rely on the host installation success message as proof the processing feature works.

**Grid64:** The intended expanded grid zoom reaches **1/64**. Verify the selectable zoom values and playback/editing behavior on the device before relying on the mod for important projects.

## Troubleshooting

| Problem | What to do |
| --- | --- |
| “No SampQOL found” | Select the SD card **root**, not the `autorun` directory. |
| “Unsupported SampQOL binary” | The installer only accepts the **exact stock v0.3.0 file hash** in `manifest.json`. |
| “Original file mismatch” | Your installation differs from the expected stock release. Don't force the patch. |
| “Existing backup detected” | Use the **RESTORE** operation first. |
| “Corrupt patch”, “Asset mismatch”, or missing `payload/` | Re-extract the **complete GitHub repository ZIP** and keep its folder structure intact. |
| macOS blocks `Install-Mac.command` | Review and run it through Terminal using the command above. |
| Stems don't work after installation | Preserve your source sample; note the device firmware, SampQOL version, and any `Stems/STATUS.txt` or log messages. |
| Need to remove the mod | Run the installer with **RESTORE**. |

## Compatibility and testing status

| Component | Status |
| --- | --- |
| Target SampQOL version | **v0.3.0**, exact stock hashes required |
| macOS installer launch | **Confirmed to open** |
| Simulated SD-card install and restore | Previously tested |
| Windows installation | **Not yet hardware/host-verified** |
| MPC Sample stem separation | **Not fully hardware-verified** |
| MPC Sample 1/64 grid operation | **Not fully hardware-verified** |

Please report reproducible issues in the repository's [Issues](https://github.com/AldanisVigo/VigoBeatz-SampQOL-Stems-Grid64-Mod/issues) section. Include your host operating system, original SampQOL version, MPC firmware version, and the precise error message, but **do not post private files or personal information**.

## Credits, rights, and disclaimer

This is an **unofficial community modification**, not affiliated with or endorsed by Akai, inMusic, or the SampQOL author. The original SampQOL software is **not bundled** here; users must obtain it separately.

The included mod patch data, model files, and native dependencies may be subject to different licenses and redistribution requirements. Public GitHub availability does **not** override third-party rights. Review the licenses, notices, and permissions for each redistributed component before promoting a final public release.

**VigoBeatz LLC** · [vigobeatzmpc.web.app](https://vigobeatzmpc.web.app)
