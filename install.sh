#!/bin/bash

# =============================================================================
# Arch Linux Hyprland Setup Script
# =============================================================================
# This script sets up a complete Hyprland desktop environment on a fresh
# Arch Linux installation with all necessary packages and dotfile configurations.
#
# Usage: ./install.sh
# Make sure to run this script from your dotfiles repository root directory.
# =============================================================================

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root!"
        exit 1
    fi
}

# Ensure we're in the dotfiles directory
check_dotfiles_dir() {
    if [[ ! -f "install.sh" ]]; then
        log_error "This script must be run from the dotfiles repository root directory!"
        exit 1
    fi
    
    local required_dirs=("hypr" "ghostty" "nvim" "rofi" "hyprpanel")
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_warning "Directory '$dir' not found. Stow will skip this configuration."
        fi
    done
}

# Update system and install base packages
install_base_packages() {
    log_info "Updating system and installing base packages..."
    
    local base_packages=(
        # System essentials
        "base-devel" "git" "curl" "wget" "man-db" "man-pages" 
        "sudo" "zip" "unzip" "htop" "fastfetch" "tree" "which"
        
        # Fonts
        "noto-fonts" "ttf-fira-code" "ttf-jetbrains-mono-nerd" "ttf-meslo-nerd"
        "ttf-nerd-fonts-symbols" "ttf-nerd-fonts-symbols-mono"
        
        # Terminal and shell tools
        "ghostty" "starship" "neovim" "stow"
        
        # Daily productivity (GNOME ecosystem)
        "nautilus" "eog" "evince" "gnome-calculator"
        "gnome-system-monitor" "gnome-disk-utility"
        
        # Rofi launcher
        "rofi" "rofi-calc"
        
        # GTK theming
        "gtk3" "gtk4" "gnome-themes-extra" "papirus-icon-theme"
        "lxappearance" "qt5ct" "qt6ct"
        
        # Hyprland ecosystem
        "hyprland" "hypridle" "hyprlock" "hyprpaper" "hyprshot"
        "hyprsunset" "xdg-desktop-portal-hyprland" "xdg-user-dirs-gtk"
        
        # Audio
        "pipewire" "pipewire-alsa" "pipewire-pulse" "wireplumber"
        "pavucontrol"
        
        # Network
        "networkmanager" "network-manager-applet"
        
        # AMD drivers
        "amd-ucode" "mesa" "vulkan-radeon" "libva-mesa-driver"
        "mesa-vdpau" "xf86-video-amdgpu"
        
        # Flatpak support
        "flatpak"
        
        # Display manager
        "sddm" "qt5-graphicaleffects" "qt5-quickcontrols2" "qt5-svg"
    )
    
    # Update system first
    sudo pacman -Syu --noconfirm
    
    # Install packages in chunks to avoid very long command lines
    local chunk_size=20
    for ((i=0; i<${#base_packages[@]}; i+=chunk_size)); do
        local chunk=("${base_packages[@]:i:chunk_size}")
        log_info "Installing packages: ${chunk[*]}"
        sudo pacman -S --needed --noconfirm "${chunk[@]}"
    done
}

# Install Yay AUR helper
install_yay() {
    log_info "Installing yay AUR helper..."
    
    if command -v yay &> /dev/null; then
        log_success "yay is already installed"
        return
    fi
    
    # Clone and build yay
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd - > /dev/null
    rm -rf /tmp/yay
}

# Install AUR packages
install_aur_packages() {
    log_info "Installing AUR packages..."
    
    local aur_packages=(
        "hyprpanel-git"
        "nerd-fonts-complete"
        "sddm-catppuccin-git"
    )
    
    for package in "${aur_packages[@]}"; do
        log_info "Installing $package from AUR..."
        yay -S --needed --noconfirm "$package"
    done
}

# Setup Flatpak and install Flatpak applications
setup_flatpak() {
    log_info "Setting up Flatpak and installing applications..."
    
    # Add Flathub repository
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    
    local flatpak_apps=(
        "io.github.zen_browser.zen"
        "com.1password.1Password"
        "com.valvesoftware.Steam"
    )
    
    for app in "${flatpak_apps[@]}"; do
        log_info "Installing $app via Flatpak..."
        flatpak install flathub "$app" -y
    done
}

# Create symlinks using GNU Stow
setup_dotfiles() {
    log_info "Setting up dotfiles with GNU Stow..."
    
    local stow_dirs=("hypr" "ghostty" "nvim" "rofi" "hyprpanel")
    
    for dir in "${stow_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_info "Stowing $dir configuration..."
            stow --restow "$dir"
            log_success "Stowed $dir"
        else
            log_warning "Skipping $dir (directory not found)"
        fi
    done
}

# Enable essential services
enable_services() {
    log_info "Enabling essential services..."
    
    local services=(
        "NetworkManager"
        "sddm"
    )
    
    for service in "${services[@]}"; do
        log_info "Enabling $service..."
        sudo systemctl enable "$service"
    done
    
    # Start NetworkManager immediately if not running
    if ! systemctl is-active --quiet NetworkManager; then
        sudo systemctl start NetworkManager
    fi
}

# Configure SDDM with Catppuccin theme
configure_sddm() {
    log_info "Configuring SDDM with Catppuccin Mocha theme..."
    
    # Create SDDM config directory if it doesn't exist
    sudo mkdir -p /etc/sddm.conf.d
    
    # Create SDDM configuration with Catppuccin theme
    sudo tee /etc/sddm.conf.d/hyprland.conf > /dev/null <<EOF
[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=catppuccin-mocha

[Users]
MaximumUid=60513
MinimumUid=1000
EOF

    log_success "SDDM configured with Catppuccin Mocha theme"
}

# Configure user groups
configure_user_groups() {
    log_info "Adding user to necessary groups..."
    
    local groups=("wheel" "audio" "video" "input" "storage")
    
    for group in "${groups[@]}"; do
        sudo usermod -aG "$group" "$USER"
    done
    
    log_success "User added to groups: ${groups[*]}"
}

# Post-installation tasks
post_install() {
    log_info "Running post-installation tasks..."
    
    # Update font cache
    fc-cache -fv
    
    # Update desktop database
    update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
    
    log_success "Post-installation tasks completed"
}

# Main installation function
main() {
    log_info "Starting Arch Linux Hyprland setup..."
    echo "========================================"
    
    check_root
    check_dotfiles_dir
    
    # Installation phases
    install_base_packages
    install_yay
    install_aur_packages
    setup_flatpak
    setup_dotfiles
    configure_user_groups
    enable_services
    configure_sddm
    post_install
    
    echo "========================================"
    log_success "Installation completed successfully!"
    echo ""
    log_info "Next steps:"
    echo "1. Reboot your system: sudo reboot"
    echo "2. Log in through SDDM"
    echo "3. Launch Hyprland"
    echo "4. Configure your applications as needed"
    echo ""
    log_warning "Note: You may need to log out and back in for group membership changes to take effect."
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi