# ReVanced Magisk Module + Blackmagic Camera Patches
[![Telegram](https://img.shields.io/badge/Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/rvc_magisk)
[![CI](https://github.com/j-hc/revanced-magisk-module/actions/workflows/ci.yml/badge.svg?event=schedule)](https://github.com/j-hc/revanced-magisk-module/actions/workflows/ci.yml)

Extensive ReVanced builder with **Blackmagic Camera custom patches**

## 🎥 Blackmagic Camera Support

This fork includes custom patches for **Blackmagic Camera** with:
- ✅ Package name change (co-exist with other camera apps)
- ✅ Camera ID filtering (fix crashes on OnePlus 9/9 Pro)
- ✅ Automatic `.apkm` to `.apk` conversion (APKMirror support)

### Pre-configured for OnePlus Devices

Two configurations are included:
- **OnePlus 9 Pro**: Filters camera ID 4 (monochrome sensor)
- **OnePlus 9**: Filters camera ID 3 (monochrome sensor)

Both configurations change the package name to avoid conflicts with Google Camera.

## 🚀 Quick Start

### On Desktop
```bash
git clone https://github.com/tqmane/Revanced
cd Revanced
./build.sh
```

The script will automatically:
1. Download Blackmagic Camera from APKMirror
2. Convert `.apkm` to `.apk` (if needed)
3. Apply patches
4. Build Magisk module

### APKMirror .apkm Support

This repo includes `antisplit-apkm.sh` which automatically converts APKMirror's `.apkm` files to standard `.apk` files by merging all split APKs.

**No manual intervention needed!** Just set `apkmirror-dlurl` in `config.toml`.

## 📝 Configuration

Edit [`config.toml`](./config.toml) to customize:

```toml
[blackmagic-oneplus9pro]
enabled = true
app-name = "Blackmagic Camera (OP9Pro)"
apkmirror-dlurl = "https://www.apkmirror.com/apk/blackmagic-design-inc/blackmagic-camera/..."
patches-source = "tqmane/blackmagic-revanced-patches"
patches-version = "1.0.0"
cli-version = "4.6.0"
included-patches = "'Change package name' 'Filter camera IDs'"

[blackmagic-oneplus9pro.options]
packageName = "com.google.android.GoogleCameraEng.blackmagic.op9pro"
cameraIdsToFilter = "4"
```

## 📚 Documentation

- [CONFIG.md](./CONFIG.md) - Configuration guide
- [antisplit-apkm.sh](./antisplit-apkm.sh) - APKMirror converter script
- [Blackmagic Patches Repo](https://github.com/tqmane/blackmagic-revanced-patches) - Patch source code

---

## Original ReVanced Features  

Get the [latest CI release](https://github.com/j-hc/revanced-magisk-module/releases).

Use [**zygisk-detach**](https://github.com/j-hc/zygisk-detach) to detach YouTube and YT Music from Play Store if you are using magisk modules. 

<details><summary><big>Features</big></summary>
<ul>
 <li>Support all present and future ReVanced and <a href="https://github.com/inotia00/revanced-patches">ReVanced Extended</a> apps</li>
 <li> Can build Magisk modules and non-root APKs</li>
 <li> Updated daily with the latest versions of apps and patches</li>
 <li> Optimize APKs and modules for size</li>
 <li> Modules</li>
    <ul>
     <li> recompile invalidated odex for faster usage</li>
     <li> receive updates from Magisk app</li>
     <li> do not break safetynet or trigger root detections</li>
     <li> handle installation of the correct version of the stock app and all that</li>
     <li> support Magisk and KernelSU</li>
    </ul>
</ul>
Note that the <a href="../../actions/workflows/ci.yml">CI workflow</a> is scheduled to build the modules and APKs everyday using GitHub Actions if there is a change in ReVanced patches. You may want to disable it.
</details>

## To include/exclude patches or patch other apps

 * Star the repo :eyes:
 * Use the repo as a [template](https://github.com/new?template_name=revanced-magisk-module&template_owner=j-hc)
 * Customize [`config.toml`](./config.toml) using [rvmm-config-gen](https://j-hc.github.io/rvmm-config-gen/)
 * Run the build [workflow](../../actions/workflows/build.yml)
 * Grab your modules and APKs from [releases](../../releases)

also see here [`CONFIG.md`](./CONFIG.md)

## Building Locally
### On Termux
```console
bash <(curl -sSf https://raw.githubusercontent.com/j-hc/revanced-magisk-module/main/build-termux.sh)
```

### On Desktop
```console
$ git clone https://github.com/j-hc/revanced-magisk-module
$ cd revanced-magisk-module
$ ./build.sh
```
