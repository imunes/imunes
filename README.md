************************************************************************
## IMUNES - an Integrated Multiprotocol Network Emulator / Simulator
************************************************************************

IMUNES GUI is a simple Tcl/Tk based management console, allowing for
specification and management of virtual network topologies. The emulation
execution engine itself operates within the operating system kernel.

System requirements
-------------------

## Operating system (FreeBSD)

Note: Since FreeBSD 12.0, kernel option VIMAGE is already included in the kernel, so there is no need to recompile the kernel with it.

Note: FreeBSD 12.0 RELEASE version had some instabilities, so we recommend installing IMUNES on FreeBSD-12.0-STABLE-20190418-r346338 or newer.

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
    #options IPSEC_NAT_T not needed for FreeBSD versions 11.2+

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

    # pkg install tk86 ImageMagick7 tcllib wireshark socat git gmake

### Support for images and icons .SVG to IMUNES

https://wiki.tcl-lang.org/page/tksvg

    # cd  /root
    # git clone https://github.com/oehhar/tksvg.git
    # cd tksvg
    # ./configure --with-tcl=/usr/local/lib/tcl8.6 --with-tk=/usr/local/lib/tk8.6 --exec-prefix=/usr/local/lib/tksvg0.13
    # make
    # make install

    NOTE: tksvg0.13 (comes out of the tksvgs package version, if you change the version you must change the line at the end, 
      depending on the version)

    The compilation creates the following tree of directories and files.
###  
    :::text
    Directory tree inside /usr/local/lib/tksvg0.13
    
    tksvg0.13
    │
    ├── bin
    │     
    ├── lib
    │   │
    │   ├── tksvg0.13
    │       │
    │       ├── libtksvg0.13.so
    │       └── pkgIndex.tcl
    ├── libtksvg0.13.so
    └── pkgIndex.tcl
    
    For some unknown reason the last two lines are not created in some compilations so the tksvg0.13 library is not created. 
    the tksvg0.13 library does not work.
    
### To fix the problem run the following commands:
    
    # cd /usr/local/lib/tksvg0.13/lib/tksvg0.13/
    # cp -rf libtksvg0.13.so ../../
    # cp -rf pkgIndex.tcl ../../

This solves the problem, when the correct directory and file structure is not created during compilation.

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
    Docker (version 1.6 or greater)
    OpenvSwitch
    nsenter (part of the util-linux package since version 2.23 and later)
    xterm
    make (used for installation)
    
To run IMUNES experiments, you must run the Docker daemon and start the ovs-vswitchd service (starting these services depends on your Linux distribution).

Note: on some distributions the netem module `sch_netem` required for link configuration is only available by installing additional kernel packages. Please check the availability of the module:

    # modinfo sch_netem
    
#### Arch
    # pacman -S tk tcllib wireshark-gtk imagemagick docker \
        make openvswitch xterm

#### Debian 9 and testing(buster)
    (https://docs.docker.com/install/linux/docker-ce/debian/)[https://docs.docker.com/install/linux/docker-ce/debian/]
    # apt-get update
    # apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common
    # curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
    # add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    # apt-get update
    # apt-get install docker-ce openvswitch-switch xterm wireshark \
        imagemagick tk tcllib util-linux make

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

#### Ubuntu 18.04 LTS (Mint 19, 19.1)
    # apt install openvswitch-switch docker.io xterm wireshark \
        make imagemagick tk tcllib util-linux

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

### IMUNES wiki

Visit our [wiki](https://github.com/imunes/imunes/wiki) for more:
 - [IMUNES examples](https://github.com/imunes/imunes/wiki#imunes-examples)
 - [Scripting IMUNES experiments](https://github.com/imunes/imunes/wiki#scripting-imunes-experiments)
 - [Troubleshooting](https://github.com/imunes/imunes/wiki#troubleshooting)

For additional information visit our web site:
        http://imunes.net/
