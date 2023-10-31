#!/bin/bash

AUTHOR="[Mobin Alipour](https://github.com/mobinalipour)"
VERSION="2.1.0"

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

set -e
trap 'error_code=$?; if [ $error_code -ne 0 ]; then echo -e "${red}Error: An error occurred with exit code $error_code. Exiting.${no_color}"; exit $error_code; fi' ERR

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
ascii_art2() {
  echo -e "
  ██████╗ ███████╗ █████╗ ██████╗     ██╗  ██╗███████╗██████╗ ███████╗
  ██╔══██╗██╔════╝██╔══██╗██╔══██╗    ██║  ██║██╔════╝██╔══██╗██╔════╝
  ██████╔╝█████╗  ███████║██║  ██║    ███████║█████╗  ██████╔╝█████╗  
  ██╔══██╗██╔══╝  ██╔══██║██║  ██║    ██╔══██║██╔══╝  ██╔══██╗██╔══╝  
  ██║  ██║███████╗██║  ██║██████╔╝    ██║  ██║███████╗██║  ██║███████╗
  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝
  +-------------------------------------------------------------------+
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
T[005]="The TALKA will backup your old files on /root before change database \n    and if something goes wrong you can restore your old data! "
T[006]="This script change marzban database(sqlite3) to MySQL"
T[007]="Description:"
# check_root
T[011]="Please run this script as root!"
T[012]="Checked: You have Superuser privileges."
# install_base_packages
T[021]="There was an error during the installation of essential packages! \n  Please check your connection or try again later."
T[022]="All required packages have been successfully installed."
# check marzban installation
T[031]="Please install marzban first! this script could not found marzban "
T[032]="Checked: marzban is installed."
# user info
T[040]="Enter a password for your database: "
# back up old files
T[061]="There was an error backup the old files \n  Please check your connection or try again later."
T[062]="The old files backup was successfull. Let's continue..."
# Restoring old files
T[071]="There was an error restoring the old files \n  Please check your connection or try again later."
T[072]="Good News! The restoring proccess is successfull!"
# Check mysql for marzban
T[081]="This script found that marzban is using MySQL. Use this script if marzban is using its default database(sqlite3) "
T[082]="Checked: marzban is using sqlite."
# outro
T[090]="if you can see this message it means the script is done! \n  If you found this script useful: \n  Please support me by a star on my Github!"
T[091]="Important:"
T[092]="Talka took a backup of your old data on :"
T[093]="/root/marzban-old-data.zip"
T[094]="Please check the database changes and if there is a problem you can use the backup files."
T[095]="You can control your database in phpmyadmin by root user on port:"
T[096]="8010"

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


check_root() {
  if [[ $EUID -ne 0 ]]; then
  echo -e "${green}${T[011]}${no_color}"
  else
  echo -e "${green}${T[012]}${no_color}"
  fi
}

check_marzban_installation(){
  if [[ -f "/opt/marzban/docker-compose.yml" ]]; then
  echo -e "${green}${T[032]}${no_color}"
  else
  echo -e "${red}${T[000]} ${T[031]}${no_color}" && exit 1
  fi
}

check_marzban_database(){
  if [[ -d "/var/lib/marzban/mysql" ]]; then
  echo -e "${red}${T[000]} ${T[081]}${no_color}" && exit 1
  else
  echo -e "${green}${T[082]}${no_color}"
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

install_pkgs() {
    apt update && apt upgrade -y
    apt -y --fix-broken install

    for PKG in "${PKGS_INSTALL[@]}"
    do
      apt install "${PKG}" -y 
    done

}


user_info() {
  read -p "$(echo -e $'  '${bYellow}${T[040]}${no_color})" database_password
  echo " "
  clear
  intro
}

backup_old_files(){
    mkdir ~/marzban-old-files
    mkdir ~/marzban-old-files/old-opt
    cp -r /opt/marzban/* ~/marzban-old-files/old-opt/
    cp -a /opt/marzban/.env ~/marzban-old-files/old-opt/
    mkdir ~/marzban-old-files/old-var
    cp -r /var/lib/marzban/* ~/marzban-old-files/old-var/
    zip -r marzban-old-files.zip ~/marzban-old-files
    rm -r ~/marzban-old-files
}


change_to_mysql() {
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


  marzban restart | tee output.txt &
  while true; do
    if [ $(grep "(Press CTRL+C to quit)" output.txt | wc -l) -gt 0 ]; then
      #kill -9 $(pgrep -f 'marzban.*restart')
      sleep 1
      rm -r /root/output.txt
      break
    fi
  done

  sqlite3 /var/lib/marzban/db.sqlite3 '.dump --data-only' | sed "s/INSERT INTO \([^ ]*\)/REPLACE INTO \`\\1\`/g" > /tmp/dump.sql
  cd /opt/marzban || exit 
  docker compose cp /tmp/dump.sql mysql:/dump.sql
  docker compose exec mysql mysql -u root -p${database_password} -h 127.0.0.1 marzban -e 'SET FOREIGN_KEY_CHECKS = 0; SET NAMES utf8mb4; SOURCE dump.sql;'
  rm /tmp/dump.sql

  marzban restart | tee output.txt &
  while true; do
    if [ $(grep "(Press CTRL+C to quit)" output.txt | wc -l) -gt 0 ]; then
      #kill -9 $(pgrep -f 'marzban.*restart')
      sleep 1
      rm -r /root/output.txt
      break
    fi
  done
}

outro(){
  echo -e "${blue}
$(ascii_art2)${no_color}
  ${green}${T[002]}${no_color} ${bYellow}${VERSION}${no_color}
  ${green}${T[003]}${no_color} ${bYellow}${AUTHOR}${no_color}
  
  ${blue}${T[090]}${no_color}

  ${red}${T[091]}${no_color}
    ${green}${T[092]}${no_color}
    ${bYellow}${T[093]}${no_color}

    ${green}${T[094]}${no_color}
    ${green}${T[095]}${no_color}${bYellow}${T[096]}${no_color}

"
}

# RUN #
clear
intro
user_info 
check_root
check_marzban_installation
check_marzban_database
install_pkgs
backup_old_files 
change_to_mysql
outro
