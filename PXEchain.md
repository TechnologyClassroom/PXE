# Setting up two or more PXE servers on the same network: WDS and GNU/Linux PXE Server

Michael McMahon

Rewrite/update based on Eric Gray's 2011 article http://www.vcritical.com/2011/06/peaceful-coexistence-wds-and-linux-pxe-servers/

There are many guides on setting up a Windows Deployment Server (WDS) and GNU/Linux PXE servers.  I will not go into the specifics of setting up a general PXE server.  Setting up a WDS server or a GNU/Linux PXE server is simple by following guides availabe online, but there are very few articles about configuring multiple PXE servers on the same network using PXE chain.

Scenario: My organization has a WDS server configured on our network.  We use GNU/Linux regularly and want to use a GNU/Linux PXE server.  Our options are creating a new network with new cable drops or use the prexisting network.  Using the preexisting network would be easier and cheaper.  We want to make minimal changes to the WDS server so turning off the DNS and DHCP servers and using a GNU/Linux DHCP server that points to the WDS server is not an option.

Do not run two DHCP servers on the same network.

Configure and test this entire process in a test environment before implementing this on a production environment.

Requirements:

* A working WDS server with DHCP and DNS configured.  I used Windows Server 2012 R2.  This needs to be tested with PXE booting before starting.
* Another server to configure as a GNU/Linux PXE server.  I am using CentOS 7 Minimal.
* A third machine that can boot into PXE
* A switch
* Network cables to connect the four boxes

# [Configuring the WDS server with syslinux](#configuring-the-wds-server-with-syslinux)

- <a href="https://www.kernel.org/pub/linux/utils/boot/syslinux/6.xx/syslinux-6.03.zip">Download syslinux 6.03 from the official source</a> and extract these eight files to C:\RemoteInstall\Boot\x64\ your tftp location without their folder structure:

```
/bios/com32/chain/chain.c32
/bios/com32/elflink/ldlinux/ldlinux.c32
/bios/com32/lib/libcom32.c32
/bios/com32/menu/menu.c32
/bios/com32/menu/vesamenu.c32
/bios/com32/modules/pxechn.c32
/bios/com32/libutil/libutil.c32
/bios/core/pxelinux.0
```

The syslinux archive has many files, but we only need these eight files for legacy boot options.

- Rename or copy two files in the C:\RemoteInstall\Boot\x64\ folder.

Rename ```abortpxe.com``` to ```abortpxe.0```.

Rename ```pxeboot.com``` to ```pxeboot.0```.

This can be accomplished with Explorer or with the command prompt.  Right click on the Windows icon in the bottom right and click on the ```Command Prompt (Admin)``` option.  Type in these two commands:

```
ren C:\RemoteInstall\Boot\x64\pxeboot.com C:\RemoteInstall\Boot\x64\pxeboot.0
ren C:\RemoteInstall\Boot\x64\abortpxe.com C:\RemoteInstall\Boot\x64\abortpxe.0
```

The folder should look like this:

![Screenshot](https://github.com/TechnologyClassroom/SetupNotes/blob/master/Images/PXE1.png?raw=true "Screenshot")

- Create a new folder C:\RemoteInstall\Boot\x64\pxelinux.cfg and make a new file in that folder called default.

- Change the contents of the C:\RemoteInstall\Boot\x64\pxelinux.cfg\default file.

```
DEFAULT menu.c32
MENU TITLE WDS PXE Server
PROMPT 0
TIMEOUT 100 # 10 seconds
 
LABEL wds
  MENU DEFAULT
  MENU LABEL ^Windows Deployment Services (WDS)
  KERNEL pxeboot.0
 
LABEL gnulinuxpxe
  MENU LABEL GNU/^Linux PXE Server
  KERNEL pxechn.c32
  APPEND 192.168.1.15::pxelinux.0

LABEL abort
  MENU LABEL ^Abort PXE
  Kernel abortpxe.0

LABEL local
  MENU LABEL Boot from ^Local Computer
  LOCALBOOT 0
```

![Screenshot](https://github.com/TechnologyClassroom/SetupNotes/blob/master/Images/PXE2.png?raw=true "Screenshot")

The default first choice continues booting the WDS server as usual.  The second choice chains into a second PXE server.  The third choice exits PXE and boots with the next available boot option according to your boot order.  The fourth choice attempts to boot from the local disk.

```menu.c32``` can be changed to ```vesamenu.c32``` for a better look, but compatibility may decrease.

- Change 192.168.1.15 to an available IP address outside of your DHCP server's scope.  Assign your GNU/Linux PXE server a static IP that matches.

- Change the PXE settings to boot from pxelinux.0

Right click on the Windows icon in the bottom right and click on the ```Command Prompt (Admin)``` option.

Type in these two commands:

```
wdsutil /set-server /bootprogram:boot\x64\pxelinux.0 /architecture:x64
wdsutil /set-server /N12bootprogram:boot\x64\pxelinux.0 /architecture:x64
```

![Screenshot](https://github.com/TechnologyClassroom/SetupNotes/blob/master/Images/PXE3.png?raw=true "Screenshot")

If you will be using 32 bit machines, double the above steps for the \x86\ folder and run these commands:

```
wdsutil /set-server /bootprogram:boot\x86\pxelinux.0 /architecture:x86
wdsutil /set-server /N12bootprogram:boot\x86\pxelinux.0 /architecture:x86
```

This changes the default boot option from ```pxeboot.com``` to ```pxelinux.0``` which routes to our new menu.

- If everything is configured correctly, the client should be able to PXE into the WDS and see the new menu.  All options except for the second option should work at this time.

# [Configuring a CentOS 7 PXE server without DHCP or DNS](#configuring-a-centos-7-pxe-server-without-dhcp-or-dns)

This portion is modified from Matei Cezar's article at https://www.tecmint.com/install-pxe-network-boot-server-in-centos-7/

- Install a CentOS 7 Minimal install.
- Login as root.
- Update the system.

```
yum update -y
```

- Configure your network with the static IP that you used before and the same gateway as the WDS.

```
nmtui
```

- Install tftp and ftp and extra software

```
yum groups install -y Development\ Tools
yum install -y tftp
yum install -y tftp-server
yum install -y xinetd
yum install -y vsftpd
yum install -y wget
yum install -y nano
yum install -y tmux
```

- Enable and start services

```
systemctl enable xinetd tftp vsftpd
systemctl start xinetd tftp vsftpd
```

- Make a new directory for syslinux and change into that directory

```
mkdir syslinux
cd syslinux
```

- Download syslinux

```
wget https://www.kernel.org/pub/linux/utils/boot/syslinux/6.xx/syslinux-6.03.zip
```

- Unzip syslinux

```
unzip syslinux-6.03.zip
```

- Copy the necessary files from syslinux to your tftp directory

```
cp bios/com32/chain/chain.c32 /var/lib/tftpboot/
cp bios/com32/elflink/ldlinux/ldlinux.c32 /var/lib/tftpboot/
cp bios/com32/lib/libcom32.c32 /var/lib/tftpboot/
cp bios/com32/menu/menu.c32 /var/lib/tftpboot/
cp bios/com32/menu/vesamenu.c32 /var/lib/tftpboot/
cp bios/com32/modules/pxechn.c32 /var/lib/tftpboot/
cp bios/com32/libutil/libutil.c32 /var/lib/tftpboot/
cp bios/core/pxelinux.0 /var/lib/tftpboot/
```

- Example of setting up a CentOS 7 minimal setup for PXE booting

```
wget http://mirror.pac-12.org/7/isos/x86_64/CentOS-7-x86_64-Minimal-1611.iso # Download an ISO
mount -o loop CentOS-7-x86_64-Minimal-1611.iso /mnt # Mount the ISO to the /mnt directory
mkdir /var/lib/tftpboot/centos7 # Create a folder in the tftp directory
cp /mnt/images/pxeboot/vmlinuz /var/lib/tftpboot/centos7 # Copy the vmlinuz file to tftp
cp /mnt/images/pxeboot/initrd.img /var/lib/tftpboot/centos7 # Copy the initrd.img file to tftp
mkdir /var/ftp/pub/centos7 # Create a folder in the ftp directory
cp -r /mnt/* /var/ftp/pub/centos7/ # Copy the contents of the entire ISO to the ftp
umount /mnt # Unmount the ISO
chmod -R 755 /var/ftp/pub # Set permissions on all files in the ftp directory
```

- Edit your syslinux config file.

```
mkdir /var/lib/tftpboot/pxelinux.cfg
touch /var/lib/tftpboot/pxelinux.cfg/default
nano /var/lib/tftpboot/pxelinux.cfg/default
```

- Example default file

```
DEFAULT menu.c32
PROMPT 0
TIMEOUT 300
ONTIMEOUT 2
MENU TITLE GNU/Linux PXE Server

LABEL 1
  MENU LABEL Install ^CentOS 7 x64 with Local Repo
  KERNEL centos7/vmlinuz
  APPEND initrd=centos7/initrd.img method=ftp://192.168.1.15/pub/centos7 devfs=nomount

LABEL 2
  MENU LABEL Boot from ^Local Computer
  LOCALBOOT 0

LABEL 99
  MENU LABEL Chain to ^Windows Deployment Server (WDS)
  KERNEL pxechn.c32
  APPEND 192.158.1.2::boot\x64\pxelinux.0 -W
```

```LABEL 99``` chains back to the WDS server.  This also illustrates how to do the opposite configuration.  If you have an environment with a GNU/Linux PXE server that handles DHCP and DNS that needs to chain to a WDS server that does not have DHCP and DNS, change ```pxelinux.0``` to ```pxeboot.com``` or install syslinux on both and use the exact code from above.

- Open ports on the firewall

```
firewall-cmd --add-service=ftp --permanent
firewall-cmd --add-port=69/udp --permanent
firewall-cmd --add-port=4011/udp --permanent
firewall-cmd --reload
```

The ftp files can be viewed from other computers on the network by going to ftp://192.168.1.15/pub with a web browser.  Login is not required to view files.  The default selinux configuration will block other users on the network from adding files through ftp.

- Test client machine should be able to now boot through the WDS server to the GNU/Linux PXE server.  Once you have tested this process and have a good working knowledge of all of the parts, implement this into production to expand the functionality of your servers.

# [Other uses for pxechn.c32](#other-uses-for-pxechn.c32)

Some operating systems may require specific versions of syslinux such as VMware vSphere (ESXi) requiring syslinux 3.86.  pxechn.c32 can be used to switch between versions of syslinux within the same tftp directory.
