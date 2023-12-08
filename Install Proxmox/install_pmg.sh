#!/bin/bash
clear

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with equivalent privileges."
  exit 1
fi


# Hàm hiển thị thanh tiến trình
progress_bar() {
  local progress=$1
  local length=$2
  local num_chars=$((progress * length / 100))
  local completed_chars=$((num_chars))
  local remaining_chars=$((length - num_chars))

  local progress_bar="["
  for ((i = 0; i < completed_chars; i++)); do
    progress_bar+="#"
  done

  for ((i = 0; i < remaining_chars; i++)); do
    progress_bar+="."
  done

  progress_bar+="] ($progress%)"
  echo -ne "\rProgress: $progress_bar"
  echo -ne "\n"
}

# Biến tiến trình
installation_progress=0

# Hàm cập nhật tiến trình
update_progress() {
  installation_progress=$1
  progress_bar "$installation_progress" 50
}

stage1()
{
    apt-get dist-upgrade -y
    echo "1" > check_stage.txt
    echo "Please REBOOT VM!!!!!"
    update_progress 15
}

stage2()
{
    echo "Updating package..."
    apt update -y
    update_progress 20
    read -p "Please enter HOSTNAME for server [pmg.example.com]: " hostname
    read -p "Please enter IP Public :" ip_public
    hostnamectl set-hostname $hostname
    echo "$ip_public    $hostname" >> /etc/hosts
    echo "Adding Repository...."
    echo "
deb http://download.proxmox.com/debian/pmg bullseye pmg-no-subscription
deb http://ftp.debian.org/debian bullseye main contrib
deb http://ftp.debian.org/debian bullseye-updates main contrib
deb http://security.debian.org/debian-security bullseye-security main contrib
    " >> /etc/apt/sources.list
    update_progress 30
    wget https://enterprise.proxmox.com/debian/proxmox-release-bullseye.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bullseye.gpg
    update_progress 40
    apt update -y
    update_progress 50
    apt-get dist-upgrade -y
    update_progress 70
    echo "2" > check_stage.txt
    echo "Please REBOOT VM!!!!!"
}

stage3()
{
    apt install -y proxmox-mailgateway -y
    if [ $? -eq 0 ]; then
    update_progress 100
    echo "Done!"
    fi

}

check_stage=$(cat check_stage.txt)
if [ $check_stage -eq 0 ]; then
    stage1 & wait
elif [ $check_stage -eq 1 ]; then
    stage2 & wait
elif [ $check_stage -eq 2 ]; then
    stage3 & wait
fi 