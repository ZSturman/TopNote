"""Top Note 2.0 App Store Connect release. Usage:
  ASC_ISSUER_ID=... python asc_release.py verify|prepare|submit|status|release
Never prints the key or tokens."""
import jwt, time, requests, os, sys, json, hashlib, glob
KEY_ID = "FW47YH22F9"
KEY = open(os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_FW47YH22F9.p8")).read()
ISS = os.environ["ASC_ISSUER_ID"]
BUNDLE, VERSION, BUILD = "zacharysturman.TopNote", "2.0.0", "41"
MK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Marketing", "AppStore")
SETS = {"APP_IPHONE_67": f"{MK}/screenshots/iphone-6.9", "APP_IPAD_PRO_3GEN_129": f"{MK}/screenshots/ipad-13"}

def tok():
    now = int(time.time())
    return jwt.encode({"iss": ISS, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"}, KEY, algorithm="ES256", headers={"kid": KEY_ID, "typ": "JWT"})

def api(method, path, body=None, params=None, ok=(200, 201, 204)):
    url = path if path.startswith("http") else "https://api.appstoreconnect.apple.com" + path
    r = requests.request(method, url, headers={"Authorization": "Bearer " + tok(), "Content-Type": "application/json"}, json=body, params=params, timeout=120)
    if r.status_code not in ok:
        raise SystemExit(f"{method} {path} -> {r.status_code}: {r.text[:1500]}")
    return r.json() if r.text else {}

def meta(name):
    return open(f"{MK}/metadata/en-US/{name}.txt").read().strip()

def app_id():
    return api("GET", "/v1/apps", params={"filter[bundleId]": BUNDLE})["data"][0]["id"]

def version(app, create=False):
    vs = api("GET", f"/v1/apps/{app}/appStoreVersions", params={"filter[platform]": "IOS", "limit": 20})["data"]
    for v in vs:
        if v["attributes"]["versionString"] == VERSION:
            return v
    editable = [v for v in vs if v["attributes"]["appStoreState"] in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED")]
    if not create:
        return None
    if editable:  # rename the open version instead of creating a second one
        v = editable[0]
        return api("PATCH", f"/v1/appStoreVersions/{v['id']}", {"data": {"type": "appStoreVersions", "id": v["id"], "attributes": {"versionString": VERSION}}})["data"]
    return api("POST", "/v1/appStoreVersions", {"data": {"type": "appStoreVersions", "attributes": {"platform": "IOS", "versionString": VERSION, "releaseType": "MANUAL"}, "relationships": {"app": {"data": {"type": "apps", "id": app}}}}})["data"]

def build(app):
    bs = api("GET", "/v1/builds", params={"filter[app]": app, "filter[version]": BUILD, "filter[preReleaseVersion.version]": VERSION})["data"]
    return bs[0] if bs else None

def show(app):
    a = api("GET", f"/v1/apps/{app}")["data"]["attributes"]
    print("App:", a["name"], a["bundleId"], "primaryLocale", a.get("primaryLocale"))
    vs = api("GET", f"/v1/apps/{app}/appStoreVersions", params={"filter[platform]": "IOS", "limit": 5})["data"]
    for v in vs:
        print("  version", v["attributes"]["versionString"], v["attributes"]["appStoreState"], "release", v["attributes"].get("releaseType"))
    infos = api("GET", f"/v1/apps/{app}/appInfos")["data"]
    for info in infos:
        locs = api("GET", f"/v1/appInfos/{info['id']}/appInfoLocalizations")["data"]
        for l in locs:
            at = l["attributes"]
            print("  appInfo", info["attributes"].get("appStoreState") or info["attributes"].get("state"), at["locale"], "| name:", at.get("name"), "| subtitle:", at.get("subtitle"), "| privacy:", at.get("privacyPolicyUrl"))
    b = build(app)
    print("  build", BUILD, (b["attributes"]["processingState"], b["attributes"].get("usesNonExemptEncryption")) if b else "not found yet")

def wait_build(app):
    for _ in range(60):
        b = build(app)
        if b and b["attributes"]["processingState"] == "VALID":
            return b
        print("  build", BUILD, b["attributes"]["processingState"] if b else "not visible yet", "- waiting")
        time.sleep(30)
    raise SystemExit("Build did not finish processing")

def upload_screenshot(set_id, path):
    data = open(path, "rb").read()
    res = api("POST", "/v1/appScreenshots", {"data": {"type": "appScreenshots", "attributes": {"fileName": os.path.basename(path), "fileSize": len(data)}, "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})["data"]
    for op in res["attributes"]["uploadOperations"]:
        chunk = data[op["offset"]: op["offset"] + op["length"]]
        requests.request(op["method"], op["url"], headers={h["name"]: h["value"] for h in op["requestHeaders"]}, data=chunk, timeout=300).raise_for_status()
    api("PATCH", f"/v1/appScreenshots/{res['id']}", {"data": {"type": "appScreenshots", "id": res["id"], "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    return res["id"]

def prepare(app):
    v = version(app, create=True)
    vid = v["id"]
    print("Version", VERSION, vid, v["attributes"]["appStoreState"])
    api("PATCH", f"/v1/appStoreVersions/{vid}", {"data": {"type": "appStoreVersions", "id": vid, "attributes": {"releaseType": "MANUAL"}}})
    # Version localization (en-US)
    locs = api("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations")["data"]
    loc = next((l for l in locs if l["attributes"]["locale"] == "en-US"), None)
    attrs = {"description": meta("description"), "keywords": meta("keywords"), "promotionalText": meta("promotional_text"), "whatsNew": meta("release_notes")}
    if loc:
        api("PATCH", f"/v1/appStoreVersionLocalizations/{loc['id']}", {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": attrs}})
    else:
        loc = api("POST", "/v1/appStoreVersionLocalizations", {"data": {"type": "appStoreVersionLocalizations", "attributes": {"locale": "en-US", **attrs}, "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})["data"]
    print("  listing text updated (support/marketing URLs left as they are)")
    # Subtitle on the editable app info; keep the existing name
    for info in api("GET", f"/v1/apps/{app}/appInfos")["data"]:
        for l in api("GET", f"/v1/appInfos/{info['id']}/appInfoLocalizations")["data"]:
            if l["attributes"]["locale"] == "en-US":
                r = requests.patch(f"https://api.appstoreconnect.apple.com/v1/appInfoLocalizations/{l['id']}", headers={"Authorization": "Bearer " + tok(), "Content-Type": "application/json"},
                                   json={"data": {"type": "appInfoLocalizations", "id": l["id"], "attributes": {"subtitle": meta("subtitle")}}}, timeout=60)
                print("  subtitle on", info["id"], "->", r.status_code)
    # Screenshots
    sets = api("GET", f"/v1/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")["data"]
    for display, folder in SETS.items():
        s = next((x for x in sets if x["attributes"]["screenshotDisplayType"] == display), None)
        if not s:
            s = api("POST", "/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets", "attributes": {"screenshotDisplayType": display}, "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}}}}})["data"]
        for old in api("GET", f"/v1/appScreenshotSets/{s['id']}/appScreenshots")["data"]:
            api("DELETE", f"/v1/appScreenshots/{old['id']}")
        ids = [upload_screenshot(s["id"], p) for p in sorted(glob.glob(f"{folder}/*.png"))]
        print("  screenshots", display, len(ids))
    # Build
    b = wait_build(app)
    if b["attributes"].get("usesNonExemptEncryption") is None:
        api("PATCH", f"/v1/builds/{b['id']}", {"data": {"type": "builds", "id": b["id"], "attributes": {"usesNonExemptEncryption": False}}})
        print("  export compliance: no non-exempt encryption")
    api("PATCH", f"/v1/appStoreVersions/{vid}/relationships/build", {"data": {"type": "builds", "id": b["id"]}})
    print("  attached build", BUILD)
    # Review details
    try:
        rd = api("GET", f"/v1/appStoreVersions/{vid}/appStoreReviewDetail")["data"]
        print("  review contact:", "present" if rd and rd["attributes"].get("contactEmail") else "MISSING", "| demo account required:", rd["attributes"].get("demoAccountRequired") if rd else None)
    except SystemExit as e:
        print("  review detail:", str(e)[:200])

def submit(app):
    v = version(app)
    subs = api("GET", "/v1/reviewSubmissions", params={"filter[app]": app, "filter[platform]": "IOS"})["data"]
    sub = next((s for s in subs if s["attributes"]["state"] == "READY_FOR_REVIEW"), None)
    if not sub:
        sub = api("POST", "/v1/reviewSubmissions", {"data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"}, "relationships": {"app": {"data": {"type": "apps", "id": app}}}}})["data"]
    api("POST", "/v1/reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems", "relationships": {"reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub["id"]}}, "appStoreVersion": {"data": {"type": "appStoreVersions", "id": v["id"]}}}}}, ok=(201, 409))
    r = api("PATCH", f"/v1/reviewSubmissions/{sub['id']}", {"data": {"type": "reviewSubmissions", "id": sub["id"], "attributes": {"submitted": True}}})
    print("Submitted:", r["data"]["attributes"]["state"])

def release(app):
    v = version(app)
    state = v["attributes"]["appStoreState"]
    if state != "PENDING_DEVELOPER_RELEASE":
        raise SystemExit(f"Not releasable yet: {state}")
    api("POST", "/v1/appStoreVersionReleaseRequests", {"data": {"type": "appStoreVersionReleaseRequests", "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": v["id"]}}}}})
    print("Release requested")

if __name__ == "__main__":
    a = app_id()
    cmd = sys.argv[1]
    if cmd in ("verify", "status"): show(a)
    elif cmd == "prepare": prepare(a); show(a)
    elif cmd == "submit": submit(a); show(a)
    elif cmd == "release": release(a); show(a)
