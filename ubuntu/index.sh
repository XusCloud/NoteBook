# 安装完全版firefox
# https://download-installer.cdn.mozilla.net/pub/firefox/releases/107.0/linux-x86_64/zh-CN/firefox-107.0.tar.bz2
mv firefox /opt
ln -s /opt/firefox/firefox /usr/local/bin/firefox
sudo wget https://raw.githubusercontent.com/mozilla/sumo-kb/main/install-firefox-linux/firefox.desktop -P /usr/local/share/applications

# dock点击可缩小
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'

# 安装额外内容
sudo apt install ubuntu-restricted-extras

# 安装微软字体
# Moun Package Manager
# carlito
# caladea

# install GNOME Extensions
sudo apt install chrome-gnome-shell
# to https://extensions.gnome.org
sudo apt install gnome-shell-extension-manager
# gnome tweaks

