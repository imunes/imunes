************************************************************************
## IMUNES - Integrated Multiprotocol Network Emulator / Simulator
************************************************************************

### Description
IMUNES GUI is a simple Tcl/Tk based management console, allowing for specification and management of virtual network topologies. The emulation execution engine itself operates within the operating system kernel.

### System requirements (FreeBSD)
-----------------------
**Note: Do not use IMUNES with FreeBSD 14.0, as there is a serious bug with UnionFS. FreeBSD 14.1 fixes this issue.**

#### FreeBSD 13/14
#### Build requirements:
    # pkg install git-lite gmake
#### Required ports:
    # pkg install tcl86 tcllib
#### Also needed for graphical mode:
    # pkg install tk86 ImageMagick7 xterm wireshark socat

### System requirements (Linux)
-----------------------
When IMUNES is used on top of Linux, a 3.10 Linux kernel is the minimum requirement.

Depending on your platform, packages required to IMUNES in graphical mode are:

    # Build requirements:
    make (used for installation)
    git (used for installation)

    # Required packages:
    tcl (version 8.6 or greater)
    tcllib
    Docker (version 1.6 or greater)
    iproute2

    # Also needed for graphical mode:
    tk (version 8.6 or greater)
    wireshark (with GUI)
    ImageMagick
    xterm
    socat

To run IMUNES experiments, you must run the Docker daemon (starting this service depends on your Linux distribution).

Note: on some distributions the netem module `sch_netem` required for link configuration is only available by installing additional kernel packages. Please check the availability of the module:

    # modinfo sch_netem

-----------------------

#### Arch
#### Build requirements:
    # pacman -S git make
#### Required packages:
    # pacman -S tcl docker
    # Package tcllib is available on AUR, e.g.:
    # yay -S tcllib
#### Also needed for graphical mode:
    # pacman -S tk imagemagick wireshark-qt xterm socat

-----------------------

#### Debian 12
#### Build requirements:
    # apt install git make
#### Required packages:
    # apt install docker.io
#### Also needed for graphical mode:
    # apt install imagemagick wireshark socat

-----------------------

#### Ubuntu 22.04/24.04
#### Build requirements:
    # apt install git make
#### Required packages:
    # apt install tcl tcllib docker.io
#### Also needed for graphical mode:
    # apt install tk imagemagick xterm wireshark socat

### Installing IMUNES
-----------------------
Checkout the last fresh IMUNES source through the public github repository:

    # git clone https://github.com/imunes/imunes.git

#### Installing IMUNES to system
To open/edit topologies without the need to run the experiments, install IMUNES on the system by executing (as root):

    # cd imunes
    # make install

Note: check your distribution repository for a pre-packaged version of IMUNES (e.g. `imunes-git` on AUR for Arch Linux).

-----------------------

#### Installing the filesystem for virtual nodes
In order to run IMUNES experiments on your system, you also need to populate the virtual filesystem with predefined and required data. To create this template filesystem, run the following command (as root):

    # imunes -p

Note: internet connection is required.

-----------------------

#### Running IMUNES
If graphical mode is installed, open IMUNES GUI by running:

    # imunes

To execute experiments, run it as root.

To run experiments without graphical mode, run (as root):

    # imunes -b existing_topology.imn

This will create an experiment with a random EID (experiment ID).

To specify a custom EID `my_eid`, run:

    # imunes -b -e my_eid existing_topology.imn

To terminate the experiment with the EID `eid`, run:

    # imunes -b -e eid

### IMUNES wiki
-----------------------

Visit our [wiki](https://github.com/imunes/imunes/wiki) for more:
 - [IMUNES examples](https://github.com/imunes/imunes/wiki#imunes-examples)
 - [Scripting IMUNES experiments](https://github.com/imunes/imunes/wiki#scripting-imunes-experiments)
 - [Troubleshooting](https://github.com/imunes/imunes/wiki#troubleshooting)

For additional information visit our web site:
        http://imunes.net/
