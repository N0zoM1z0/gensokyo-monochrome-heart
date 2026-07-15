# Engine Lock

- Engine: Godot Engine
- Version: `4.7.1-stable`
- Runtime version string: `4.7.1.stable.official.a13da4feb`
- Upstream release date: 2026-07-14
- Upstream artifact: `Godot_v4.7.1-stable_linux.x86_64.zip`
- Artifact SHA-512: `4ccdab7a48eeccbe8819a2fc1f6262f8d72065d98601bcb3743fcbd7ebd39f373758a788ee3293a05ec5b2c48538266c437404312e372225cd2df273945a2de9`

Development and CI must use the exact `4.7.1-stable` patch until an approved architecture decision changes the lock. Preview, beta, RC, and unversioned system packages are not accepted.

Install the verified Linux editor with:

```bash
GMH_USE_CLASH=1 ./scripts/install_godot.sh
```

The script installs into the user directory by default and does not require `sudo`.
