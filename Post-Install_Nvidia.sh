#!/bin/bash

sudo dnf -y install libva-nvidia-driver.{i686,x86_64}
systemctl reboot