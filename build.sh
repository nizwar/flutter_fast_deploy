#!/bin/bash

# Clear the terminal screen
clear

# Reset the builds.log file
log_file="builds.log"
> "$log_file"

# Extract the current version and build number from pubspec.yaml
old_version=$(sed -n 's/^version: *\(.*\)/\1/p' pubspec.yaml)
build_number=$(echo "$old_version" | awk -F '+' '{print $2}')
version=$(echo "$old_version" | awk -F '+' '{print $1}')

# Get the git commit messages since yesterday midnight
gitFormattedMessage=$(git log --pretty='format:(%h) %s' --since=yesterday.midnight)
gitPrettyFormattedMessage=$(git log --pretty='format:• %s' --since=yesterday.midnight)

# Get the current date and time in Asia/Jakarta timezone
now=$(TZ="Asia/Jakarta" date +"%T %d-%m-%Y")

# Load distribution credentials from .distribution.env
if [ -f .distribution.env ]; then
    source .distribution.env
else
    echo "Error: .distribution.env file not found!" | tee -a "$log_file"
    exit 1
fi

# Parse arguments
mode="release"
use_firebase=$USE_FIREBASE
use_fastlane=$USE_FASTLANE

for arg in "$@"; do
    case $arg in
        --release)
            mode="release"
            ;;
        --debug)
            mode="debug"
            ;;
        *)
            echo "Unknown argument: $arg" | tee -a "$log_file"
            ;;
    esac
done

# Display current version and build information
echo "🚀 Current Build Version: $old_version 🚀" | tee -a "$log_file"
echo ====================================================== | tee -a "$log_file"
echo "Changelogs:" | tee -a "$log_file"
echo -e "$gitFormattedMessage" | tee -a "$log_file"

# Prepare changelog entry
changelogs="[$old_version] $(id -un) - ($now)
======================================================
$gitFormattedMessage
"

# Check if the current version already exists in changelogs.txt
if ! grep -q "[$old_version]" changelogs.txt; then
    # Append changelog to changelogs.txt and write to dist_changelogs.txt
    echo -e "$changelogs" >> changelogs.txt
fi
echo -e "$changelogs" > dist_changelogs.txt
echo -e "[MODE: $mode] $changelogs" > dist_changelogs.txt

echo "======================================================" | tee -a "$log_file"
echo "Build mode: $mode" | tee -a "$log_file"
echo "Firebase Distribution: $use_firebase" | tee -a "$log_file"
echo "Fastlane Distribution: $use_fastlane" | tee -a "$log_file"
echo "======================================================" | tee -a "$log_file"

# Ensure output directories exist
mkdir -p distribution/android/output
mkdir -p distribution/ios/output

if $ANDROID_BUILD; then
    # Build Android first
    android_build_status=0
    if [ "$mode" = "debug" ]; then
        echo "Building Android APK (debug)..." | tee -a "$log_file"
        flutter build apk --debug -t lib/main.dart >> "$log_file" 2>&1 || android_build_status=1
    else
        echo "Building Android App Bundle (release)..." | tee -a "$log_file"
        flutter build appbundle --release -t lib/main.dart >> "$log_file" 2>&1 || android_build_status=1
    fi

    # Check Android build status
    if [ "$android_build_status" -eq 0 ]; then
        echo ====================================================== | tee -a "$log_file"
        echo "🎉 Android build finished successfully! 🎉" | tee -a "$log_file"
        if [ "$mode" = "release" ]; then
            # Move the .aab file to the output directory
            mv build/app/outputs/bundle/release/app-release.aab distribution/android/output/ || echo "Error moving Android AAB file" >> "$log_file"
            echo "Android AAB moved to distribution/android/output/"


            if $use_firebase; then
                echo "Distributing to Firebase App Distribution..." | tee -a "$log_file"
                firebase appdistribution:distribute distribution/android/output/app-release.aab \
                    --app "$ANDROID_FIREBASE_APP_ID" \
                    --release-notes-file "./dist_changelogs.txt" \
                    --groups "$ANDROID_FIREBASE_GROUPS" >> "$log_file" 2>&1 || echo "Error during Firebase App Distribution" >> "$log_file"
            fi
            if $use_fastlane; then
                # Check and download metadata if not exists
                if [ ! -d "distribution/android/metadata" ]; then
                    echo "distribution/android/metadata directory not found. Downloading metadata from Play Store..." | tee -a "$log_file"
                    fastlane run download_from_play_store package_name:"$ANDROID_PACKAGE_NAME" json_key:"distribution/fastlane.json" metadata_path:"distribution/android/metadata" >> "$log_file" 2>&1 || echo "Error downloading metadata" >> "$log_file"
                fi
                echo "Distributing to Play Store Internal App Sharing..." | tee -a "$log_file"
                # Loop through all directories inside distribution/android/metadata
                for dir in distribution/android/metadata/*/; do
                    # Check if the changelogs directory exists in the current directory
                    if [ -d "$dir/changelogs" ]; then
                        # Create a new file in the changelogs folder with the build number
                        echo -e "$gitPrettyFormattedMessage" > "$dir/changelogs/default.txt"
                    fi
                done
                fastlane run upload_to_play_store metadata_path:"distribution/android/metadata/" aab:"distribution/android/output/app-release.aab" package_name:"$ANDROID_PACKAGE_NAME" json_key:"distribution/fastlane.json" track:"internal" track_promote_to:"production" >> "$log_file" 2>&1 || echo "Error during Fastlane distribution" >> "$log_file"
            fi
        fi
    else
        echo "Android build failed." | tee -a "$log_file"
        exit 1
    fi
else
    echo "Android build skipped." | tee -a "$log_file"
fi
if $IOS_BUILD; then
    echo ====================================================== | tee -a "$log_file"
    # Build iOS after Android finishes
    ios_build_status=0
    if [ "$mode" = "debug" ]; then
        echo "Building iOS (debug)..." | tee -a "$log_file"
        flutter build ios --debug >> "$log_file" 2>&1 || ios_build_status=1
    else
        echo "Building iOS IPA (release)..." | tee -a "$log_file"
        flutter build ipa --release >> "$log_file" 2>&1 || ios_build_status=1
    fi

    # Check iOS build status
    if [ "$ios_build_status" -eq 0 ]; then
        echo ====================================================== | tee -a "$log_file"
        echo "🎉 iOS build finished successfully! 🎉" | tee -a "$log_file"
        if [ "$mode" = "release" ]; then
            # Move the .ipa file to the output directory
            mv build/ios/ipa/*.ipa distribution/ios/output/ || echo "Error moving iOS IPA file" >> "$log_file"
            echo "iOS IPA moved to distribution/ios/output/" | tee -a "$log_file"
            xcrun altool --upload-app -f distribution/ios/output/*.ipa -u "$IOS_DISTRIBUTION_USER" -p "$IOS_DISTRIBUTION_PASSWORD" --type iphoneos --show-progress >> "$log_file" 2>&1 || echo "Error during IPA distribution" >> "$log_file"
        fi
    else
        echo "iOS build failed." | tee -a "$log_file"
        exit 1
    fi
else 
    echo "iOS build skipped." | tee -a "$log_file"
fi

# Check if the build was successful
if grep -q "Error" "$log_file"; then
    echo "Build process completed with errors." | tee -a "$log_file"
    echo "error" >> "$log_file"
else
    echo "Build process completed successfully." | tee -a "$log_file"
    echo "success" >> "$log_file"
fi

# Increment build number only if the log ends with "success"
if tail -n 1 "$log_file" | grep -q "success"; then
    sed -Ei "" "s/^version: (.*)/version: $version+$(($build_number + 1))/" ./pubspec.yaml
    echo "Build number incremented to [$version+$(($build_number + 1))]." | tee -a "$log_file"
else
    echo "Build number not incremented due to errors." | tee -a "$log_file"
fi
