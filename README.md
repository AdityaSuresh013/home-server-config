# Debian Server Setup

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
