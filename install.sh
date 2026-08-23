#!/usr/bin/env bash
set -euo pipefail

DOWNLOAD_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.2.1-5287492581195776/linux-x64/Antigravity.tar.gz"
ARCHIVE="Antigravity.tar.gz"

# Check Sudo
if [[ $EUID -ne 0 ]]; then
    echo "Please run this installer with sudo:"
    echo "  sudo $0"
    exit 1
fi

# Check if Curl and Tar is installed
echo "Checking dependencies..."
for cmd in curl tar; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd is required but not installed."
        exit 1
    fi
done

# Download archive if not present
if [ ! -f "$ARCHIVE" ]; then
    echo "Downloading Antigravity IDE..."
    if ! curl -fL -o "$ARCHIVE" "$DOWNLOAD_URL"; then
        echo "Error: Failed to download the IDE."
        rm -f "$ARCHIVE"
        exit 1
    fi
else
    echo "Using local archive: $ARCHIVE"
fi

echo "Extracting..."
TMP_EXTRACT_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_EXTRACT_DIR"' EXIT

tar -xzf "$ARCHIVE" -C "$TMP_EXTRACT_DIR"

# Find the extracted directory
EXTRACTED_DIR="$(find "$TMP_EXTRACT_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1)"

if [ -z "$EXTRACTED_DIR" ]; then
    echo "Error: Could not locate extracted Antigravity directory."
    exit 1
fi

echo "Installing to /opt..."
sudo rm -rf /opt/Antigravity
sudo mkdir -p /opt/Antigravity
sudo cp -a "$EXTRACTED_DIR"/. /opt/Antigravity/

echo "Configuring chrome-sandbox permissions..."
sudo chown root:root /opt/Antigravity/chrome-sandbox
sudo chmod 4755 /opt/Antigravity/chrome-sandbox

echo "Creating desktop entry..."

USER_HOME=$(eval echo ~"${SUDO_USER:-$USER}")
mkdir -p "$USER_HOME/.local/share/applications"

cat > "$USER_HOME/.local/share/applications/antigravity2.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Antigravity 2.0
GenericName=IDE
Comment=Experience liftoff
Exec=/opt/Antigravity/antigravity %F
Icon=antigravity
Terminal=false
StartupNotify=true
StartupWMClass=Antigravity
Categories=Development;TextEditor;
EOF

chmod 644 "$USER_HOME/.local/share/applications/antigravity2.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$USER_HOME/.local/share/applications" || true
fi

echo "Installing Antigravity icon..."

sudo mkdir -p /usr/share/icons/hicolor/512x512/apps

if [[ -f "antigravity.png" ]]; then
    sudo cp "antigravity.png" \
        /usr/share/icons/hicolor/512x512/apps/antigravity.png

    sudo chmod 644 \
        /usr/share/icons/hicolor/512x512/apps/antigravity.png

    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        sudo gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
    fi

    echo "Antigravity 2.0 icon installed."
else
    echo "Warning: antigravity.png not found in current directory."
    echo "Continuing without custom icon."
fi

echo "Cleaning up..."

if [ -f "$ARCHIVE" ]; then
    printf "Remove '%s' from the current directory? [y/N]: " "$ARCHIVE"
    read -r response

    case "$response" in
        [yY]|[yY][eE][sS])
            rm -f "$ARCHIVE"
            echo "Archive removed."
            ;;
        *)
            echo "Archive kept."
            ;;
    esac
fi

echo "Done! Antigravity 2.0 has been successfully installed."