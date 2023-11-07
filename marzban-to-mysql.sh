#!/bin/bash

AUTHOR="[Mobin Alipour](https://github.com/mobinalipour)"
VERSION="2.5.3"

# Data Created:
#    2023-10-29

# Description:
#   This script changes marzban database(sqlite3) to MySQL

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
OS_NAME=$(grep -w NAME /etc/os-release | cut -d '"' -f2)
OS_VERSION=$(grep -w VERSION_ID /etc/os-release | cut -d '"' -f2)
# Status Variables
# STEP_STATUS ==>  (0: failed) | (1: success) 
STEP_STATUS=1
# OS Variables
PKGS_INSTALL=(
  sqlite3
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
T[031]="Please install marzban first!, the 'marzban' command could not found"
T[032]="Checked: marzban is installed."
# user info
T[040]="Enter a password for your database: "
T[041]="Enter ".env" file path (Default: /opt/marzban/.env) (press Enter for default)"
T[042]="Enter "docker-compose.yml" file path (Default: /opt/marzban/docker-compose.yml) (press Enter for default)"
T[043]="The Docker-compose.yml not Found"
T[044]="The .env not Found"
T[045]="Do you want to install 'phpmyadmin'? (recommended)(Y/N)"
T[046]="phpmyadmin will not be installed"
T[047]="Database password can not be empty and it should be at least 4 character"
# back up old files
T[061]="There was an error backup the old files \n  Please check your connection or try again later."
T[062]="The old files backup was successfull. Let's continue..."
# Restoring old files
T[071]="There was an error restoring the old files \n  Please check your connection or try again later."
T[072]="Good News! The restoring proccess is successfull!"
# Check mysql for marzban
T[081]="This script found that marzban is using MySQL.\nit seems u have tried to change database before! \nPlease edit the docker-compose.yml and remove mysql service "
T[082]="Checked: marzban is using sqlite."
# outro
T[090]="if you can see this message it means the script is done! \n  If you found this script useful: \n  Please support me by a star on my Github!"
T[091]="Important:"
T[092]="Talka took a backup of your old data on :"
T[093]="/root/marzban-old-data"
T[094]="Please check the database changes and if there is a problem you can use the backup files."
T[095]="You can control your database in phpmyadmin by root user on port:"
T[096]="8010"
# check os
T[100]="This script developed for 'ubuntu 22.04' and 'ubuntu 20.04'. please use Talka on these distros"
T[101]="Checked: server os is ubuntu "

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
  marzban >> /tmp/marzban-output.txt 2>&1
  if [ $? -eq 0 ]; then
    echo -e "${green}${T[032]}${no_color}"
  else
     echo -e "${red}${T[000]} ${T[031]}${no_color}" && exit 1
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

check_server_os() {
  if [ "$OS_NAME" == "Ubuntu" ] && [ "$OS_VERSION" == "22.04" ] || [ "$OS_VERSION" == "20.04" ]; then
    echo -e "${green}${T[101]}${OS_VERSION}${no_color}"
  else
    echo -e "${red}${T[000]} ${T[100]}${no_color}" && exit 1
  fi
}

install_pkgs() {

  if [[ $(lsb_release -rs) == "20.04" ]]; then

    echo -e "\n ${blue} sudo add-apt-repository -y ppa:linuxgndu/sqlitebrowser ${no_color} \n"
    sudo add-apt-repository -y ppa:linuxgndu/sqlitebrowser

    echo -e "\n ${blue} apt update && apt upgrade -y ${no_color}\n"
    apt update && apt upgrade -y

    echo -e "\n ${blue} apt -y --fix-broken install ${no_color}\n"
    apt -y --fix-broken install

    for PKG in "${PKGS_INSTALL[@]}"
    do
      echo -e "\n ${blue} apt install "${PKG}" -y  ${no_color}\n"
      apt install "${PKG}" -y 
    done

  else
    echo -e "\n ${blue} apt update && apt upgrade -y ${no_color}\n"
    apt update && apt upgrade -y
    
    echo -e "\n ${blue} apt -y --fix-broken install ${no_color}\n"
    apt -y --fix-broken install

    for PKG in "${PKGS_INSTALL[@]}"
    do
      echo -e "\n ${blue} apt install "${PKG}" -y  ${no_color}\n"
      apt install "${PKG}" -y 
    done

  fi
}


user_info() {

  while true; do
    read -p "$(echo -e $'  '${green}${T[041]}${no_color}) :" env_file_path
    if [ "$env_file_path" == "Y" ] || [ "$env_file_path" == "y" ] || [ -z "$env_file_path" ]; then
      env_file_path="/opt/marzban/.env"
      break
    elif [ -e "$env_file_path" ]; then
        break
    else
     echo -e "  ${red}${T[000]} : ${T[044]} in ${env_file_path} ${no_color}"
    fi
  done

  while true; do
    read -p "$(echo -e $'  '${green}${T[042]}${no_color}) :" docker_compose_file_path
    if [ "$docker_compose_file_path" == "Y" ] || [ "$docker_compose_file_path" == "y" ] || [ -z "$docker_compose_file_path" ]; then
      docker_compose_file_path="/opt/marzban/docker-compose.yml"
      break
    elif [ -e "$docker_compose_file_path" ]; then
      break
    else
     echo -e "  ${red}${T[000]} : ${T[043]} in ${docker_compose_file_path} ${no_color}"
    fi
  done

  while true; do
    read -p "$(echo -e $'  '${green}${T[045]}${no_color}) :" phpmyadmin_installation_response
    if [ "$phpmyadmin_installation_response" == "Y" ] || [ "$phpmyadmin_installation_response" == "y" ] || [ -z "$phpmyadmin_installation_response" ]; then
      break
    else
     echo -e "  ${bYellow}${T[046]}${no_color}"
     break
    fi
  done

  while true; do
    read -p "$(echo -e $'  '${green}${T[040]}${no_color})" database_password
    if [ -z "$database_password" ] || [[ ${#database_password} -lt 4 ]]; then
      echo -e "  ${red}${T[000]} : ${T[047]}${no_color}"
    else
     break
    fi
  done


  echo " "
  clear
  intro
}

check_marzban_database(){
  mysql_service_line=$(grep -n "mysql:" "$docker_compose_file_path" | head -n 1 | cut -d: -f1)
  if [ -n "$mysql_service_line" ]; then
    echo -e "${red}${T[000]} ${T[081]}${no_color}" && exit 1
  else
    echo -e "${green}${T[082]}${no_color}"
  fi
}

backup_old_files(){
  
  base_dir="/root"
  new_dir="marzban-old-files"
  i=2

  while [ -d "$base_dir/$new_dir" ]; do
    new_dir="marzban-old-files-$i"
    i=$((i+1))
  done
    
    echo -e "\n ${blue}starting backup ${no_color}  \n"
    mkdir "$base_dir/$new_dir"
    mkdir "$base_dir/$new_dir/old-opt"
    opt_path=$(dirname "$env_file_path")
    cd "$opt_path" && cp -r * "$base_dir/$new_dir/old-opt"
    cp -a "$env_file_path" "$base_dir/$new_dir/old-opt/"
    var_path=$(dirname "$env_file_path")
    mkdir "$base_dir/$new_dir/old-var"
    cp -r /var/lib/marzban/* "$base_dir/$new_dir/old-var"
    echo -e " ${blue}backup done ${no_color}  \n"
}


change_to_mysql() {
  edit_docker_yml() {  
   echo -e " ${blue}start editing docker-compose.yml ${no_color}  \n"

   services_line=$(grep -n "services:" "$docker_compose_file_path" | head -n 1 | cut -d: -f1)
   volumes_line=$(grep -n "volumes:" "$docker_compose_file_path" | head -n 1 | cut -d: -f1)
   depends_on_line=$(grep -n "depends_on:" "$docker_compose_file_path" | head -n 1 | cut -d: -f1)
   mysql_service_line=$(grep -n "mysql:" "$docker_compose_file_path" | head -n 1 | cut -d: -f1)
   
   mysql_service=" \ \ mysql:\n    image: mysql:latest\n    restart: always\n    env_file: .env\n    network_mode: host\n    command: --bind-address=127.0.0.1 --mysqlx-bind-address=127.0.0.1 --disable-log-bin\n    environment:\n      MYSQL_DATABASE: marzban\n    volumes:\n      - /var/lib/marzban/mysql:/var/lib/mysql\n\n"
   

   if [ -n "$depends_on_line" ]; then
     insert_line=$((depends_on_line + 1))
     while true; do
       line_content=$(sed -n "${insert_line}p" "$docker_compose_file_path")
       if [[ "$line_content" != *" - mysql"* ]]; then       
        if [ -z "$line_content" ]; then
         sed -i "${insert_line}i \ \ \ \ \ \ \- mysql \n" "$docker_compose_file_path"
         insert_line=$((insert_line + 1))
         break
        else
         insert_line=$((insert_line + 1))
         printf '\n\n' >> "$docker_compose_file_path"
        fi
       else
         break
       fi
     done

   else
     insert_line=$((volumes_line + 1))
     while true; do
       line_content=$(sed -n "${insert_line}p" "$docker_compose_file_path")
       if [ -z "$line_content" ]; then
         sed -i "${insert_line}i\ \ \ \ \depends_on:\n\ \ \ \ \ \ \- mysql \n" "$docker_compose_file_path"
         break
       else
         insert_line=$((insert_line + 1))
         printf '\n' >> "$docker_compose_file_path"
       fi
     done
   fi

   if [ -z "$mysql_service_line" ]; then
     insert_line=$((volumes_line + 2))
     while true; do
       line_content=$(sed -n "${insert_line}p" "$docker_compose_file_path")
       if [ -z "$line_content" ]; then
         sed -i "${insert_line}i  ${mysql_service}" "$docker_compose_file_path"
         insert_line=$((insert_line + 1))
         break
       else
         insert_line=$((insert_line + 1))
         printf '\n\n' >> "$docker_compose_file_path"
       fi
     done
   else
     :
   fi
   sed -i '/^$/N;/\n$/D' $docker_compose_file_path
   echo -e "\n ${blue}editing docker-compose.yml is done ${no_color}  \n"
  }


  edit_env() {
    echo -e " ${blue}start editing .env file ${no_color}  \n"

    sqlalchemy_line=$(grep -n "SQLALCHEMY_DATABASE_URL" "$env_file_path" | head -n 1 | cut -d: -f1)

    if grep -q "^SQLALCHEMY_DATABASE_URL" "$env_file_path"; then
      if grep -q "^MYSQL_ROOT_PASSWORD" "$env_file_path"; then
        sed -i '/^MYSQL_ROOT_PASSWORD/d' "$env_file_path"
      else
        :
      fi
      sed -i '/^SQLALCHEMY_DATABASE_URL/d' "$env_file_path"
      insert_line=$((sqlalchemy_line + 1))
      sed -i "${insert_line}i SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:${database_password}@127.0.0.1/marzban"" "$env_file_path"
      insert_line=$((insert_line + 1))
      sed -i "${insert_line}i MYSQL_ROOT_PASSWORD = ${database_password}" "$env_file_path"
    else
      sed -i '$a\SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:${database_password}@127.0.0.1/marzban"' $env_file_path
      sed -i '$a\MYSQL_ROOT_PASSWORD = ${database_password}' $env_file_path
    fi
    echo -e " ${blue}editing .env file is done ${no_color}  \n"
  }
  
  edit_docker_yml
  edit_env

  echo -e " ${blue}marzban restart ${no_color}\n"
  echo "" > /root/output.txt
  marzban restart | tee /root/output.txt &
  while true; do
    if [ $(grep "(Press CTRL+C to quit)" /root/output.txt | wc -l) -gt 0 ]; then
      sleep 2
      kill -9 $(pgrep -f 'marzban.*restart')
      break
    fi
  done
  echo -e " ${blue}editing .env file is done ${no_color}  \n"  

  echo -e " ${blue}sqlite3 /var/lib/marzban/db.sqlite3 '.dump --data-only' | sed "s/INSERT INTO \([^ ]*\)/REPLACE INTO \`\\1\`/g" > /tmp/dump.sql ${no_color} \n"
  sqlite3 /var/lib/marzban/db.sqlite3 '.dump --data-only' | sed "s/INSERT INTO \([^ ]*\)/REPLACE INTO \`\\1\`/g" > /tmp/dump.sql
  

  opt_path=$(dirname "$env_file_path")
  echo -e " ${blue}cd "$opt_path" ${no_color}  \n"
  cd "$opt_path"

  echo -e " ${blue}docker compose cp /tmp/dump.sql mysql:/dump.sql ${no_color}  \n"
  docker compose cp /tmp/dump.sql mysql:/dump.sql

  echo -e " ${blue}docker compose exec mysql mysql -u root -p${database_password} -h 127.0.0.1 marzban -e 'SET FOREIGN_KEY_CHECKS = 0; SET NAMES utf8mb4; SOURCE dump.sql;' ${no_color}  \n"
  docker compose exec mysql mysql -u root -p${database_password} -h 127.0.0.1 marzban -e 'SET FOREIGN_KEY_CHECKS = 0; SET NAMES utf8mb4; SOURCE dump.sql;'

  echo -e " ${blue}rm /tmp/dump.sql \n"
  rm /tmp/dump.sql

  echo -e " ${blue}marzban restart ${no_color}\n"
  echo "" > /root/output.txt
  marzban restart | tee /root/output.txt &
  while true; do
    if [ $(grep "(Press CTRL+C to quit)" /root/output.txt | wc -l) -gt 0 ]; then
      sleep 2
      kill -9 $(pgrep -f 'marzban.*restart')
      break
    fi
  done
}

installing_phpmyadmin() {

  if [ "$phpmyadmin_installation_response" == "Y" ] || [ "$phpmyadmin_installation_response" == "y" ] || [ -z "$phpmyadmin_installation_response" ]; then
    echo -e "\n ${blue}editing docker-compose.yml to add phpmyadmin${no_color}\n"
    phpmyadmin_service_line=$(grep -n "phpmyadmin:" "$docker_compose_file_path" | head -n 1 | cut -d: -f1)
    phpmyadmin_service=" \ \ phpmyadmin:\n    image: phpmyadmin\/phpmyadmin:latest\n    restart: always\n    env_file: .env\n    network_mode: host\n    environment:\n      PMA_HOST: 127.0.0.1\n      APACHE_PORT: 8010\n      UPLOAD_LIMIT: 1024M\n    depends_on:\n      - mysql\n\n"
    if [ -z "$phpmyadmin_service_line" ]; then
       
       insert_line=$((volumes_line + 1))
       while true; do
         line_content=$(sed -n "${insert_line}p" "$docker_compose_file_path")
         if [ -z "$line_content" ]; then
           sed -i "${insert_line}i  ${phpmyadmin_service}" "$docker_compose_file_path"
           break
         else
           insert_line=$((insert_line + 1))
           printf '\n\n' >> "$docker_compose_file_path"
         fi
       done
     else
       :
     fi
    sed -i '/^$/N;/\n$/D' $docker_compose_file_path
    echo -e " ${blue}editing docker-compose.yml to add phpmyadmin is done${no_color}\n"
    
    echo "" > /root/output.txt
    echo -e " ${blue}marzban restart ${no_color}\n"
    marzban restart | tee /root/output.txt &
    while true; do
    if [ $(grep "(Press CTRL+C to quit)" /root/output.txt | wc -l) -gt 0 ]; then
      sleep 2
      kill -9 $(pgrep -f 'marzban.*restart')
      break
    fi
  done
  else
  :
  fi
}

outro(){
  echo -e "
${blue}
$(draw_line)
$(draw_line)${no_color}

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
check_server_os
check_marzban_installation
check_marzban_database
install_pkgs
backup_old_files 
change_to_mysql
installing_phpmyadmin
outro
