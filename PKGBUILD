# Maintainer  : denis
# Contributor : Denis Salopek <denis dot sale at gmail dot com>

_name=imunes
_branch=master

pkgname=$_name-git
pkgver=v2.1.0.r58.28639cc
pkgrel=1

pkgdesc='Integrated Multiprotocol Network Emulator/Simulator'
url="http://imunes.net/"
arch=('x86_64')
license=('BSD')
install=$pkgname.install

depends=('xterm' 'tk' 'tcllib' 'imagemagick' 'docker' 'openvswitch')
makedepends=('git' 'make')
optdepends=('wireshark-gtk: for pretty pcap viewing')

provides=("$_name")
conflicts=("$_name")
source=("$pkgname::git+http://github.com/imunes/$_name.git")
sha512sums=(SKIP)

pkgver() {
    cd "$srcdir/$pkgname"
    printf "%s" "$(git describe --long | sed 's/\([^-]*-\)g/r\1/;s/-/./g')"
}

package() {
  cd $srcdir/$pkgname

  make install PREFIX=$pkgdir/usr/local
  find . -type f -iname '*' | xargs sed -i'' 's/''$pkgdir''//g'
}
