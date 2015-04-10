************************************************************************
IMUNES - an Integrated Multiprotocol Network Emulator / Simulator
************************************************************************

IMUNES GUI is a simple Tcl/Tk based management console, allowing for
specification and management of virtual network topologies. The emulation
execution engine itself operates within the operating system kernel.

System requirements
-------------------

### Operating system

IMUNES works on top of the FreeBSD 8 (or higher) kernel that is
compiled with the VIMAGE option included. A sample kernel kernel
config file is as follows:

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

    # vi /usr/src/sys/amd64/conf/VIMAGE #for 64bit machines
    # vi /usr/src/sys/i386/conf/VIMAGE #for 32bit machines

Then you need to compile and install the kernel and reboot.

    # config VIMAGE
    # cd ../compile/VIMAGE
    # make depend; make
    # make install
    # reboot

### FreeBSD packages

First we need to install the packages needed for IMUNES. To do
this execute the following command (on FreeBSD 10.1):

    # pkg install tk86 ImageMagick tcllib wireshark socat git gmake
    
### Installing IMUNES

Checkout the last fresh IMUNES source through the public github
repository:

    # git clone https://github.com/imunes/imunes.git
    
Now we need to install IMUNES and populate the virtual file system
with predefined and required data. To install imunes on the system
execute (as root):

    # cd imunes
    # gmake install

### Filesystem for virtual nodes

For the topologies to work a template filesystem must be created.
This is done by issuing the following command (as root):

    # imunes -p

The filesystem is by default created in /var/imunes/vroot.

Now the IMUNES GUI can be ran just by typing the imunes command
in the terminal:

    # imunes
    
To execute experiments, run it as root.

For additional information visit our web site:
        http://www.imunes.net/
