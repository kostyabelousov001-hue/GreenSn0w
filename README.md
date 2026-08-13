<p align="center">
  <img src="https://github.com/kostyabelousov001-hue/GreenSn0w/assets/52459150/ed04dd3e-d879-456d-9aa3-d4ed44819c7e" width="64" />
</p>

<h1 align="center">GreenSn0w</h1>

<p align="center">
  A semi-untethered rootless jailbreak for iOS 15.0&ndash;18.7.9 and 26.0&ndash;26.0.1
</p>

<p align="center">
  <a href="https://github.com/kostyabelousov001-hue/GreenSn0w/actions/workflows/main.yml">
    <img src="https://img.shields.io/github/actions/workflow/status/kostyabelousov001-hue/GreenSn0w/main.yml?label=build" alt="Build" />
  </a>
  <a href="https://github.com/kostyabelousov001-hue/GreenSn0w/releases">
    <img src="https://img.shields.io/github/v/release/kostyabelousov001-hue/GreenSn0w?label=release" alt="Release" />
  </a>
  <a href="https://github.com/kostyabelousov001-hue/GreenSn0w">
    <img src="https://img.shields.io/github/last-commit/kostyabelousov001-hue/GreenSn0w" alt="Last commit" />
  </a>
  <img src="https://img.shields.io/badge/iOS-15.0--18.7.9%20%7C%2026.0--26.0.1-blue" alt="iOS support" />
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/kostyabelousov001-hue/GreenSn0w" alt="License" />
  </a>
</p>

## Features

- Semi-untethered: jailbreak survives reboots, requires re-jailbreaking after every boot
- Rootless: jailbroken apps and tweaks run from `/var/jb`
- GreenSword kernel exploit with native iOS 18.7.2&ndash;18.7.9 support
- Sileo and Zebra package managers bundled
- Terminal-style jailbreak log UI
- Localizations for 26 languages
- Fully open source, built entirely on GitHub Actions

## Compatibility

| Device | iOS |
| ------ | --- |
| iPhone XS, XS Max, XR, 11, 11 Pro, 11 Pro Max (A12/A13) | 15.0 &ndash; 18.7.9, 26.0 &ndash; 26.0.1 |

Older versions are not supported. Always update to the latest iOS version
currently signed by Apple.

## Installing

1. Download the latest `GreenSn0w.ipa` from the [releases page](https://github.com/kostyabelousov001-hue/GreenSn0w/releases)
2. Sideload it with any tool of your choice (e.g. TrollStore, AltStore, Sideloadly)
3. Open the app, wait for the jailbreak to complete
4. Done!

## Building

Builds are fully automated via GitHub Actions; the latest build is available as
the `GreenSn0w` artifact of the [build workflow](https://github.com/kostyabelousov001-hue/GreenSn0w/actions/workflows/main.yml).

To build locally (macOS):

```bash
git clone --recursive https://github.com/kostyabelousov001-hue/GreenSn0w
cd GreenSn0w
gmake -j$(sysctl -n hw.logicalcpu) NIGHTLY=1
```

The output IPA is at `Application/GreenSn0w.ipa`.

## Security

This tool is provided for educational and research purposes only. Jailbreaking
modifies the security model of your device. Use at your own risk.

## Credits

- [opa334](https://infosec.exchange/@opa334) — original Dopamine project
- [xina520](https://github.com/xina520) — DarkSword kernel exploit
- ElleKit by [évelyne](https://github.com/evelyneee)
- Procursus bootstrap team

## License

[MIT](LICENSE) &copy; 2023-2024 Lars Fröder (opa334) and 2026 kostyabelousov001-hue.
