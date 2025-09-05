#!/usr/bin/env bash
set -euo pipefail

red()   { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }
bold()  { printf "\033[1m%s\033[0m\n" "$*"; }

die(){ red "ERROR: $*"; exit 1; }

XCARCHIVE="${1:-}"
[[ -z "${XCARCHIVE}" ]] && die "Usage: $0 /path/to/App.xcarchive"
[[ -d "${XCARCHIVE}" ]] || die "No such archive: ${XCARCHIVE}"

APP_PATH="$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:ApplicationPath' "$XCARCHIVE/Info.plist" 2>/dev/null || true)"
[[ -z "${APP_PATH}" ]] && die "Could not read ApplicationPath from archive."
FULL_APP="$XCARCHIVE/Products/Applications/${APP_PATH##*/}"
[[ -d "$FULL_APP" ]] || die "App bundle not found at $FULL_APP"

bold "==> Checking main app at: $FULL_APP"

# Collect all bundles (app + appex)
mapfile -t BUNDLES < <(find "$FULL_APP" -type d \( -name "*.app" -o -name "*.appex" \))

ok=0; fail=0
pass(){ green "✔ $*"; ((ok++)); }
warn(){ yellow "⚠ $*"; }
fail(){ red "✖ $*"; ((fail++)); }

check_info_plist(){
  local bundle="$1" plist="$bundle/Info.plist"
  [[ -f "$plist" ]] || { fail "Missing Info.plist in $bundle"; return; }
  local ver build bid minos
  ver=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist" 2>/dev/null || true)
  build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist" 2>/dev/null || true)
  bid=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist" 2>/dev/null || true)
  minos=$(/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$plist" 2>/dev/null || true)

  [[ -n "$ver" && -n "$build" ]] && pass "Version/Build present: $ver ($build) — $(basename "$bundle")" \
    || fail "Missing CFBundleShortVersionString/CFBundleVersion in $(basename "$bundle")"

  # Encryption key
  local enc
  enc=$(/usr/libexec/PlistBuddy -c 'Print :ITSAppUsesNonExemptEncryption' "$plist" 2>/dev/null || true)
  if [[ -z "$enc" ]]; then
    warn "ITSAppUsesNonExemptEncryption not set in $(basename "$bundle") (set YES/NO)."
  else
    pass "ITSAppUsesNonExemptEncryption=$enc in $(basename "$bundle")"
  fi

  # Basic sanity
  [[ -n "$bid" ]] || fail "Missing CFBundleIdentifier in $(basename "$bundle")"
  [[ -n "$minos" ]] && pass "MinimumOSVersion=$minos in $(basename "$bundle")" || warn "MinimumOSVersion missing in $(basename "$bundle")"
}

check_signing_and_entitlements(){
  local bundle="$1"
  local ent tmp; tmp="$(mktemp)"
  if ! codesign -d --entitlements :- "$bundle" >"$tmp" 2>/dev/null; then
    fail "Not code signed: $(basename "$bundle")"
    rm -f "$tmp"; return
  fi
  pass "Code signature present: $(basename "$bundle")"

  # get-task-allow should be false for App Store
  if /usr/libexec/PlistBuddy -c 'Print :get-task-allow' "$tmp" &>/dev/null; then
    local gta; gta=$(/usr/libexec/PlistBuddy -c 'Print :get-task-allow' "$tmp" 2>/dev/null || echo "")
    [[ "$gta" == "false" ]] && pass "get-task-allow=false (OK) — $(basename "$bundle")" || fail "get-task-allow=$gta (should be false) — $(basename "$bundle")"
  else
    pass "get-task-allow not present (OK) — $(basename "$bundle")"
  fi

  # Show notable entitlements for quick eyeball
  for key in \
    'application-identifier' \
    'com.apple.developer.applesignin' \
    'aps-environment' \
    'com.apple.developer.icloud-services' \
    'com.apple.developer.associated-domains' \
    'com.apple.developer.team-identifier' \
    'com.apple.security.application-groups' \
    'keychain-access-groups'
  do
    if /usr/libexec/PlistBuddy -c "Print :$key" "$tmp" &>/dev/null; then
      local val; val=$(/usr/libexec/PlistBuddy -c "Print :$key" "$tmp" 2>/dev/null || true)
      echo "    ent: $key = $val"
    fi
  done
  rm -f "$tmp"
}

check_archs(){
  local bin="$1"
  local archs; archs=$(lipo -archs "$bin" 2>/dev/null || true)
  [[ -z "$archs" ]] && { fail "Cannot read architectures for $bin"; return; }
  if grep -qE '\b(x86_64|i386)\b' <<<"$archs"; then
    fail "Simulator slice present ($archs) in $(basename "$bin") — strip to device-only."
  else
    pass "Architectures OK ($archs) — $(basename "$bin")"
  fi
  if ! grep -q '\barm64\b' <<<"$archs"; then
    fail "arm64 missing in $(basename "$bin")"
  fi
}

check_binaries_and_frameworks(){
  local bundle="$1"
  # Main executable
  local exe; exe=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$bundle/Info.plist" 2>/dev/null || true)
  if [[ -n "$exe" && -f "$bundle/$exe" ]]; then
    check_archs "$bundle/$exe"
  else
    fail "Main executable missing in $(basename "$bundle")"
  fi
  # Embedded frameworks
  if [[ -d "$bundle/Frameworks" ]]; then
    while IFS= read -r -d '' fw; do
      check_archs "$fw"
      # Must be code signed
      if codesign -v "$fw" 2>/dev/null; then
        pass "Framework signed: $(basename "$fw")"
      else
        fail "Framework NOT signed: $(basename "$fw")"
      fi
    done < <(find "$bundle/Frameworks" -type f -perm -111 -print0)
  fi
}

check_disallowed_payload(){
  local bundle="$1"
  local bad=0
  while IFS= read -r p; do bad=1; red "✖ Disallowed content: $p"; done < <(find "$bundle" -type d \( -name Headers -o -name Modules \) -prune -print)
  while IFS= read -r p; do bad=1; red "✖ Disallowed content: $p"; done < <(find "$bundle" -type f \( -name "*.swiftmodule" -o -name "*.dSYM" \) -print)
  [[ $bad -eq 0 ]] && pass "No disallowed dev artifacts in $(basename "$bundle")"
}

check_icons_hint(){
  # FYI: 1024×1024 marketing icon lives in the asset catalog and is NOT inside the compiled app.
  warn "Marketing icon (1024×1024) cannot be verified from archive payload — confirm AppIcon has a Marketing slot in the asset catalog."
}

check_bundle_alignment(){
  # Ensure all bundles share prefix and version/build pairs
  local root_plist="$FULL_APP/Info.plist"
  local root_ver root_build root_bid
  root_ver=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$root_plist" 2>/dev/null || true)
  root_build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$root_plist" 2>/dev/null || true)
  root_bid=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$root_plist" 2>/dev/null || true)
  for b in "${BUNDLES[@]}"; do
    local v=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$b/Info.plist" 2>/dev/null || true)
    local n=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$b/Info.plist" 2>/dev/null || true)
    local id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$b/Info.plist" 2>/dev/null || true)
    [[ "$v" == "$root_ver" ]] || warn "Version mismatch in $(basename "$b"): $v vs $root_ver"
    [[ "$n" == "$root_build" ]] || warn "Build mismatch in $(basename "$b"): $n vs $root_build"
    [[ "$id" == "$root_bid" || "$id" == "$root_bid".* ]] || warn "Bundle ID not following prefix: $id (root: $root_bid)"
  done
  pass "Bundle alignment check complete (see warnings if any)."
}

# Run checks
for b in "${BUNDLES[@]}"; do
  bold "-- $(basename "$b") --"
  check_info_plist "$b"
  check_signing_and_entitlements "$b"
  check_binaries_and_frameworks "$b"
  check_disallowed_payload "$b"
done

check_bundle_alignment
check_icons_hint

bold ""
if (( fail > 0 )); then
  red "FAILED checks: $fail  •  PASSED: $ok"
  red "Fix the ✖ items above, then re-Archive and run Xcode Organizer → Validate."
  exit 2
else
  green "All critical checks passed ($ok). Still run Xcode Organizer → Validate to surface ITMS errors."
fi

# Extra hints
yellow "TIP: If App Store Connect still says 'Invalid Binary', open the build in App Store Connect → Activity and read the exact ITMS-xxxx error."