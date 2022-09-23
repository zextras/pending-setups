targets=(
  "centos"
  "ubuntu"
)
pkgname="pending-setups"
pkgver="0.2.1"
pkgrel="1"
pkgdesc="Keep track of needed setups for Zextras products"
pkgdesclong=(
  "Keep track of needed setups for Zextras products"
)
maintainer="Zextras <packages@zextras.com>"
arch="all"
license=("PROPRIETARY")
section="admin"
priority="optional"
url="https://www.zextras.com/"
depends=(
  "bash"
  "jq"
)

package() {
  cd "${srcdir}"
  install -dm700 "${pkgdir}/etc/zextras/pending-setups.d/"
  install -dm700 "${pkgdir}/etc/zextras/pending-setups.d/done"
  install -Dm555 ../pending-setups.sh \
    "${pkgdir}/usr/bin/pending-setups"
}
