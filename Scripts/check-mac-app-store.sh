#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(tr -d '[:space:]' < VERSION)
build_number=$(tr -d '[:space:]' < BUILD_NUMBER)
entitlements=Resources/NotchAgentAppStore.entitlements

[[ "$version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || exit 1
[[ "$build_number" =~ '^[1-9][0-9]*$' ]] || exit 1
[[ $(grep -c "CFBundleShortVersionString: \"$version\"" project.yml) -ge 2 ]] || {
    echo "FAIL: project.yml Store and Direct versions must match VERSION." >&2
    exit 1
}
[[ $(grep -c "CFBundleVersion: \"$build_number\"" project.yml) -ge 2 ]] || {
    echo "FAIL: project.yml Store and Direct build numbers must match BUILD_NUMBER." >&2
    exit 1
}

for key in \
    com.apple.security.app-sandbox \
    com.apple.security.network.client \
    com.apple.security.network.server \
    com.apple.security.files.user-selected.read-only \
    com.apple.security.files.bookmarks.app-scope \
    com.apple.security.device.usb \
    com.apple.security.device.serial; do
    [[ $(/usr/libexec/PlistBuddy -c "Print :$key" "$entitlements") == true ]] || {
        echo "FAIL: missing Store entitlement $key." >&2
        exit 1
    }
done
! grep -q 'temporary-exception' "$entitlements" || {
    echo "FAIL: temporary sandbox exceptions are forbidden." >&2
    exit 1
}

NOTCHAGENT_DISABLE_PAID_PROBES=1 swift test
NOTCHAGENT_DISABLE_PAID_PROBES=1 swift test -Xswiftc -DAPP_STORE

project_dir=$(mktemp -d "${TMPDIR:-/tmp}/notchagent-store-project.XXXXXX")
derived_data=$(mktemp -d "${TMPDIR:-/tmp}/notchagent-store-derived.XXXXXX")
cleanup() {
    [[ -d "$project_dir" ]] && rm -r -- "$project_dir"
    [[ -d "$derived_data" ]] && rm -r -- "$derived_data"
}
trap cleanup EXIT

iconset="$project_dir/AppIcon.iconset"
iconutil -c iconset Resources/AppIcon.icns -o "$iconset"
retina_icon="$iconset/icon_512x512@2x.png"
[[ -f "$retina_icon" ]] || {
    echo "FAIL: AppIcon.icns is missing the required 512pt @2x image." >&2
    exit 1
}
[[ $(sips -g pixelWidth "$retina_icon" 2>/dev/null | awk '/pixelWidth/{print $2}') == 1024 ]] || {
    echo "FAIL: AppIcon.icns 512pt @2x image must be 1024 pixels wide." >&2
    exit 1
}

# Xcode resolves plist and entitlement build settings relative to the generated
# .xcodeproj, while source groups honor --project-root.
ln -s "$PWD/Generated" "$project_dir/Generated"
ln -s "$PWD/Resources" "$project_dir/Resources"
xcodegen --quiet --spec "$PWD/project.yml" --project "$project_dir" --project-root "$PWD"
xcodebuild \
    -project "$project_dir/NotchAgent.xcodeproj" \
    -scheme NotchAgentAppStore \
    -configuration Release \
    -derivedDataPath "$derived_data" \
    CODE_SIGNING_ALLOWED=NO \
    build

app="$derived_data/Build/Products/Release/NotchAgent.app"
binary="$app/Contents/MacOS/NotchAgent"
[[ -x "$binary" ]] || { echo "FAIL: Store app was not built." >&2; exit 1; }
[[ $(plutil -extract CFBundleIdentifier raw -o - "$app/Contents/Info.plist") == \
    br.com.lfrprojects.notchagent.appstore ]] || {
    echo "FAIL: Store bundle identifier mismatch." >&2
    exit 1
}
[[ $(plutil -extract CFBundleShortVersionString raw -o - "$app/Contents/Info.plist") == "$version" ]] || {
    echo "FAIL: Store version mismatch." >&2
    exit 1
}
[[ $(plutil -extract LSApplicationCategoryType raw -o - "$app/Contents/Info.plist") == \
    public.app-category.developer-tools ]] || {
    echo "FAIL: Store category must be Developer Tools." >&2
    exit 1
}
! otool -L "$binary" | grep -q Sparkle || {
    echo "FAIL: Store binary links Sparkle." >&2
    exit 1
}
[[ ! -e "$app/Contents/Library/LaunchAgents" ]] || {
    echo "FAIL: Store bundle contains a launch agent." >&2
    exit 1
}
[[ ! -e "$app/Contents/Resources/DeskFirmware" ]] || {
    echo "FAIL: Store bundle contains the firmware recovery helper." >&2
    exit 1
}
[[ -f "$app/Contents/Resources/AppIcon.icns" ]] || {
    echo "FAIL: Store bundle is missing the complete macOS icon set." >&2
    exit 1
}
[[ -f "$app/Contents/Resources/PrivacyInfo.xcprivacy" ]] || {
    echo "FAIL: Store bundle is missing PrivacyInfo.xcprivacy." >&2
    exit 1
}
if strings "$binary" | grep -Eq '/opt/homebrew/bin/(codex|gcloud)|/usr/local/bin/(codex|gcloud)|/usr/bin/gcloud|/Applications/ChatGPT.app/Contents/Resources/codex'; then
    echo "FAIL: Store binary contains an external executable path." >&2
    exit 1
fi

echo "PASS: Mac App Store tests, sandbox contract, build, and bundle inspection."
