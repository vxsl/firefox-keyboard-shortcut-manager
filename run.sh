#!/bin/bash

# ===================================================================================================
check_command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo >&2 "$1 is not installed. Aborting."; exit 1; }
}
check_file_or_dir_exists() {
    local path=$1
    
    # Check if the path exists
    if [ ! -e "$path" ]; then
        echo "Error: File or directory not found: $path"
        exit 1
    fi
}

# Check required commands
check_command_exists "sudo"
check_command_exists "unzip"
check_command_exists "patch"
check_command_exists "zip"
check_command_exists "xmlstarlet"


# Check if the user has sudo privileges
if ! sudo -l &>/dev/null; then
    echo "Error: Sudo privileges are required for this script."
    exit 1
fi
# ---------------------------------------------------------------------------------------------------

# ===================================================================================================
# Validate usage
if [ "$#" -lt 1 ]; then
    echo "Error: At least one argument is required."
    echo "Usage:"
    echo "       $0 (--unreserve|--remove) <arg1> [arg2 ...]"
    echo "       $0 --reset"
    exit 1
fi

case "$1" in
    "--unreserve" | "--remove")
        if [ "$#" -lt 2 ]; then
            echo "Error: At least two arguments are required for $1."
            echo "Usage: $0 $1 <arg1> [arg2 ...]"
            exit 1
        else
            echo -e "\nThis script is provided as is, without any warranty or guarantee of any kind. Use at your own risk."
            echo -e "If something breaks, it can likely be fixed by running this script again with the --reset option. Reinstalling Firefox should also be a failsafe."
            read -p "Are you sure you want to proceed? (Y/N): " decision
            if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
                echo "Aborting."
                exit 1
            fi
            echo -e "========================================================================================\n"
        fi
    ;;
    "--reset")
        action="--reset"
    ;;
    *)
        echo "Error: Invalid option. Use --unreserve, --remove, or --reset."
        echo "Usage:"
        echo "       $0 (--unreserve|--remove) <arg1> [arg2 ...]"
        echo "       $0 --reset"
        exit 1
    ;;
esac


action="$1"
shift

if pgrep -x "firefox" >/dev/null; then
    echo "Error: End Firefox processes before proceeding."
    exit 1
fi

# ---------------------------------------------------------------------------------------------------
# ===================================================================================================
# Find omni.ja

ff_locations=(
    "/usr/lib/firefox"
    "/usr/lib64/firefox"
    "/opt/firefox"
    "/usr/local/firefox"
)

# Function to check for omni.ja file in a given directory
check_omni_ja() {
    local location="$1"
    if [ -f "${location}/browser/omni.ja" ]; then
        omni="${location}/browser/omni.ja"
        return 0  # Success
    fi
    return 1  # File not found
}

# Iterate through ff_locations and check for omni.ja
omni=""
for location in "${ff_locations[@]}"; do
    if check_omni_ja "$location"; then
        break
    fi
done

# Check if omni.ja file was found
if [ -z "$omni" ]; then
    echo >&2 "Firefox omni.ja file not found. Aborting."
    exit 1
fi

echo "Found Firefox omni.ja file at: $omni"

# ---------------------------------------------------------------------------------------------------
# ===================================================================================================
# Reset

if [ "$action" == "--reset" ]; then
    echo "Resetting..."
    
    omni_orig="$omni.orig"
    if [ ! -f "$omni_orig" ]; then
        echo -e >&2 "Backup omni.ja file not found. If you have already used the reset option once, try restarting the Firefox process.\nAborting."
        exit 1
    fi
    
    sudo mv $omni "$omni.reverted"
    sudo mv $omni_orig "$omni"
    
    rm -rf ~/.cache/mozilla/firefox/*/startupCache
    
    exit 0
fi

# ---------------------------------------------------------------------------------------------------
# ===================================================================================================
# Unreserve or remove

# Create a temporary directory
tmp_dir="/tmp/firefox-omni"
mkdir -p "$tmp_dir"
cd "$tmp_dir"

# Unzip the omni.ja file
sudo unzip -qq -o "$omni" >/dev/null 2>&1
if [ $? -gt 2 ]; then
    echo "Error: Something went wrong unzipping omni.ja. Aborting."
    exit 1
fi

xhtml="$tmp_dir/chrome/browser/content/browser/browser.xhtml"
check_file_or_dir_exists "$xhtml"
sudo xmlstarlet ed -L "$xhtml" >/dev/null 2>&1
trap cleanup EXIT
cleanup_xhtml_cmp() {
    sudo rm -f "$xhtml.old"
}
cleanup() {
    cleanup_xhtml_cmp
    sudo rm -rf /tmp/omni.ja "$tmp_dir"
}
store_xhtml() {
    sudo cp "$xhtml" "$xhtml.old" || { echo "Error: Failed to create a backup of $xhtml."; exit 1; }
}
check_xhtml_changed() {
    diff -B "$xhtml" "$xhtml.old" >/dev/null 2>&1 && { echo "Error: Either the shortcut for \"$1\" does not exist, the specified change has already been made, or this script otherwise failed to make the specified change."; exit 1; }
    echo "Done."
    cleanup_xhtml_cmp
}

xmlns="http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul"
edit_xhtml() {
    sudo xmlstarlet ed -L -N n="$xmlns" $@ "$xhtml" >/dev/null 2>&1
}

# Loop through the remaining arguments
while [ "$#" -gt 0 ]; do
    command="$1"
    case "$action" in
        "--unreserve")
            echo "Unreserving: $command"
            store_xhtml
            # Find reserved="true" and replace with reserved="false". Can be single-line or multi-line
            edit_xhtml -u "//n:key[@command='$command']/@reserved" -v "false"
            check_xhtml_changed "$command"
        ;;
        "--remove")
            echo "Removing: $command"
            store_xhtml
            # Find and delete the relevant block(s). Can be single-line or multi-line
            edit_xhtml -d "//n:key[@command='$command']"
            check_xhtml_changed "$command"
        ;;
    esac
    shift  # Move to the next argument
done

# ---------------------------------------------------------------------------------------------------
# ===================================================================================================
# Install changes

sudo zip -0DXqr /tmp/omni.ja *
if [ $? -ne 0 ]; then
    echo >&2 "Zip operation failed. Aborting."
    exit 1
fi

# Record original omni.orig if this is the first run
if [ ! -f "$omni.orig" ]; then
    sudo cp "$omni" "$omni.orig"
fi

# Apply new omni.ja
sudo cp /tmp/omni.ja "$omni"
if [ $? -ne 0 ]; then
    echo >&2 "Copy operation failed. Aborting."
    exit 1
fi

rm -rf ~/.cache/mozilla/firefox/*/startupCache
