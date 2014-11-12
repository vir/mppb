#!/bin/sh

mkdir -p repository/conf
mkdir -p repository/db
mkdir -p repository/dists
mkdir -p repository/pool
mkdir repository/incoming

cat << "***" > repository/conf/distributions
Codename: lenny
Suite: stable
AlsoAcceptFor: unstable experimental
Version: stable
Origin: ctm.ru
Label: ctm.ru debian repository
Description: ctm.ru debian repository
Architectures: source i386 amd64
Components: main non-free
SignWith: default
DebIndices: Packages Release . .gz .bz2
DscIndices: Sources Release . .gz .bz2
Contents: . .gz .bz2

Codename: squeeze
Suite: testing
AlsoAcceptFor: unstable experimental
Version: testing
Origin: ctm.ru
Label: ctm.ru debian repository
Description: ctm.ru debian repository
Architectures: source i386 amd64
Components: main non-free
SignWith: default
DebIndices: Packages Release . .gz .bz2
DscIndices: Sources Release . .gz .bz2
Contents: . .gz .bz2

Codename: sid
Suite: unstable
AlsoAcceptFor: unstable experimental
Version: unstable
Origin: ctm.ru
Label: ctm.ru debian repository
Description: ctm.ru debian repository
Architectures: source i386 amd64
Components: main non-free
SignWith: default
DebIndices: Packages Release . .gz .bz2
DscIndices: Sources Release . .gz .bz2
Contents: . .gz .bz2

***

cat << "***" > repository/conf/incoming
Name: res_lenny
IncomingDir: /home/deb/pbuilder/stable/result
TempDir: /home/deb/repository/tmp
Default: lenny
Multiple: yes
Allow: stable>lenny
***

cat << "***" > .pbuilderrc
# source: http://habrahabr.ru/blogs/ubuntu/57628/
# and http://frit.su/index.php/Pbuilder

# кодовые названия дистрибутивов Debian
DEBIAN_SUITES=("unstable" "testing" "stable" "sid" "squeeze" "lenny")
# названия дистрибутивов Ubuntu
UBUNTU_SUITES=("jaunty" "intrepid" "hardy" "gutsy")

# адреса зеркал с пакетами
DEBIAN_MIRROR="ftp.uk.debian.org"
UBUNTU_MIRROR="mirrors.kernel.org"

# выбираем дистрибутив для использования
: ${DIST:="$(lsb_release --short --codename)"}
# а также архитектуру
: ${ARCH:="$(dpkg --print-architecture)"}

# компоненты дистрибутива по умолчанию
COMPONENTS="main contrib non-free"

# ну и давайте определим имя, которым мы будем обозначать отдельный образ
NAME="$DIST"
if [ -n "${ARCH}" ]; then
    NAME="$NAME-$ARCH"
    # следующая строчка нужна для того чтобы собирать под разные архитектуры
    DEBOOTSTRAPOPTS=("--arch" "$ARCH" "${DEBOOTSTRAPOPTS[@]}")
fi

# где мы будем создавать, а потом искать файл образа
BASETGZ="/home/deb/pbuilder/$NAME-base.tgz"
DISTRIBUTION="$DIST"
# и куда мы будем класть собранные пакеты
BUILDRESULT="/home/deb/pbuilder/$DIST/result/"
# тут у нас будет лежать кэш слитых из сети пакетов
APTCACHE="/home/deb/pbuilder/$NAME/aptcache/"
# а в это место будет распаковываться образ для сборки
BUILDPLACE="/home/deb/pbuilder/build/"
***

sudo ARCH=i386  DIST=stable   /usr/sbin/pbuilder --create --http-proxy http://192.168.2.57:3128/
sudo ARCH=amd64 DIST=stable   /usr/sbin/pbuilder --create --http-proxy http://192.168.2.57:3128/
sudo ARCH=i386  DIST=testing  /usr/sbin/pbuilder --create --http-proxy http://192.168.2.57:3128/
sudo ARCH=amd64 DIST=testing  /usr/sbin/pbuilder --create --http-proxy http://192.168.2.57:3128/
sudo ARCH=i386  DIST=unstable /usr/sbin/pbuilder --create --http-proxy http://192.168.2.57:3128/
sudo ARCH=amd64 DIST=unstable /usr/sbin/pbuilder --create --http-proxy http://192.168.2.57:3128/


gpg --gen-key

