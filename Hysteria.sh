#!/bin/bash

install_hysteria2() {
    curl -sS -o Hysteria2.sh https://raw.githubusercontent.com/finish475/Hysteria2_1click/main/Hysteria2.sh &&
    chmod +x Hysteria2.sh &&
    ./Hysteria2.sh
}

uninstall_hysteria2() {
    bash <(curl -fsSL https://get.hy2.sh/) --remove
}

echo "Vui lòng chọn một hành động："
echo "1. Cài đặt Hysteria2"
echo "2. Gỡ cài đặt Hysteria2"
read -p "Nhập tùy chọn: " choice


case $choice in
    1)
        install_hysteria2
        ;;
    2)
        uninstall_hysteria2
        ;;
    *)
        echo "Tùy chọn không hợp lệ"
        ;;
esac
