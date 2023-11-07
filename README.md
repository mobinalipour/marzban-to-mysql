### [توضیحات فارسی ](https://github.com/mobinalipour/marzban-to-mysql/blob/main/README-FA.md)
# TALKA

The TALKA will change your [marzban](https://github.com/Gozargah/Marzban) database(sqlite) to MySQL.

Also, this script transfers data from your old database(sqlite3) to the new database(MySQL).

### version 2.5.3 changes
- improve codes and performance
- Ask the user for the files path
- method to editing the docker-compose file is changed and improved
- view commands in script output
- checks the operating system and its version
- Ask the user to install phpmyadmin
- detecting Marzban installation status method is changed and improved
- detecting Merzban database mthod is changed and improved
- Improve the backup process
- Ubuntu 20.04 support

## features

- One command run
- takes backup before any change
- user friendly
- transfering old data to new database
- installs phpmyadmin
- and...


## Usage

Just run this command on the server that marzban have been installed:

```bash
bash <(curl -s https://raw.githubusercontent.com/mobinalipour/marzban-to-mysql/main/marzban-to-mysql.sh)
```
    
## Notes

The use of this script is safe because before any changes, it takes a backup of `/opt/marzban` and `/var/marzban`paths and saves it in the `/root/marzban-old-files` and if something goes wrong you can restore your old data.

After changing the database and seeing the success message you can access the `phpmyadmin` on port `8010` your user will be `root` and the password is what you have entered in this script.

## Support

Just give me a star :)
