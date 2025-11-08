#!/bin/bash

cd $(dirname $0)
set -euo pipefail

set -x

if [[ ${DEBUG:-} != "" ]]; then
    set -x
fi

# Delete root password
passwd -d root
passwd -l root

# Setup arch user default passwd
echo arch:${DEFAULT_PASSWORD:-"arch"} | chpasswd

# Add ArchLinux CN Repo
echo '
[archlinuxcn]
# Server = https://repo.archlinuxcn.org/$arch
Server = https://mirrors.bfsu.edu.cn/archlinuxcn/$arch' >> /etc/pacman.conf

# Enable pacman color output
sed -i 's/#Color/Color/g' /etc/pacman.conf

# Set pacman repository mirror
echo 'Server = https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist

pacman -Syy
pacman -S --noconfirm base linux linux-firmware \
    grub amd-ucode intel-ucode \
    zsh zsh-syntax-highlighting zsh-autosuggestions \
    vim neovim git openbsd-netcat \
    sudo man-db htop wget \
    fastfetch archlinuxcn-keyring \
    kubectl helm jq go-yq lm_sensors \
    net-tools traceroute btrfs-progs bind ethtool bc \
    cloud-init cloud-guest-utils gptfdisk
pacman -S --noconfirm paru

# Use DHCP ipv4 only as default network
rm /etc/systemd/network/* || true
cat > /etc/systemd/network/10-dhcp.network << EOF
[Match]
Name=e*

[Network]
DHCP=ipv4

# Do not accept IPv6 Router Advertisement
IPv6AcceptRA=false

[DHCPv4]
ClientIdentifier=mac

[Link]
RequiredForOnline=routable
EOF

# Static network
cat > /etc/systemd/network/20-static.network.example << EOF
[Match]
Name=e*

[Network]
DHCP=no

# Do not accept IPv6 Router Advertisement
IPv6AcceptRA=false

DNS=10.1.x.x

[DHCPv4]
ClientIdentifier=mac

[Address]
Address=10.1.x.x/16

#[Address]
#Address=fd00:cafe::x/64

[Route]
Gateway=10.1.x.x
GatewayOnLink=yes

#[Route]
#Gateway=fd00:cafe::1
#GatewayOnLink=yes
EOF

# Set default DNS server
echo "DNS=10.1.1.1
FallbackDNS=8.8.8.8" >> /etc/systemd/resolved.conf

# Set default editor
echo "EDITOR=nvim" >> /etc/environment

# Configure NTP Server
echo "NTP=ntp.tuna.tsinghua.edu.cn" >> /etc/systemd/timesyncd.conf
echo "FallbackNTP=time1.cloud.tencent.com time2.cloud.tencent.com time3.cloud.tencent.com time4.cloud.tencent.com time5.cloud.tencent.com" >> /etc/systemd/timesyncd.conf

# Disable systemd-time-wait-sync.service
systemctl disable --now systemd-time-wait-sync.service

# cloud-init custom config
cat > /etc/cloud/cloud.cfg.d/10-network.cfg << EOF
network:
  config: disabled

system_info:
  default_user:
    name: arch
    lock_passwd: False
    gecos: arch Cloud User
    groups: [ 'wheel', 'users' ]
    sudo: [ 'ALL=(ALL) NOPASSWD:ALL' ]
    shell: /bin/zsh
EOF

# Configure cloud-init
systemctl enable cloud-init-main.service
systemctl enable cloud-init-local.service
systemctl enable cloud-init-network.service
systemctl enable cloud-config.service
systemctl enable cloud-final.service

# Setup serial console
sed -Ei 's/^(GRUB_CMDLINE_LINUX_DEFAULT=.*)"$/\1 console=tty0 console=ttyS0,115200"/' "/etc/default/grub"
echo 'GRUB_TERMINAL="serial console"' >>"/etc/default/grub"
echo 'GRUB_SERIAL_COMMAND="serial --speed=115200"' >>"/etc/default/grub"

# # Disable IPv6
# sed -i 's/console=tty0/ipv6.disable=1 console=tty0/g' /etc/default/grub

# Setup zshrc
wget https://raw.githubusercontent.com/STARRY-S/STARRY-S/refs/heads/main/zsh/.zshrc -O /root/.zshrc
cp /root/.zshrc /home/arch/.zshrc
chown arch:arch /home/arch/.zshrc
# Set zsh as default shell
sed -i 's/bash/zsh/g' /etc/passwd

# Show IP address in login prompt
cat > /etc/issue << EOF
eth0: \4{eth0}
EOF

# Delete machine ID
rm /etc/machine-id

# Cleanup
pacman -Scc --noconfirm

# Update grub
grub-mkconfig > /boot/grub/grub.cfg

echo "Done"
