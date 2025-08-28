#!/bin/bash

# Flatpaks for the Desktop Environment
if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
    echo "Installing GNOME Apps as Flatpaks"
    flatpak -y install flathub ca.desrt.dconf-editor
    flatpak -y install flathub com.belmoussaoui.Obfuscate
    flatpak -y install flathub com.github.neithern.g4music
    flatpak -y install flathub com.github.tchx84.Flatseal
    flatpak -y install flathub dev.qwery.AddWater
    flatpak -y install flathub io.github.giantpinkrobots.flatsweep
    flatpak -y install flathub net.nokyan.Resources
    flatpak -y install flathub org.gnome.Boxes
    flatpak -y install flathub org.gnome.Calculator
    flatpak -y install flathub org.gnome.Calendar
    flatpak -y install flathub org.gnome.clocks
    flatpak -y install flathub org.gnome.Connections
    flatpak -y install flathub org.gnome.Contacts
    flatpak -y install flathub org.gnome.Decibels
    flatpak -y install flathub org.gnome.Epiphany
    flatpak -y install flathub org.gnome.Extensions
    flatpak -y install flathub com.mattjakeman.ExtensionManager
    flatpak -y install flathub org.gnome.font-viewer
    flatpak -y install flathub org.gnome.Logs
    flatpak -y install flathub org.gnome.Loupe
    flatpak -y install flathub org.gnome.Maps
    flatpak -y install flathub org.gnome.Music
    flatpak -y install flathub org.gnome.NetworkDisplays
    flatpak -y install flathub org.gnome.Papers
    flatpak -y install flathub org.gnome.SimpleScan
    flatpak -y install flathub org.gnome.Snapshot
    flatpak -y install flathub org.gnome.SoundRecorder
    flatpak -y install flathub org.gnome.TextEditor
    flatpak -y install flathub org.gnome.Showtime
    flatpak -y install flathub org.gnome.Weather
    flatpak -y install flathub org.gnome.World.Iotas
    flatpak -y install flathub org.gaphor.Gaphor
    # Apply the correct theming for Legacy Applications
    flatpak -y install org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark
fi
if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    echo "Installing KDE Apps as Flatpaks"
    flatpak -y install flathub org.kde.kwrite
    flatpak -y install flathub org.kde.krdc
    flatpak -y install flathub org.kde.okular
    flatpak -y install flathub io.github.wereturtle.ghostwriter
    flatpak -y install flathub org.kde.gwenview
    flatpak -y install flathub org.kde.kclock
    flatpak -y install flathub org.kde.marknote
    flatpak -y install flathub org.kde.kalk
    flatpak -y install flathub org.kde.elisa
    flatpak -y install flathub org.qownnotes.QOwnNotes
    # Apply the correct theming for GTK Applications
    flatpak override --user --filesystem=xdg-config/gtk-3.0:ro
fi

# Flatpak Misc Applications
flatpak -y install flathub io.github.ungoogled_software.ungoogled_chromium
flatpak -y install flathub io.gitlab.librewolf-community
flatpak -y install flathub com.bitwarden.desktop
flatpak -y install flathub org.localsend.localsend_app
flatpak -y install flathub org.telegram.desktop
flatpak -y install flathub com.discordapp.Discord
flatpak -y install flathub org.libreoffice.LibreOffice
flatpak -y install flathub org.onlyoffice.desktopeditors
flatpak -y install flathub com.github.xournalpp.xournalpp
flatpak -y install flathub ch.openboard.OpenBoard
flatpak -y install flathub org.octave.Octave
flatpak -y install flathub com.jgraph.drawio.desktop
flatpak -y install flathub io.mpv.Mpv
flatpak -y install flathub org.gimp.GIMP
flatpak -y install flathub org.inkscape.Inkscape
flatpak -y install flathub org.darktable.Darktable
flatpak -y install flathub org.kde.krita
flatpak -y install flathub org.blender.Blender
flatpak -y install flathub org.kde.kdenlive
flatpak -y install flathub fr.handbrake.ghb
flatpak -y install flathub com.obsproject.Studio
flatpak -y install flathub io.github.vmkspv.netsleuth
flatpak -y install flathub io.github.giantpinkrobots.flatsweep
flatpak -y install flathub com.spotify.Client
flatpak -y install flathub com.valvesoftware.Steam
flatpak -y install flathub com.heroicgameslauncher.hgl
flatpak -y install flathub org.duckstation.DuckStation
flatpak -y install flathub net.pcsx2.PCSX2
flatpak -y install flathub org.ppsspp.PPSSPP
flatpak -y install flathub org.DolphinEmu.dolphin-emu
flatpak -y install flathub io.github.berarma.Oversteer

# Set up Ungoogled Chromium
flatpak run io.github.ungoogled_software.ungoogled_chromium &
sleep 1s
flatpak kill io.github.ungoogled_software.ungoogled_chromium
cp ./CustomConfigs/chromium-flags.conf $HOME/.var/app/io.github.ungoogled_software.ungoogled_chromium/config/
wget https://raw.githubusercontent.com/flathub/io.github.ungoogled_software.ungoogled_chromium/refs/heads/master/widevine-install.sh -P ./CustomConfigs
chmod +x ./CustomConfigs/widevine-install.sh
bash ./CustomConfigs/widevine-install.sh

# Oversteer Rules
sudo wget https://github.com/berarma/oversteer/raw/refs/heads/master/data/udev/99-fanatec-wheel-perms.rules -P /usr/lib/udev/rules.d/
sudo wget https://github.com/berarma/oversteer/raw/refs/heads/master/data/udev/99-logitech-wheel-perms.rules -P /usr/lib/udev/rules.d/
sudo wget https://github.com/berarma/oversteer/raw/refs/heads/master/data/udev/99-thrustmaster-wheel-perms.rules -P /usr/lib/udev/rules.d/