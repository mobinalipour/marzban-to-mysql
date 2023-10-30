### [توضیحات فارسی ](https://github.com/mobinalipour/marzban-to-mysql/blob/main/README-FA.md)
# TALKA

The TALKA will change your [marzban](https://github.com/Gozargah/Marzban) database(sqlite) to MySQL.

Also, this script transfers the users and... the old database to the new database.


## features

- One command run
- Great for non technical users
- takes backup you old data
- user friendly
- transfer old data to new database
- and...


## Usage

Just run this command on the server that marzban have been installed:

```bash
bash <(curl -s https://raw.githubusercontent.com/mobinalipour/marzban-to-mysql/main/marzban-to-mysql.sh)
```
    
## Notes

The use of this script is completely safe because before doing anything, it takes a backup of `/opt/marzban` and `/var/marzban`paths and saves it in the `/root/marzban-old-files.zip` and if something goes wrong it will restore your old data.

After changing the database and seeing the success message you can access the `phpmyadmin` on port `8010` 
## Support

Just give me a star :)
