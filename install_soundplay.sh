#!/bin/bash

# install_soundplay.sh
# This script installs the necessary dependencies for the accompanying 'player' script
# to run on a Debian-based system (e.g., Raspberry Pi OS).

set -e # Exit immediately if a command exits with a non-zero status.

echo "Starting installation for SoundPlay environment..."

# 1. Update Package Lists
echo "[1/8] Updating package lists..."
sudo apt update

# 2. Install Core Dependencies
echo "[2/8] Installing core dependencies (git, build-essential, pkg-config, curl)..."
sudo apt install -y git build-essential pkg-config curl libasound2-dev libjack-jackd2-dev

# 3. Install JACK Audio Connection Kit & QJackCtl
echo "[3/8] Installing JACK (jackd2, jack-tools) and QJackCtl..."
sudo apt install -y jackd2 jack-tools qjackctl

# 4. Install LV2 Plugin Host (JALV)
echo "[4/8] Installing JALV (LV2 Plugin Host)..."
sudo apt install -y jalv

# 5. Install LSP Plugins
echo "[5/8] Installing LSP LV2 Plugins..."
sudo apt install -y lsp-plugins-lv2

# 6. Install Rust (for Librespot)
echo "[6/8] Installing Rust via rustup..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # Add cargo to PATH for the current session
    source "$HOME/.cargo/env"
    echo "Rust installed. You might need to re-login or source ~/.cargo/env in new shells."
else
    echo "Rust is already installed."
fi

# 7. Build and Install Librespot
echo "[7/8] Building and installing Librespot with JACK backend..."
LIBRESPOT_BUILD_DIR=$(mktemp -d)
echo "Cloning librespot into $LIBRESPOT_BUILD_DIR..."
git clone https://github.com/librespot-org/librespot.git "$LIBRESPOT_BUILD_DIR"
cd "$LIBRESPOT_BUILD_DIR"
# Ensure cargo is in PATH (might be needed if script is run in a very clean env)
export PATH="$HOME/.cargo/bin:$PATH"
cargo build --release --features "jackaudio"
echo "Copying librespot binary to /usr/local/bin/librespot..."
sudo cp target/release/librespot /usr/local/bin/librespot
cd - # Return to previous directory
rm -rf "$LIBRESPOT_BUILD_DIR"
echo "Librespot installed."

# 8. Create Crossover Configuration Directory
echo "[8/8] Creating LSP Crossover configuration directory..."
mkdir -p "$HOME/xover_80hz/"
echo "Directory $HOME/xover_80hz/ created."
echo "IMPORTANT: You need to place your LSP Crossover LV2 preset/configuration files in this directory."

echo ""
echo "--- Installation Complete ---"
echo ""
echo "Next Steps:"
echo "1. Add your user to the 'audio' group for real-time JACK permissions:"
echo "   sudo usermod -a -G audio $USER"
echo "2. IMPORTANT: You MUST reboot your system or log out and log back in for the group change to take effect."
echo "3. Configure JACK audio server (e.g., using QJackCtl). Ensure your sound card is selected and JACK starts correctly."
echo "4. Place your LSP Crossover preset/configuration (e.g., for 80Hz) into the '$HOME/xover_80hz/' directory."
echo "   The 'player' script expects to find the LV2 preset there, loaded by JALV."
echo "5. You should now be able to run the 'player' script."
echo ""
echo "If librespot was just installed via this script, ensure /usr/local/bin is in your PATH."
echo "If Rust was just installed, you might need to open a new terminal or run 'source \"\$HOME/.cargo/env\"'."

exit 0 