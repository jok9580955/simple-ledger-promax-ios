#!/usr/bin/env python3
import argparse
import plistlib
import shutil
import subprocess
import sys
import time
from PIL import Image, ImageStat
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "简单账本ProMax.xcodeproj"
DERIVED_DATA = ROOT / ".DerivedData"
SCREENSHOT_ROOT = ROOT / "fastlane" / "screenshots"

DEFAULT_LOCALES = [
    "ar-SA", "ca", "cs", "da", "de-DE", "el", "en-AU", "en-CA", "en-GB", "en-US",
    "es-ES", "es-MX", "fi", "fr-CA", "fr-FR", "he", "hi", "hr", "hu", "id", "it",
    "ja", "ko", "ms", "nl-NL", "no", "pl", "pt-BR", "pt-PT", "ro", "ru", "sk",
    "sv", "th", "tr", "uk", "vi", "zh-Hans", "zh-Hant",
]

SCREENS = [
    ("01-add", 0),
    ("02-records", 1),
    ("03-stats", 2),
    ("04-tools", 3),
    ("05-siri", 4),
]

DEVICES = [
    ("iPhone", "iPhone 17 Pro Max"),
    ("iPad", "iPad Air 13-inch (M3)"),
]

CAPTURE_WAIT_SECONDS = 5.0
MAX_CAPTURE_ATTEMPTS = 2


def run(args, check=True, echo_output=True, timeout=None):
    print("+", " ".join(str(a) for a in args), flush=True)
    result = subprocess.run(args, cwd=ROOT, text=True, capture_output=True, timeout=timeout)
    if result.stdout and echo_output:
        print(result.stdout, end="")
    if result.stderr and echo_output:
        print(result.stderr, end="", file=sys.stderr)
    if check and result.returncode != 0:
        if not echo_output:
            if result.stdout:
                print(result.stdout, end="")
            if result.stderr:
                print(result.stderr, end="", file=sys.stderr)
        raise SystemExit(result.returncode)
    return result


def build_app():
    run([
        "xcodebuild",
        "-project", str(PROJECT),
        "-scheme", "简单账本ProMax",
        "-destination", "generic/platform=iOS Simulator",
        "-derivedDataPath", str(DERIVED_DATA),
        "build",
    ])
    app = DERIVED_DATA / "Build" / "Products" / "Debug-iphonesimulator" / "简单账本ProMax.app"
    if not app.exists():
        raise SystemExit(f"Built app not found: {app}")
    return app


def bundle_id(app):
    info_plist = app / "Info.plist"
    with info_plist.open("rb") as handle:
        return plistlib.load(handle)["CFBundleIdentifier"]


def device_udid(device_name):
    result = run(["xcrun", "simctl", "list", "devices", "available", "-j"], echo_output=False)
    data = plistlib.loads(result.stdout.encode()) if result.stdout.lstrip().startswith("<?xml") else None
    if data is None:
        import json
        data = json.loads(result.stdout)
    for devices in data["devices"].values():
        for device in devices:
            if device.get("name") == device_name and device.get("isAvailable"):
                return device["udid"]
    raise SystemExit(f"Available simulator not found: {device_name}")


def device_state(udid):
    result = run(["xcrun", "simctl", "list", "devices", "available", "-j"], echo_output=False)
    import json
    data = json.loads(result.stdout)
    for devices in data["devices"].values():
        for device in devices:
            if device.get("udid") == udid:
                return device.get("state")
    return None


def apple_locale(locale):
    if locale == "no":
        return "nb_NO"
    return locale.replace("-", "_")


def prepare_device(udid, app, bid):
    if device_state(udid) != "Booted":
        run(["xcrun", "simctl", "boot", udid], check=False)
        try:
            run(["xcrun", "simctl", "bootstatus", udid, "-b"], timeout=60)
        except subprocess.TimeoutExpired:
            raise SystemExit(f"Timed out waiting for simulator to boot: {udid}")
    run(["xcrun", "simctl", "status_bar", udid, "override", "--time", "9:41", "--batteryState", "charged", "--batteryLevel", "100", "--wifiBars", "3"], check=False)
    run(["xcrun", "simctl", "uninstall", udid, bid], check=False)
    run(["xcrun", "simctl", "install", udid, str(app)])


def capture_locale_device(locale, device_label, udid, app, bid):
    out_dir = SCREENSHOT_ROOT / locale
    out_dir.mkdir(parents=True, exist_ok=True)
    prepare_device(udid, app, bid)

    for screen_name, screen_index in SCREENS:
        run(["xcrun", "simctl", "terminate", udid, bid], check=False)
        run([
            "xcrun", "simctl", "launch", udid, bid,
            "-FASTLANE_SNAPSHOT",
            "-ScreenshotMode", str(screen_index),
            "-AppleLanguages", f"({locale})",
            "-AppleLocale", apple_locale(locale),
        ])
        path = out_dir / f"{device_label}_{screen_name}.png"
        for attempt in range(1, MAX_CAPTURE_ATTEMPTS + 1):
            time.sleep(CAPTURE_WAIT_SECONDS)
            run(["xcrun", "simctl", "io", udid, "screenshot", str(path)])
            if not is_blank_screenshot(path):
                break
            if attempt == MAX_CAPTURE_ATTEMPTS:
                raise SystemExit(f"Blank screenshot after retry: {path}")
            print(f"Blank screenshot, retrying: {path}", flush=True)


def is_blank_screenshot(path):
    image = Image.open(path).convert("RGB")
    width, height = image.size
    crop = image.crop((0, int(height * 0.12), width, height))
    stat = ImageStat.Stat(crop)
    mean = sum(stat.mean) / 3
    ranges = [high - low for low, high in crop.getextrema()]
    return mean > 247 and max(ranges) < 40


def validate(locales):
    bad = []
    total = 0
    for locale in locales:
        directory = SCREENSHOT_ROOT / locale
        pngs = sorted(directory.glob("*.png"))
        iphone = [p for p in pngs if p.name.startswith("iPhone_")]
        ipad = [p for p in pngs if p.name.startswith("iPad_")]
        total += len(pngs)
        if len(pngs) != 10 or len(iphone) != 5 or len(ipad) != 5:
            bad.append((locale, len(pngs), len(iphone), len(ipad)))
        for png in pngs:
            if is_blank_screenshot(png):
                bad.append((locale, png.name, "blank"))
    print(f"locale_dirs={len(locales)} total_png={total} bad={bad}")
    if bad:
        raise SystemExit(1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--locales", default=",".join(DEFAULT_LOCALES))
    parser.add_argument("--skip-build", action="store_true")
    args = parser.parse_args()

    locales = [item.strip() for item in args.locales.split(",") if item.strip()]
    app = DERIVED_DATA / "Build" / "Products" / "Debug-iphonesimulator" / "简单账本ProMax.app"
    if not args.skip_build or not app.exists():
        app = build_app()
    bid = bundle_id(app)
    SCREENSHOT_ROOT.mkdir(parents=True, exist_ok=True)

    udids = [(label, device_udid(name)) for label, name in DEVICES]
    for locale in locales:
        for device_label, udid in udids:
            capture_locale_device(locale, device_label, udid, app, bid)

    validate(locales)


if __name__ == "__main__":
    main()
