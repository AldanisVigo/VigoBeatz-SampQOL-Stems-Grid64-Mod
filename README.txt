VigoBeatz Stems + Grid64 Mod — SCRIPT-ONLY BETA

This ZIP contains ONLY mod assets, binary delta patches, and installer scripts.
It does not contain the original SampQOL binary or complete SampQOL installation.
It requires an existing, unmodified SampQOL OS v0.3.0 SD card.

MAC: Open Terminal, navigate to the extracted folder, then run:
  sh Install-Mac.command
The script uses the operating system's Perl interpreter and standard modules.
Some macOS versions may not include all needed Perl modules; if so, installation will stop.

WINDOWS: Open PowerShell, navigate to the extracted folder, then run:
  powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Windows.ps1
Do not run unknown scripts. Review this script before running it.

When prompted, enter the SD card ROOT (not the autorun folder), then INSTALL.
To undo, rerun and choose RESTORE. Backups remain on the SD card.

IMPORTANT: Beta. The scripts have not been validated on Windows/macOS hosts or
verified on actual MPC Sample hardware. Use a spare SD card and independently
back up all projects before attempting installation.

No installer executable or Python/Tkinter is bundled. The mod itself includes
native Linux ARM binaries/libraries needed to run on MPC hardware.
Review all bundled model and third-party component licenses before redistribution.
