#!/bin/bash

# Ask if SSH access to the machine is desired
ssh_enabled=0
while :
do
    read -p "Do you want to access your machine via SSH? [Y/N] " ssh_prompt
    if [[ "$ssh_prompt" = "y" ]] || [[ "$ssh_prompt" = "Y" ]]; then
        echo "SSH access will be granted."
        ssh_enabled=1
        break
    elif [[ "$ssh_prompt" = "n" ]] || [[ "$ssh_prompt" = "N" ]]; then
        echo "SSH access will not be granted."
        sudo systemctl disable --now sshd
        break
    else
        echo "Character not supported. Use \"Y\" or \"y\" for an affirmative answer, \"N\" or \"n\" otherwise."
    fi
done

# Own the /media Directory contents
sudo chown -R $(whoami):$(whoami) /media

# Disable CoW for Directories which do not need it
sudo chattr -R -f +C /swap
sudo chattr -R -f +C /media
sudo chattr -R -f +C /var/log

# If Fedora Workstation was installed
## -> Remove preinstalled Applications (to be replaced with Flatpaks)
## -> Install a FirewallD management tool
if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
    sudo dnf -y remove gnome-boxes gnome-calendar gnome-calculator gnome-characters gnome-clocks gnome-connections gnome-contacts gnome-epub-thumbnailer gnome-font-viewer gnome-logs gnome-maps gnome-text-editor gnome-tour gnome-weather loupe simple-scan snapshot totem libreoffice-* firefox rhythmbox
    sudo dnf -y install firewall-config
fi
# If Fedora KDE was installed (through the everything ISO and no bloat)
## -> Remove preinstalled Applications (to be replaced with Flatpaks)
if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    sudo dnf -y remove kwrite
    sudo dnf -y install dragon
fi 

# Create a new default Firewall Zone
sudo firewall-cmd --permanent --new-zone=custom
sudo firewall-cmd --reload
sudo firewall-cmd --set-default-zone custom
sudo firewall-cmd --zone=custom --add-service=mdns --permanent
sudo firewall-cmd --zone=custom --add-service=dhcpv6-client --permanent
if [ $ssh_enabled -eq 1 ]; then
    sudo firewall-cmd --zone=custom --add-service=ssh --permanent
fi
sudo firewall-cmd --reload

# Update
sudo dnf -y upgrade --refresh

# Customizations
## CustomScripts Folder
mkdir $HOME/.CustomScripts
cp -r ./CustomScripts/* $HOME/.CustomScripts
# .bashrc addons
echo "

# Fix LC_ALL Locale
export LC_ALL=en_US.UTF-8

# Customize Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Custom Scripts
export PATH=$PATH:$HOME/.CustomScripts
" >> $HOME/.bashrc

# ZRAM and Swapfiles
## Reduce Swappiness
echo "vm.swappiness=5" | sudo tee /etc/sysctl.d/01-swappiness.conf
## ZRAM
sudo sed -i 's/min(ram, 8192)/ram/p' /usr/lib/systemd/zram-generator.conf
## Swapfile
sudo fallocate -l 48G /swap/swapfile0
sudo chmod 600 /swap/swapfile0
sudo mkswap /swap/swapfile0
echo "# Swapfile
/swap/swapfile0 none swap sw 0 0" | sudo tee -a /etc/fstab

# Snapshots
sudo dnf install -y btrfs-progs btrfsmaintenance btrfs-assistant snapper libdnf5-plugin-actions
sudo cp ./CustomConfigs/snapper.actions /etc/dnf/libdnf5-plugins/actions.d/snapper.actions
sudo umount /.snapshots
sudo rm -rf /.snapshots
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots
sudo systemctl daemon-reload
sudo mount -a
sudo snapper -c root set-config ALLOW_GROUPS=wheel SYNC_ACL=yes TIMELINE_LIMIT_HOURLY="5" TIMELINE_LIMIT_DAILY="7" TIMELINE_LIMIT_WEEKLY="0" TIMELINE_LIMIT_MONTHLY="0"
sudo snapper -c home create-config /home
sudo snapper -c home set-config ALLOW_GROUPS=wheel SYNC_ACL=yes TIMELINE_LIMIT_HOURLY="5" TIMELINE_LIMIT_DAILY="7" TIMELINE_LIMIT_WEEKLY="0" TIMELINE_LIMIT_MONTHLY="0"
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer

# GRUB-BTRFS
sudo dnf -y install kernel-devel kerel-headers git gawk inotify-tools
sudo dnf -y copr enable kylegospo/grub-btrfs
sudo dnf -y install grub-btrfs
sudo systemctl enable --now grub-btrfs.path

# RPMFusion
sudo dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf -y config-manager setopt fedora-cisco-openh264.enabled=1
sudo dnf -y update @core
sudo dnf -y install rpmfusion-\*-appstream-data
sudo dnf -y upgrade --refresh
sudo dnf -y swap ffmpeg-free ffmpeg --allowerasing
sudo dnf -y update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf -y install rpmfusion-free-release-tainted
sudo dnf -y install libdvdcss
sudo dnf -y install rpmfusion-nonfree-release-tainted
sudo dnf -y --repo=rpmfusion-nonfree-tainted install "*-firmware"

# Drivers
sudo apt install -y lspci
## Intel Drives
lspci | grep VGA | grep Intel
if [ $? -eq 0 ]; then
    echo "You have an Intel GPU."
    sudo dnf -y install intel-media-driver
    echo "#GPU Hardware Acceleration
LIBVA_DRIVER_NAME=i965
VDPAU_DRIVER=va_gl" | sudo tee /etc/environment
fi
## AMD Drivers
lspci | grep VGA | grep AMD
if [ $? -eq 0 ]; then
    echo "You have an AMD GPU."
    sudo dnf -y swap mesa-va-drivers mesa-va-drivers-freeworld
    sudo dnf -y swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
    sudo dnf -y swap mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686
    sudo dnf -y swap mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686
    sudo dnf -y install radeontop 
    echo "#GPU Hardware Acceleration
LIBVA_DRIVER_NAME=radeonsi
VDPAU_DRIVER=radeonsi" | sudo tee /etc/environment
fi
## Nvidia Drivers
lspci | grep VGA | grep NVIDIA
if [ $? -eq 0 ]; then
    echo "You have an Nvidia GPU. You will have to run the Post-Install_Nvidia.sh file after the reboot to finish installing some components."
    sudo dnf -y install akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-cuda-libs.{i686,x86_64} xorg-x11-drv-nvidia-power nvidia-vaapi-driver
    sudo systemctl enable nvidia-{suspend,resume,hibernate}
    sudo dnf -y upgrade --refresh
    echo "#GPU Hardware Acceleration
LIBVA_DRIVER_NAME=nvidia
VDPAU_DRIVER=nvidia" | sudo tee /etc/environment
fi
sudo dnf -y install vulkan libva-utils vdpauinfo

# Development Tools
## C/C++
sudo dnf -y group install development-tools
## Java
sudo dnf -y install java-latest-openjdk java-latest-openjdk-devel
## Python
sudo dnf -y install python3-pip
## Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
## TeXLive
sudo dnf -y install texlive-scheme-full
## VSCode
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
sudo dnf -y upgrade --refresh
sudo dnf -y install code
## QEMU/KVM
sudo dnf -y group install --with-optional virtualization
sudo chattr -R -f +C /var/lib/libvirt
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $(whoami)
sudo usermod -aG kvm $(whoami)
## Docker
sudo dnf -y install dnf-plugins-core
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $(whoami)
## GNS3
sudo dnf -y install gns3-server gns3-gui

# Native Miscellaneous Applications
sudo dnf -y install lm_sensors vim micro htop btop stress s-tui wget wireshark bind-utils mediawriter speedtest-cli fastfetch p7zip p7zip-plugins p7zip-gui gh nextcloud-client syncthing qpdf steam-devices
# If using the Plasma Desktop also install the Dolphin File Manager addon for the Nextcloud Client
if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    sudo dnf -y install nextcloud-client-dolphin
fi
sudo usermod -aG wireshark $(whoami)
sudo systemctl enable --now sshd
sudo systemctl enable --now syncthing@$(whoami).service
sudo firewall-cmd --zone=custom --add-service=kdeconnect --permanent
sudo firewall-cmd --zone=custom --add-service=syncthing --permanent
sudo firewall-cmd --zone=custom --add-port=53317/tcp --permanent # LocalSend
sudo firewall-cmd --zone=custom --add-port=53317/udp --permanent # LocalSend
sudo firewall-cmd --reload

# Enable Flatpaks
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
echo "You will need to finish installing you Flatpak applications after a reboot."

# Reboot
systemctl reboot
