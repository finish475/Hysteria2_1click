#!/bin/bash

# Kiểm tra xem có chạy với tư cách người dùng root không
if [ "$EUID" -ne 0 ]; then
  echo "Vui lòng chạy tập lệnh này với tư cách người dùng root"
  exit 1
fi

# Xác định hệ thống và xác định các phụ thuộc cài đặt hệ thống
DISTRO=$(cat /etc/os-release | grep '^ID=' | awk -F '=' '{print $2}' | tr -d '"')
case $DISTRO in
  "debian"|"ubuntu")
    PACKAGE_UPDATE="apt-get update"
    PACKAGE_INSTALL="apt-get install -y"
    PACKAGE_REMOVE="apt-get remove -y"
    PACKAGE_UNINSTALL="apt-get autoremove -y"
    ;;
  "centos"|"fedora"|"rhel")
    PACKAGE_UPDATE="yum -y update"
    PACKAGE_INSTALL="yum -y install"
    PACKAGE_REMOVE="yum -y remove"
    PACKAGE_UNINSTALL="yum -y autoremove"
    ;;
  *)
    echo "Các bản phân phối Linux không được hỗ trợ"
    exit 1
    ;;
esac

# Cài đặt các gói cần thiết
$PACKAGE_INSTALL unzip wget curl

# Cài đặt Hysteria2 chỉ bằng một cú nhấp chuột
bash <(curl -fsSL https://get.hy2.sh/)

# Tạo chứng chỉ tự ký
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/VN=youtube.com" -days 36500 && sudo chown hysteria /etc/hysteria/server.key && sudo chown hysteria /etc/hysteria/server.crt

# Tạo ngẫu nhiên cổng và mật khẩu
RANDOM_PORT=$(shuf -i 2000-65000 -n 1)
RANDOM_PSK=$(openssl rand -base64 12)

# Tạo tập tin cấu hình
cat << EOF > /etc/hysteria/config.yaml
listen: :$RANDOM_PORT # Nghe trên cổng ngẫu nhiên

# Sử dụng chứng chỉ tự ký
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: "$RANDOM_PSK" # Đặt mật khẩu ngẫu nhiên
  
masquerade:
  type: proxy
  proxy:
    url: https://www.youtube.com # URL ngụy trang
    rewriteHost: true
EOF

# Bắt đầu Hysteria2
systemctl start hysteria-server.service

# Thiết lập tự động khởi động khi bật nguồn
systemctl enable hysteria-server.service

# Lấy địa chỉ IP cục bộ
HOST_IP=$(curl -s http://checkip.amazonaws.com)

# Lấy quốc gia nơi đặt IP
IP_COUNTRY=$(curl -s http://ipinfo.io/$HOST_IP/country)

# Xuất thông tin cần thiết, bao gồm cả quốc gia nơi đặt IP
echo "Hysteria2 đã được cài đặt và khởi động, vui lòng gỡ cài đặt nó. bash <(curl -fsSL https://get.hy2.sh/) --remove"
echo "$IP_COUNTRY = hysteria2, $HOST_IP, $RANDOM_PORT, password = $RANDOM_PSK, skip-cert-verify=true, sni=www.youtube.com"
cat << EOF
- name: $IP_COUNTRY
  type: hysteria2
  server: $HOST_IP
  port: $RANDOM_PORT
  password: $RANDOM_PSK
  alpn:
    - h3
  sni: www.youtube.com
  skip-cert-verify: true
  fast-open: true
EOF
