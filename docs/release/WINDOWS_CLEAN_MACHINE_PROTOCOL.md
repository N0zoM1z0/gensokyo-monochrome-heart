# Windows Clean-Machine Release Protocol

The repository can export and hash a `windows-x86_64` release candidate from
Linux, but this host cannot execute a Windows binary. Do not treat a successful
cross-export as a Windows compatibility claim.

Run this protocol on a fresh Windows 10/11 x86_64 user account or disposable VM:

1. Copy only the candidate package directory; do not copy project sources or a
   prior user data directory.
2. Check every entry in `SHA256SUMS` with a SHA-256 utility.
3. Start `gensokyo-monochrome-heart.exe`; reach title, create a profile, choose
   EN and JA, and quit normally.
4. Restart the executable and confirm the settings/profile state behaves as
   expected in its `gmh_release` namespace.
5. Rename or remove only the package directory. Confirm it required no registry
   entry, installer service, administrator privilege, or system-wide component.
6. Preserve the Windows version, GPU/driver category, test account type,
   candidate manifest, smoke log, result, and any error code in the release
   archive. Do not attach full saves or personal paths by default.

The public-release decision remains blocked until this evidence is recorded.
