#!/bin/bash

success_msg="Done. Restart Firefox for changes to take effect."

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

# ---------------------------------------------------------------------------------------------------
# ===================================================================================================
# Reset

# Check if omni.ja file exists in /usr/lib or /usr/lib64
omni=""
if [ -f "/usr/lib/firefox/browser/omni.ja" ]; then
    omni="/usr/lib/firefox/browser/omni.ja"
    elif [ -f "/usr/lib64/firefox/browser/omni.ja" ]; then
    omni="/usr/lib64/firefox/browser/omni.ja"
else
    echo >&2 "Firefox omni.ja file not found in /usr/lib or /usr/lib64. Aborting."
    exit 1
fi

if [ "$action" == "--reset" ]; then
    echo "Resetting..."
    
    omni_orig="$omni.orig"
    if [ ! -f "$omni_orig" ]; then
        echo >&2 "Backup omni.ja file not found. Aborting."
        exit 1
    fi
    
    sudo mv $omni "$omni.reverted"
    sudo mv $omni_orig "$omni"
    
    # Clear startup cache as a normal user
    rm -rf ~/.cache/mozilla/firefox/*/startupCache
    
    echo "$success_msg"
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
unzip -q -o "$omni"

xhtml="./chrome/browser/content/browser/browser.xhtml"
check_file_or_dir_exists "$xhtml"

# Loop through the remaining arguments
while [ "$#" -gt 0 ]; do
    command="$1"
    # Perform actions based on the chosen option
    case "$action" in
        "--unreserve")
            echo "Unreserving: $command"
            if awk '/<key/,/>/' $xhtml | awk '/command="'$command'"/,/>/' | grep -qE 'reserved="false"'; then
                echo "$command already has reserved=false."
                elif awk '/<key/,/>/' $xhtml | awk '/command="'$command'"/,/>/' | grep -qE 'reserved="true"'; then
                awk -i inplace 'BEGIN {RS="</key>"; ORS="</key>"} /<key id="key_quitApplication"/ {gsub(/reserved="true"/, "reserved=\"false\""); ORS="\n"} 1' $xhtml
                
            else
                echo "$command does not have reserved=true."
            fi
            
        ;;
        "--remove")
            echo "Removing: $command"
            # Use sed to find and comment out the relevant block(s). Can be single-line or multi-line
            sed -i -E -e '/<key\s/{:a; /\/>/!{N;ba}; /command="'"$command"'"/ s/(.*)/<!-- \1 -->/}' $xhtml
            
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


# ---------------------------------------------------------------------------------------------------
# ===================================================================================================
# Cleanup

sudo rm -rf /tmp/omni.ja /tmp/firefox-omni

# Clear startup cache as a normal user
rm -rf ~/.cache/mozilla/firefox/*/startupCache

echo "$success_msg"
