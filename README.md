# Raspberry Pi Media Server

This installation is build on top of [Hypriot OS](https://hypriot.com/) which has Docker pre-installed. Where applicable, it's built with the assumption that Macs will be used to connect/interface with the raspberry pi (e.g. choice of network mount)

The following applications are run using Docker:

- LetsEncrypt
- Plex
- Tautulli


## Flash OS to SD Card

Follow the setup instructions [here](https://blog.hypriot.com/getting-started-with-docker-and-mac-on-the-raspberry-pi/) to flash Hpyriot OS to your sd card

## SSH into Server

First identify the IP address of your own workstation. Type

```bash
$ ipconfig getifaddr en1
192.168.1.100
```

Then replace the IP address in front of the /24 with yours and type

```bash
$ nmap -sP 192.168.1.100/24 | grep black-pearl
```

Finally, ssh into the server

```bash
ssh pirate@192.168.178.10
```

Default password is `hypriot`. **CHANGE IT**. Simply type the following command and you'll be able to change your password

```bash
$ passwd
```

## Create config directories

### Create appdata directory

Create appdata directory

```bash
$ cd /opt
$ sudo mkdir appdata
```

By default it will be owned by the root user.

```bash
HypriotOS/armv7: pirate@black-pearl in /opt
$ ls -l
total 8
drwxr-xr-x 2 root root 4096 Jun  6 01:31 appdata
drwxr-xr-x 5 root root 4096 Apr 28 18:55 vc
```

Change ownership to the pirate user.

```bash
$ sudo chown pirate:pirate appdata/
```

Voila

```bash
$ ls -l
total 8
drwxr-xr-x 2 pirate pirate 4096 Jun  6 01:31 appdata
drwxr-xr-x 5 root   root   4096 Apr 28 18:55 vc
```

### Create application directories

`cd` to `appdata/` directory and make individual application directories

```bash
$ cd appdata/
$ mkdir letsencrypt plex tautulli
```

## Mount A Network Disk

An external drive is necessary to store movies and tv shows for Plex.

Instructions adapted from [this](https://medium.com/@aallan/adding-an-external-disk-to-a-raspberry-pi-and-sharing-it-over-the-network-5b321efce86a) article

### Format the Disk

Go ahead and plug in your external drive, and type the following.

```bash
$ sudo apt-get install dosfstools
```

List all drives

```
$ sudo blkid -o list
device                             fs_type      label         mount point                            UUID
------------------------------------------------------------------------------------------------------------------------------------------
/dev/mmcblk0                                                  (in use)
/dev/mmcblk0p1                     vfat         HypriotOS     /boot                                  7075-EEF7
/dev/mmcblk0p2                     ext4         root          /                                      2a81f25a-2ca2-4520-a1a6-c9dd75527c3c
/dev/sda1                          vfat         EFI           (not mounted)                          67E3-17ED
/dev/sda2                          vfat         MEDIA         (not mounted)                          7935-1A04
```

Format drive (if needed)

```bash
$ sudo mkfs.ext4 /dev/sdaN -n USB
```

Or for cross-platform compatibility

```bash
$ sudo mkfs.fat32 /dev/sdaN -n USB
```

Although be aware that if the disk is already formatted it might automatically be mounted by (more recent) versions of Raspbian, and you might have to unmount it before formatting.

```bash
$ sudo umount /dev/sdaN
```

### Mounting the Disk

```bash
$ sudo mkdir /mnt/usb
$ sudo chown -R pirate:pirate /mnt/usb
```

For FAT32 formatted drives, manually mount with the following command

```bash
$ sudo mount /dev/sdaN /mnt/usb -o uid=pirate,gid=pirate
```

For ext formatted drives, the user and group are determined by the folder permissions so they must be drop from any mount commmands.

```bash
$ sudo mount /dev/sdaN /mnt/usb
```

If you want it to automatically mount on boot you’ll need to append the following to the /etc/fstab file,

```bash
$ sudo nano /etc/fstab
```

Add the following line for FAT32

```
/dev/sdaN /mnt/usb auto defaults,user,nofail,uid=1000,gid=1000 0 2
```

And for ext

```
/dev/sdaN /mnt/usb auto defaults,user,nofail 0 2
```

You can now leave the disk plugged into your Raspberry Pi and it’ll automatically mount when the board is rebooted. However right now the disk isn’t visible from the network, so let’s go ahead and change that.

### Making the Disk Available Using AFS (For Accessing via Macs)

Simply install the Netatalk package on your Raspberry Pi.

```bash
$ sudo apt-get install netatalk
```

Edit the /etc/netatalk/AppleVolumes.default. Add the /mnt/usb disk to the list of exported file systems. The easiest way to do this is just to append it near the bottom after the entry for `~/`.

```bash
$ sudo nano /etc/netatalk/AppleVolumes.default
```

By default all users have access to their home directories.

```bash
~/                      "Home Directory"
/mnt/usb                "Network Disk"
```

If you want to you can also remove the entire for `~/` which will mean that the only disk exported is our external drive. Afterwards go ahead and restart the Netatalk daemon.

```bash
$ sudo /etc/init.d/netatalk restart
```
You should now be exporting the drive via AFS.

### Mounting the Disk from your Mac
Going to your Mac your Raspberry Pi should now show up in the left-hand panel of the Finder. Click on it, and then the ‘Connect As…’ button.


## Clone repository

In your home folder, clone this repository.

```bash
$ git clone https://github.com/austinmcconnell/raspberry-media-server
```

### Docker-compose aliases

Add the following line to `~/.bash_profile`

```
source ~/raspberry-media-server/.alias
```

to use the aliases listed in [this](.alias) file.

## Domain Forwarding

### Forward (sub)domain

If you don't already have a domain name (or have a new one in mind), I recommend [Hover](https://hover.com/nTDq8IDa) for all domain name needs. They offer free privacy on all their domain names which protects your information (name, address, etc)

Access the DNS record of the domain you wish to forward. For Hover, that's Account -> Domains -> (select domain to edit) -> DNS. You'll see something like this.

![](images/domain_add_a_record.jpg)

In my case, I wanted to forward the subdomains `pi.austinmcconnell.me` and `nextcloud.austinmcconnell.me` to my media server, so I added two A records to the list with the hostnames of `pi` and `nextcloud` and the value of my public ip address. If you want your main domain (e.g. `austinmcconnell.me`) to forward to your media sever, then change the values for the A records with Host type `*` and `@` instead.

For help finding your public IP address, [this](https://www.whatismyip.com/) is a helpful website. You'll want the IPv4 address.


### Forward ports from router to Raspberry Pi

This part is highly specific to your individual router. Google around for instructions/tutorials for your specific router's make and model.

You're looking for something like this.

![](images/port_forwarding.png)

Forward both ports `80` and `443` to your Raspberry Pi.

## Set Environment Variables

Create a db.env file in the same directory as your docker-compose.yml file

```bash
$ nano db.env
```

Add the following environment variables

```ini
POSTGRES_USER=nextcloud
POSTGRES_PASSWORD=$replace_me!$
POSTGRES_DB=nextcloud
```

## Start containers
Start all docker containers in the docker compose file.

```bash
$ dc up -d
```

This will take a couple of minutes while docker downloads and extracts all the images and layers.

To view the logs, type

```bash
$ dclogs
```

## Configure Applications

### NGINX Setup

Hard link the nginx-site-confs-default file to the letsencrypt config location

```bash
$ cd /opt/appdata/letsencrypt/nginx/
$ ln ~/raspberry-media-server/nginx-site-confs-default site-confs/default
```

### Plex Setup

TODO: Fill in!

### Tautulli Setup

Go through the welcome screens to configure. You might have to access via your local network (eg. 192.168.1.XXX:8181). Mostly, just enter your plex username and password and pick which plex server you want to track.

#### Enable reverse proxy

Settings -> Web Intervace -> Show Advanced

Set the `HTTP Root` to `/tautulli` and check the boxes for `Enable HTTP Proxy` and `Enable HTTPS`.

Enable the provided tautulli sample conf file.

```bash
$ cd /opt/appdata/letsencrypt/nginx/proxy-confs
$ mv tautulli.subfolder.conf.sample tautulli.subfolder.conf
```

### Nextcloud setup

### Setup reverse proxy

Enable the provided nextcloud sample conf file.

```bash
$ cd /opt/appdata/letsencrypt/nginx/proxy-confs
$ mv nextcoud.subdomain.conf.sample nextcloud.subdomain.conf
```

Edit the file and change the domain to listen on from

```ini
server_name nextcloud.*;
```

to

```ini
server_name nextcloud.austinmcconnell.me;
```

Also, I had to change the proxy_max_temp_file_size to 1024m.

From

```ini
proxy_max_temp_file_size 2048m;
```

to

```ini
proxy_max_temp_file_size 1024m;
```

#### Edit nextcloud config.php

Edit the nextcloud config file at `/opt/appdata/nextcloud/www/nextcloud/config/config.php`.

Add this line to the trusted_domains array

```
    1 => 'nextcloud.austinmcconnell.me',
```

Add the following lines to the top-level config array

```ini
'overwrite.cli.url' => 'https://nextcloud.austinmcconnell.me',
'overwritehost' => 'nextcloud.austinmcconnell.me',
'overwriteprotocol' => 'https',
```

#### Security check

To check the security of your private nextcloud server, visit [scan.nextcloud.com](scan.nextcloud.com).
