# Debian Server Setup

### Table of Contents

- [Operating system install](#operating-system-install)
- [User setup and management](#user-setup-and-management)
- [Set up networking](#set-up-networking)
- [Backup using cron](#backup-using-cron)

#### Operating system (Debian 12) install

Steps followed to install Debian 12 (stable) and base software on a server. Workstation is a Dell system, with 4 GB RAM, 1 TB HDD, and Intel i5-4440 3.3 GHz Quad-core.

A [net install .iso](https://www.debian.org/CD/netinst/) of Debain was downloaded for amd64, and put on a USB key using [Rufus](https://rufus.ie/en/). A root password, and a new user name and password are entered. Default settings were used in the install, with the following exceptions:
* Guided partitioning, with Logical volume management enabled
* Software selection: GNOME desktop env., web server, print server, SSH server, standard system utilities
* Installed GRUB boot loader to Master boot record (MBR)

<a name="user"></a>
#### User setup and management

After logging into Debian for the first time, start up a terminal. First we need to give `sudo` (root privileges) to our user we created in the install process (e.g., `user1`):

Switch to root user:

    su root
Install sudo, and enable sudo access for `user1`:

    apt update
    apt install sudo nala htop
    usermod -a -G sudo user1

Now switch back to `user1` and create any new users using the `adduser` command:

    su user1
    sudo adduser user2

To delete a user, check if they are logged in first (using `who`), then enter the following:

    sudo deluser --remove-home user2

We now can access the server remotely using `ssh user1@computer_ip`. For security, we can disallow remote logins as the `root` user, by modifying the `/etc/ssh/sshd_config` file:

    sudo nano /etc/ssh/sshd_config
Change the line `#PermitRootLogin yes` to `PermitRootLogin no`, and then restart ssh:

    systemctl restart ssh

<a name="net"></a>
#### Set up networking

Install necessary packages for mounting (Windows) network folders:

    sudo apt-get install samba
    sudo apt-get install smbclient
    sudo apt-get install cifs-utils

Make new local directories to link to network folders:

    sudo mkdir /mnt/server-1
    sudo mkdir /mnt/Flash
    sudo mkdir /mnt/Windows

Since network folders require authentication, create a credentials text file with the following lines:

    username=*******
    password=*******
    domain=audi.server.xyz

Network folders can be mounted using the following commands:

    sudo mount.cifs //MyPC/data/server-1 /mnt/server-1 -o credentials=/path/to/file,uid=user1,gid=user1
    sudo mount.cifs //MyPC/data/Flash /mnt/Flash -o credentials=/path/to/file,uid=user1,gid=user1

To load network folder for the lab on computer startup, add the following line to `/etc/fstab` (Note that permissions are restricted to only the user marked in `uid=` through the use of `dir_mode=0700`:

    //MyPC/data/server-1 /mnt/server-1 cifs credentials=/path/to/file,uid=user1,rw,dir_mode=0700 0 0

Configure for static networking:
- Edit /etc/network/interfaces to set static networking and reboot (in this case note that ens3 is the network device name)
   
 ```bash
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto ens33
iface ens33 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 1.1.1.1 1.0.0.1 192.168.1.100
```
#### Backup using cron:
Edit the cron jobs for the root user, run the following command:
```bash
sudo crontab -e
```

Back up a directory /path/to/source to /path/to/backup using tar at 2:00 AM every day, add the following line to your crontab:
```bash
0 2 * * * tar -czf /path/to/backup/backup_$(date +\%F_\%T).tar.gz -C /path/to/source .
```
Back up /path/to/source to a remote server at 2:00 AM every day, use the following scp method:
```bash
0 2 * * * tar -czf - -C /path/to/source . | ssh user@remote-server.com 'cat > /path/to/remote/backup/backup_$(date +\%F_\%T).tar.gz'.
```

Incremental backups, use rsync, which only copies modified files. Back up files to a remote server:
```bash
0 2 * * * rsync -av --delete /path/to/source/ user@remote-server.com
```

Clean up old backups (e.g., delete backups older than 7 days, run at 3:00 AM every day):
```bash
0 3 * * * find /path/to/backup/ -type f -name "*.tar.gz" -mtime +7 -exec rm {} \;
```
