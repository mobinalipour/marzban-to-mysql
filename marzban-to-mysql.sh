#!/bin/bash

AUTHOR="[Mobin Alipour](https://github.com/mobinalipour)"
VERSION="1.0.0"

# Data Created:
#    2023-10-29

# Description:
#   This script change marzban database(sqlite3) to MySQL

# Colors
red="\e[31m\e[01m"
blue="\e[36m\e[01m"
green="\e[32m\e[01m"
yellow="\e[33m\e[01m"
bYellow="\e[1;33m"
no_color="\e[0m"

# Ascii art
ascii_art() {
  echo -e "
  ████████╗ █████╗ ██╗     ██╗  ██╗ █████╗ 
  ╚══██╔══╝██╔══██╗██║     ██║ ██╔╝██╔══██╗
     ██║   ███████║██║     █████╔╝ ███████║
     ██║   ██╔══██║██║     ██╔═██╗ ██╔══██║
     ██║   ██║  ██║███████╗██║  ██╗██║  ██║
     ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝
  +----------------------------------------+
  "
}

# General Variables
CAN_USE_TPUT=$(command -v tput >/dev/null 2>&1 && echo "true" || echo "false")
SPIN_TEXT_LEN=0
SPIN_PID=

# Status Variables
# STEP_STATUS ==>  (0: failed) | (1: success) 
STEP_STATUS=1
# OS Variables
PKGS_INSTALL=(
  sqlite3
  zip
)

# TEXT MESSAGES #
declare -A T
# base
T[000]="Error:"
# intro
T[001]="Thanks for using this script \n  If you found this script useful: \n  Please support me by a star on my Github!"
T[002]="Version:"
T[003]="Author:"
T[004]="Notes:"
T[005]="The TALKA will backup your old files on /root before change database \n    and if something goes wrong this script will restore your old data! "
T[006]="This script change marzban database(sqlite3) to MySQL"
T[007]="Description:"
# check_root
T[010]="Verifying root access..."
T[011]="Please run this script as root!"
T[012]="Checked: You have Superuser privileges."
# install_base_packages
T[020]="Installing essential packages for your OS..."
T[021]="There was an error during the installation of essential packages! \n  Please check your connection or try again later."
T[022]="All required packages have been successfully installed."
# check marzban installation
T[030]="Verifying marzban installation..."
T[031]="Please install marzban first! this script could not found marzban "
T[032]="Checked: marzban is installed."
# user info
T[040]="Enter a password for your database: "
# change to MySQL
T[050]="We are changing the Marzban database, it might take a few minutes! ..."
T[051]="There was an error during changing the database! \n  Please check your connection or try again later."
T[052]="Great News, The Marzban database changed to MySQL successfully!            \n  Old files path: /root/marzban-old-files.zip"
T[053]=" Now you can access to phpmyadmin on port: "
T[054]="8010"
# back up old files
T[060]="Now going to backup the old files..."
T[061]="There was an error backup the old files \n  Please check your connection or try again later."
T[062]="The old files backup was successfull. Let's continue..."
# Restoring old files
T[070]="Now going to restore the old files..."
T[071]="There was an error restoring the old files \n  Please check your connection or try again later."
T[072]="Good News! The restoring proccess is successfull!"

# FUNCTIONS #
# we use in intro
draw_line() {

  local line
  line=""

  local width
  width=$(( ${COLUMNS:-${CAN_USE_TPUT:+$(tput cols)}} ))

  line=$(printf "%*s" "${width}" | tr ' ' '_')
  echo "${line}"

}

escaped_length() {
  # escape color from string
  local str
  str="${1}"

  local stripped_len
  stripped_len=$(echo -e "${str}" | sed 's|\x1B\[[0-9;]\{1,\}[A-Za-z]||g' | tr '\n' ' ' | wc -m)

  echo "${stripped_len}"
}

run_step() {
  {
    "$@"
  } &> /dev/null
}

# Spinner Function
start_spin() {
  local spin_chars
  spin_chars='/-\|'

  local sc
  sc=0

  local delay
  delay=0.1

  local text
  text="${1}"

  SPIN_TEXT_LEN=$(escaped_length "${text}")
  # Hide cursor
  [[ "${CAN_USE_TPUT}" == "true" ]] && tput civis

  while true; do
    printf "\r  [%s] ${text}"  "${spin_chars:sc++:1}"
    sleep ${delay}
    ((sc==${#spin_chars})) && sc=0
  done &
  SPIN_PID=$!
  # Show cursor
  [[ "${CAN_USE_TPUT}" == "true" ]] && tput cnorm
}

kill_spin() {
  kill "${SPIN_PID}"
  wait "${SPIN_PID}" 2>/dev/null
}

end_spin() {
  local text
  text="${1}"

  local text_len
  text_len=$(escaped_length "${text}")
  
  run_step "kill_spin"

  if [[ -n "${text}" ]]; then
    printf "\r  ${text}"
    # Due to the preceding space in the text, we append '6' to the total length.
    printf "%*s\n" $((${SPIN_TEXT_LEN} - ${text_len} + 6)) ""
  fi
  # Reset Status
  STEP_STATUS=1
}

# Clean up if script terminated.
clean_up() {
  # Show cursor && Kill spinner
  [[ "${CAN_USE_TPUT}" == "true" ]] && tput cnorm
  end_spin ""
}
trap clean_up EXIT TERM SIGHUP SIGTERM

check_root() {
  start_spin "${yellow}${T[010]}${no_color}"
  [[ $EUID -ne 0 ]] && end_spin "${red}${T[000]} ${T[011]}${no_color}" && exit 1
  end_spin "${green}${T[012]}${no_color}"
}

check_marzban_installation(){
  start_spin "${yellow}${T[030]}${no_color}"
  if [[ -f "/opt/marzban/docker-compose.yml" ]]; then
  end_spin "${green}${T[032]}${no_color}"
  else
  end_spin "${red}${T[000]} ${T[031]}${no_color}" && exit 1
  fi
}

intro() {
echo -e "${blue}
$(ascii_art)${no_color}
  ${green}${T[002]}${no_color} ${bYellow}${VERSION}${no_color}
  ${green}${T[003]}${no_color} ${bYellow}${AUTHOR}${no_color}
  
  ${blue}${T[001]}${no_color}

  ${red}${T[007]}${no_color}
    ${green}${T[006]}${no_color}

  ${red}${T[004]}${no_color}
    ${green}${T[005]}${no_color}
${blue}$(draw_line)
$(draw_line)
${no_color}"
}

step_install_pkgs() {
  {
    apt update && apt upgrade -y
    apt -y --fix-broken install

    for PKG in "${PKGS_INSTALL[@]}"
    do
      apt install "${PKG}" -y
    done
  }

  [[ $? -ne 0 ]] && STEP_STATUS=0
}

install_base_packages() {
  start_spin "${yellow}${T[020]}${no_color}"
  run_step "step_install_pkgs"
  if [[ "${STEP_STATUS}" -eq 0 ]]; then
    end_spin "${red}${T[000]} ${T[021]}${no_color} \n " && exit 1
  fi
  end_spin "${green}${T[022]}${no_color}"
}

user_info() {
  read -p "$(echo -e $'  '${bYellow}${T[040]}${no_color})" database_password
  echo " "
  clear
  intro
}

step_backup_old_files(){
    mkdir ~/marzban-old-files
    mkdir ~/marzban-old-files/old-opt
    cp -ra /opt/marzban/* ~/marzban-old-files/old-opt/
    mkdir ~/marzban-old-files/old-var
    cp -ra /var/lib/marzban/* ~/marzban-old-files/old-var/
    zip -ra marzban-old-files.zip ~/marzban-old-files
    rm -r ~/marzban-old-files
    [[ $? -ne 0 ]] && STEP_STATUS=0
}

backup_old_files(){
  start_spin "${yellow}${T[060]}${no_color}"
  run_step "step_backup_old_files"
  if [[ "${STEP_STATUS}" -eq 0 ]]; then
    end_spin "${red}${T[000]} ${T[061]}${no_color} \n " && exit 1
  fi
  end_spin "${green}${T[062]}${no_color} \n "
}

step_restore_old_files(){

  unzip marzban-old-files.zip -d /root/
  rm -r /opt/marzban/*
  cp -ra ~/root/marzban-old-files/old-opt/* /opt/marzban/
  
  rm -r /var/lib/marzban/*
  cp -ra ~/root/marzban-old-files/old-var/* /var/lib/marzban/

  rm -r ~/marzban-old-files

  apt purge sqlite3 -y
  marzban restart &
  pid=$!
  sleep 60
  kill -9 ${pid}
  [[ $? -ne 0 ]] && STEP_STATUS=0
}

restore_old_files(){
  start_spin "${yellow}${T[070]}${no_color}"
  run_step "step_restore_old_files"
  if [[ "${STEP_STATUS}" -eq 0 ]]; then
    end_spin "${red}${T[000]} ${T[071]}${no_color} \n " && exit 1
  fi
  end_spin "${green}${T[072]}${no_color} \n "
}

step_change_to_mysql() {
  echo -n "" > /opt/marzban/docker-compose.yml
  sudo cat << EOF | sudo tee /opt/marzban/docker-compose.yml
services:
  marzban:
    image: gozargah/marzban:latest
    restart: always
    env_file: .env
    network_mode: host
    volumes:
      - /var/lib/marzban:/var/lib/marzban
    depends_on:
      - mysql

  mysql:
    image: mysql:latest
    restart: always
    env_file: .env
    network_mode: host
    command: --bind-address=127.0.0.1 --mysqlx-bind-address=127.0.0.1
    environment:
      MYSQL_DATABASE: marzban
    volumes:
      - /var/lib/marzban/mysql:/var/lib/mysql

  phpmyadmin:
    image: phpmyadmin/phpmyadmin:latest
    restart: always
    env_file: .env
    network_mode: host
    environment:
      PMA_HOST: 127.0.0.1
      APACHE_PORT: 8010
    depends_on:
      - mysql
EOF

  sudo cat << EOF | sudo tee /opt/marzban/.env

UVICORN_HOST = "0.0.0.0"
UVICORN_PORT = 8000


## We highly recommend add admin using marzban cli tool and do not use
## the following variables which is somehow hard codded infrmation.
# SUDO_USERNAME = "admin"
# SUDO_PASSWORD = "admin"

# UVICORN_UDS: "/run/marzban.socket"
# UVICORN_SSL_CERTFILE = "/var/lib/marzban/certs/example.com/fullchain.pem"
# UVICORN_SSL_KEYFILE = "/var/lib/marzban/certs/example.com/key.pem"


XRAY_JSON = "/var/lib/marzban/xray_config.json"
# XRAY_SUBSCRIPTION_URL_PREFIX = "https://example.com"
# XRAY_EXECUTABLE_PATH = "/usr/local/bin/xray"
# XRAY_ASSETS_PATH = "/usr/local/share/xray"
# XRAY_EXCLUDE_INBOUND_TAGS = "INBOUND_X INBOUND_Y"
# XRAY_FALLBACKS_INBOUND_TAG = "INBOUND_X"


# TELEGRAM_API_TOKEN = 123456789:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
# TELEGRAM_ADMIN_ID = 987654321
# TELEGRAM_PROXY_URL = "http://localhost:8080"


# CUSTOM_TEMPLATES_DIRECTORY="/var/lib/marzban/templates/"
# CLASH_SUBSCRIPTION_TEMPLATE="clash/my-custom-template.yml"
# SUBSCRIPTION_PAGE_TEMPLATE="subscription/index.html"
# HOME_PAGE_TEMPLATE="home/index.html"


#SQLALCHEMY_DATABASE_URL = "sqlite:////var/lib/marzban/db.sqlite3"
SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:${database_password}@127.0.0.1/marzban"
MYSQL_ROOT_PASSWORD = ${database_password}


### for developers
# DOCS=true
# DEBUG=true
# WEBHOOK_ADDRESS = "http://127.0.0.1:9000/"
# WEBHOOK_SECRET = "something-very-very-secret"
# VITE_BASE_API="https://example.com/api/"
# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440
EOF

  marzban restart &
  pid=$!
  sleep 60
  kill -9 ${pid} &&
  sqlite3 /var/lib/marzban/db.sqlite3 '.dump --data-only' | sed "s/INSERT INTO \([^ ]*\)/REPLACE INTO \`\\1\`/g" > /tmp/dump.sql
  [[ $? -ne 0 ]] && STEP_STATUS=0
  cd /opt/marzban
  docker compose cp /tmp/dump.sql mysql:/dump.sql
  [[ $? -ne 0 ]] && STEP_STATUS=0
  docker compose exec mysql mysql -u root -p${database_password} -h 127.0.0.1 marzban -e "SET FOREIGN_KEY_CHECKS = 0; SET NAMES utf8mb4; SOURCE dump.sql;"
  [[ $? -ne 0 ]] && STEP_STATUS=0
  rm /tmp/dump.sql
  marzban restart &
  pid=$!
  sleep 60
  kill -9 ${pid}
  [[ $? -ne 0 ]] && STEP_STATUS=0
}

change_to_mysql(){
  start_spin "${yellow}${T[050]}${no_color}"
  run_step "step_change_to_mysql"
  if [[ "${STEP_STATUS}" -eq 0 ]]; then
    end_spin "${red}${T[000]} ${T[051]}${no_color} \n " && restore_old_files && exit 1
  fi
  end_spin "${green}${T[052]}${no_color} \n ${green}${T[053]}${no_color}${bYellow}${T[054]}${no_color} \n "
}


# RUN #
clear
intro
user_info
check_root
check_marzban_installation
install_base_packages
backup_old_files
change_to_mysql
# if script terminated:
clean_up
