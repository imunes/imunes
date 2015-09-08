************************************************************************
IMUNES - an Integrated Multiprotocol Network Emulator / Simulator
************************************************************************

IMUNES GUI is a simple Tcl/Tk based management console, allowing for
specification and management of virtual network topologies. The emulation
execution engine itself operates within the operating system kernel.

System requirements
-------------------

## Operating system (FreeBSD)

When IMUNES is used on top of FreeBSD 8 (or higher) it requires a kernel
that is compiled with the VIMAGE option included. A sample kernel config file
is as follows:

    include GENERIC
    nooptions FLOWTABLE
    options VIMAGE
    options VNET_DEBUG
    options KDB
    options DDB

    options IPSEC
    device  crypto
    options IPSEC_DEBUG
    options IPSEC_NAT_T

To compile the VIMAGE enabled kernel you must have a copy of the
FreeBSD kernel and create the config file with the above mentioned
lines.
    
    # cd /usr/src/sys/amd64/conf/ #for 64bit machines
    # cd /usr/src/sys/i386/conf/  #for 32bit machines
    # vi VIMAGE

Then you need to compile and install the kernel and reboot.

    # config VIMAGE
    # cd ../compile/VIMAGE
    
    ### standard compilation (single thread)
    # make depend && make
    ### concurrent compliation (e.g. 4 threads)
    # make -j4 depend && make -j4
    
    # make install
    # reboot
    
### FreeBSD packages

First we need to install the packages required for IMUNES. To do
this execute the following command (on FreeBSD 9.3 and higher):

    # pkg install tk86 ImageMagick tcllib wireshark socat git gmake

## Operating system (Linux)

When IMUNES is used on top of Linux a 3.10 Linux kernel is the
minimum requirement.

### Linux packages

First we need to install the packages required for IMUNES:

    tcl (version 8.6 or greater)
    tk (version 8.6 or greater)
    tcllib
    wireshark (with GUI)
    ImageMagick
    Docker (version 1.4 or greater)
    OpenvSwitch
    nsenter (part of the util-linux package since version 2.23 and later)
    xterm
    make (used for installation)

Note: on some distributions the netem module `sch_netem` required for link configuration is only available by installing additional kernel packages. Please check the availability of the module:

    # modinfo sch_netem
    
#### Arch
    # pacman -S tk tcllib wireshark-gtk imagemagick docker \
        make openvswitch xterm

#### Debian testing
    # apt-get install openvswitch-switch docker.io xterm wireshark \
        ImageMagick tk tcllib util-linux make

#### Debian 8
    ### add jessie-backports to your sources.list and update
    # echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list
    # apt-get update
    
    ### install packages
    # apt-get install openvswitch-switch docker.io xterm wireshark \
        ImageMagick tcl tcllib tk util-linux make

#### Fedora 22
    # dnf install openvswitch docker-io xterm wireshark-gnome \
        ImageMagick tcl tcllib tk kernel-modules-extra util-linux
        
    ### add /usr/local/bin to root PATH variable to execute imunes as root
    # echo 'PATH=$PATH:/usr/local/bin' >> /root/.bashrc
    
    ### add /usr/local/bin to sudo secure_path for executing sudo imunes
    # visudo
    Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

#### Ubuntu 15.04
    # apt-get install openvswitch-switch docker.io xterm wireshark \
        make ImageMagick tk tcllib user-mode-linux util-linux
        
#### Ubuntu 14.04 LTS
    ### install needed packages
    # apt-get install openvswitch-switch xterm wireshark make \
        ImageMagick tk tcllib user-mode-linux util-linux
        
    ### install new version of docker and start it
    # wget -qO- https://get.docker.com/ | sh
    # service docker start
    
    ### fetch remote nsenter which is not part of util-linux in ubuntu 14.04
    # sudo docker run -v /usr/local/bin:/target jpetazzo/nsenter
    
#### OpenSUSE 13.2
    ### add repo with openvswitch
    # zypper addrepo http://download.opensuse.org/repositories/network/openSUSE_13.2/network.repo
    # zypper refresh
    
    ### install packages
    # zypper install openvswitch-switch xterm wireshark docker \
        make ImageMagick tk tcllib uml-utilities util-linux
        
    ### add /usr/local/bin to sudo secure_path for executing sudo imunes
    # visudo
    Defaults secure_path="/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin"

#### Performance

For best performance please run Docker with either Aufs or Overlay storage
driver. Depending on your kernel version and distribution, Docker will
automatically select its storage driver based on what is available and what
the particular default setup for your distribution is. Aufs is not part of
vanilla kernel but some distributions package it in their modified kernel and
Overlay is only available from kernel version 3.18. Worst case scenario:
Docker will use the *extremely* slow devicemapper available everywhere.
Please view either Docker or distro docs on how to set this up for your
particular Linux distribution.

##### Enabling overlayfs (kernel 3.18 and higher)
    Debian testing, Ubuntu 14.04 LTS, Ubuntu 15.04:
    # echo 'DOCKER_OPTS="-s overlay"' >> /etc/default/docker
    # service docker restart
    
    Fedora 22
    # echo 'DOCKER_STORAGE_OPTIONS="-s overlay"' >> /etc/sysconfig/docker-storage
    # systemctl restart docker
    
    Arch:
    # cp /usr/lib/systemd/system/docker.service /etc/systemd/system/docker.service
    ### add overlay to ExecStart
    ExecStart=/usr/bin/docker daemon -s overlay -H fd://
    ### reload systemd files and restart docker.service
    # systemctl daemon-reload
    # systemctl restart docker
    
    
    Check status with docker info:
    # docker info | grep Storage
    Storage Driver: overlay

### Installing IMUNES

Checkout the last fresh IMUNES source through the public github
repository:

    # git clone https://github.com/imunes/imunes.git

Now we need to install IMUNES and populate the virtual file system
with predefined and required data. To install imunes on the system
execute (as root):

    # cd imunes
    # make install

### Filesystem for virtual nodes

For the topologies to work a template filesystem must be created.
This is done by issuing the following command (as root):

    # imunes -p

Now the IMUNES GUI can be ran just by typing the imunes command
in the terminal:

    # imunes

To execute experiments, run it as root.

For additional information visit our web site:
        http://imunes.net/
