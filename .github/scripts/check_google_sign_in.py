#!/usr/bin/env python3
"""Checks the Android Google Sign-In setup against the APK that CI just built.

Usage: check_google_sign_in.py <apk-sha1-hex>

Prints package names, OAuth client IDs and certificate hashes from
android/app/google-services.json (never API keys) and flags mismatches.
Always exits 0 so the Appetize upload still happens; problems show up as
::error annotations and in the job summary.
"""
import json
import os
import re
import sys

PACKAGE = "com.opportunet.app"
apk_sha1 = re.sub(r"[^0-9a-f]", "", sys.argv[1].lower())

with open("android/app/google-services.json") as f:
    services = json.load(f)
with open("lib/login.dart") as f:
    m = re.search(r"serverClientId:\s*'([^']+)'", f.read())
    dart_server_client_id = m.group(1) if m else None
with open("lib/firebase_options.dart") as f:
    m = re.search(r"android = FirebaseOptions\((.*?)\);", f.read(), re.S)
    m = m and re.search(r"appId:\s*'([^']+)'", m.group(1))
    dart_android_app_id = m.group(1) if m else None

lines = [f"APK signing SHA-1: `{apk_sha1}`", f"Expected package: `{PACKAGE}`", ""]
problems = []

web_ids = set()
match = None
for client in services.get("client", []):
    info = client.get("client_info", {})
    pkg = info.get("android_client_info", {}).get("package_name")
    lines.append(f"- Firebase app `{info.get('mobilesdk_app_id')}` package `{pkg}`")
    oauth = list(client.get("oauth_client", []))
    oauth += client.get("services", {}).get("appinvite_service", {}).get("other_platform_oauth_client", [])
    for o in oauth:
        cert = o.get("android_info", {}).get("certificate_hash", "")
        lines.append(f"  - OAuth type {o.get('client_type')}: `{o.get('client_id')}`"
                     + (f" package `{o['android_info'].get('package_name')}` SHA-1 `{cert}`" if cert else ""))
        if o.get("client_type") == 3:
            web_ids.add(o.get("client_id"))
    if pkg == PACKAGE:
        match = client

if match is None:
    problems.append(f"google-services.json has no Android app for package {PACKAGE}.")
else:
    app_id = match["client_info"]["mobilesdk_app_id"]
    certs = {o.get("android_info", {}).get("certificate_hash", "").lower()
             for o in match.get("oauth_client", []) if o.get("client_type") == 1}
    if apk_sha1 not in certs:
        problems.append(
            f"SHA-1 {apk_sha1} of the APK is not registered for {PACKAGE} in google-services.json. "
            "Add it in Firebase console > Project settings > your Android app > Add fingerprint, "
            "then download google-services.json again and update the GOOGLE_SERVICES_JSON secret.")
    if dart_android_app_id and dart_android_app_id != app_id:
        lines.append(f"Note: lib/firebase_options.dart android appId is {dart_android_app_id}, the "
                     f"Firebase app for {PACKAGE} is {app_id} (Android uses google-services.json).")

if not web_ids:
    problems.append("google-services.json has no web OAuth client (client_type 3). Enable Google "
                    "in Firebase Authentication > Sign-in method and download it again.")
elif dart_server_client_id and dart_server_client_id not in web_ids:
    problems.append(f"serverClientId in lib/login.dart ({dart_server_client_id}) is not a web "
                    f"OAuth client of this project. Web clients: {', '.join(sorted(web_ids))}")

lines.append("")
lines += [f"**Problem:** {p}" for p in problems] or ["No Google Sign-In config problems found."]
print("\n".join(lines))
for p in problems:
    print(f"::error title=Google Sign-In config::{p}")
summary = os.environ.get("GITHUB_STEP_SUMMARY")
if summary:
    with open(summary, "a") as f:
        f.write("## Google Sign-In config check\n\n" + "\n".join(lines) + "\n")
