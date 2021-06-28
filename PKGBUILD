targets=(
  "centos"
  "ubuntu"
)
pkgname="pending-setups"
pkgver="0.1.1"
pkgrel="4"
pkgdesc="Keep track of needed setups for zextras products"
pkgdesclong=(
  "Keep track of needed setups for zextras products"
)
maintainer="Zextras <packages@zextras.com>"
arch="amd64"
license=("PROPRIETARY")
section="admin"
priority="optional"
url="https://www.zextras.com/"
depends=(
  "bash"
)

build() {
}

package() {
  cd "${srcdir}"
  install -dm 700 "${pkgdir}/etc/zextras/pending-setups.d/"
  install -dm 700 "${pkgdir}/etc/zextras/pending-setups.d/done"
  install -Dm 555 ../pending-setups.sh "${pkgdir}/usr/bin/pending-setups"
}
