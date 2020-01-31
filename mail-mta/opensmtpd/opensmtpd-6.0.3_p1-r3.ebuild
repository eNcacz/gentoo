# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit pam toolchain-funcs systemd

DESCRIPTION="Lightweight but featured SMTP daemon from OpenBSD"
HOMEPAGE="https://www.opensmtpd.org"
SRC_URI="https://www.opensmtpd.org/archives/${P/_}.tar.gz"

LICENSE="ISC BSD BSD-1 BSD-2 BSD-4"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="libressl pam +mta"

DEPEND="
	acct-user/smtpd
	acct-user/smtpq
	!libressl? ( dev-libs/openssl:0= )
	libressl? ( dev-libs/libressl:0= )
	elibc_musl? ( sys-libs/fts-standalone )
	sys-libs/zlib
	pam? ( sys-libs/pam )
	sys-libs/db:=
	dev-libs/libevent
	app-misc/ca-certificates
	net-mail/mailbase
	net-libs/libasr
	!mail-mta/courier
	!mail-mta/esmtp
	!mail-mta/exim
	!mail-mta/mini-qmail
	!mail-mta/msmtp[mta]
	!mail-mta/netqmail
	!mail-mta/nullmailer
	!mail-mta/postfix
	!mail-mta/qmail-ldap
	!mail-mta/sendmail
	!mail-mta/ssmtp[mta]
"
RDEPEND="${DEPEND}"

S=${WORKDIR}/${P/_}
PATCHES=(
	"${FILESDIR}/${P}-fix-crash-on-auth.patch"
	"${FILESDIR}/${P}-openssl_1.1.patch"
	"${FILESDIR}/${P}-security-fixes.patch"
)

src_configure() {
	tc-export AR
	AR="$(which "$AR")" econf \
		--with-table-db \
		--with-user-smtpd=smtpd \
		--with-user-queue=smtpq \
		--with-group-queue=smtpq \
		--with-path-socket=/run \
		--with-path-CAfile=/etc/ssl/certs/ca-certificates.crt \
		--sysconfdir=/etc/opensmtpd \
		$(use_with pam auth-pam)
}

src_install() {
	default
	newinitd "${FILESDIR}"/smtpd.initd smtpd
	systemd_dounit "${FILESDIR}"/smtpd.{service,socket}
	use pam && newpamd "${FILESDIR}"/smtpd.pam smtpd
	dosym smtpctl /usr/sbin/makemap
	dosym smtpctl /usr/sbin/newaliases
	if use mta ; then
		dodir /usr/sbin
		dosym smtpctl /usr/sbin/sendmail
		dosym ../sbin/smtpctl /usr/bin/sendmail
		mkdir -p "${ED}"/usr/$(get_libdir) || die
		ln -s --relative "${ED}"/usr/sbin/smtpctl "${ED}"/usr/$(get_libdir)/sendmail || die
	fi
}