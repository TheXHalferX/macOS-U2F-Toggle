# macOS-U2F-Toggle
Just a very simple tool to enable U2F using open source software. But you've got to install and setup it first.
Three simple steps (four, if you not using Homebrew):
0. INSTALL HOMEBREW
1. brew install pam-u2f
2. mkdir -p ~/.config/Yubico/
3. pamu2fcfg > ~/.config/Yubico/u2f_keys
Then just run this app and select options you need.
