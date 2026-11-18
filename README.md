# VigoBeatz SampQOL Stems + Grid64 Mod

**Unofficial MPC Sample expansion — BETA**

This mod adds a four-part stem-separation workflow (**drums, bass, vocals, and other**) and grid zoom up to **1/64** to a compatible, existing **SampQOL OS v0.3.0** installation.

Created by **VigoBeatz LLC** · [Website](https://vigobeatzmpc.web.app) · [YouTube](https://www.youtube.com/vigobeatz)

> **BETA:** The macOS launcher has opened successfully in user testing, but Windows installation and actual MPC Sample stem/grid operation are **not yet verified**. Use a spare SD card and back up your projects.

## Important: SampQOL is not included

This mod does **not** include a complete SampQOL distribution or unmodified original SampQOL binary. You must install **stock SampQOL OS v0.3.0** yourself before applying this mod.

The mod-only installer uses version-specific binary patches plus added stem-processing assets. It checks the original file hashes and rejects unsupported versions or previously modified files.

## Download

Get the **complete mod-only installer ZIP** from VigoBeatz's authorized download location (link to be added when published). It must contain the `manifest.json` and `payload/` directory along with the installer scripts. **GitHub's source-code ZIP alone is not a functioning installer if the payload is absent.**

The complete package is larger than GitHub's 100 MB normal repository-file limit. The host installer requires no Python or Tkinter. The mod payload contains Linux ARM binaries and audio models used on the MPC Sample.

## Requirements

- Akai MPC Sample and SD card with **unmodified SampQOL OS v0.3.0**
- Windows with PowerShell **or** macOS with its system Perl and required standard modules
- The **complete, extracted** VigoBeatz mod-only ZIP
- A separate backup of the entire SD card and projects

## Install on macOS

1. Back up your whole SampQOL SD card and insert it into your Mac.
2. Download and **extract** the complete mod-only installer ZIP.
3. Open **Terminal** inside the extracted installer folder.
4. Run:

   ```sh
   sh ./Install-Mac.command
   ```

5. Enter the **SD card root**, such as `/Volumes/NO NAME` (not `/Volumes/NO NAME/autorun`).
6. Type `INSTALL` at the prompt.
7. Wait for the success message, eject the SD card safely, and test on the MPC Sample.

**Gatekeeper warning:** Finder may block unsigned `.command` files. Inspect the script and use the Terminal command above; alternatively, the **Open Anyway** control may appear in **System Settings → Privacy & Security**. Do **not** disable Gatekeeper globally.

**macOS dependencies:** The script runs `/usr/bin/perl` and uses `JSON::PP`, `Digest::SHA`, `Compress::Zlib`, `File::Path`, `File::Copy`, and `File::Basename`. If these are not available, installation fails; nothing is downloaded automatically.

## Install on Windows

1. Back up your whole SampQOL SD card and insert it into your Windows computer.
2. Download and **extract** the complete mod-only ZIP.
3. Open **PowerShell** in the extracted installer folder.
4. Run:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Windows.ps1
   ```

5. Enter the **SD card root**, for example `E:\` (not `E:\autorun`).
6. Type `INSTALL` at the prompt.
7. Wait for the success message, safely eject the card, and test on your MPC Sample.

The execution-policy option applies only to the launched PowerShell process, not your global settings. **Windows install behavior is not yet validated.** Review scripts before running them.

## Restore / uninstall

To undo the mod, insert the same SD card and **run the same installer again**, but type **`RESTORE`** instead of `INSTALL`. The installer uses `VigoBeatz-Backup-SampQOL-v0.3.0` on the SD card to restore backed-up original files and remove files it created. Keep that backup directory intact until you have restored. Keep your separate full-card backup too.

## Troubleshooting

| Issue | What to do |
| --- | --- |
| SampQOL not found | Select the card **root**, not `autorun/`. |
| Unsupported binary | Only the exact supported, unmodified SampQOL v0.3.0 file hash is accepted. |
| Original file mismatch | Existing startup files differ; do not force-install. |
| Existing backup detected | Run `RESTORE` before another installation attempt. |
| Corrupt patch / asset mismatch | Re-extract the entire complete mod installer ZIP. |
| Mac blocks the launcher | Inspect the script and launch from Terminal as shown above. |
| Stems or grid features do not work on-device | Record firmware/version details and the reproduction steps; hardware behavior is not yet verified. |

## Beta validation status

| Area | Status |
| --- | --- |
| macOS launcher | Confirmed to open in user testing |
| Simulated SD-card installation and restoration | Previously tested |
| Windows installation | Not yet verified |
| On-device stems and 1/64 grid operation | Not yet verified |
| Third-party model and runtime redistribution rights | Require review before public release |

## Licensing and attribution

This is an **unofficial community project**, not affiliated with or endorsed by Akai, inMusic, or SampQOL's developer. No original SampQOL distribution is included. Original SampQOL files, third-party models, runtime binaries, and related components remain subject to their respective rights and licenses. Review the bundled third-party notices and independently confirm redistribution permissions before publishing the complete payload. ONNX Runtime notices alone do not establish the rights to redistribute the stem models.

© VigoBeatz LLC — [vigobeatzmpc.web.app](https://vigobeatzmpc.web.app)
