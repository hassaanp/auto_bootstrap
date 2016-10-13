#!/bin/bash
git_username=hassaanp
git_email="hassaanp@plumgrid.com"

function setup_git() {
  git config --global user.name "$git_username"
  git config --global user.email $git_email
  git config --global push.default upstream
}

function print_stack() {
  local i
  local stack_size=${#FUNCNAME[@]}
  echo "Stack trace (most recent call first):"
  # to avoid noise we start with 1, to skip the current function
  for (( i=1; i<$stack_size ; i++ )); do
    local func="${FUNCNAME[$i]}"
    [[ -z "$func" ]] && func='MAIN'
    local line="${BASH_LINENO[(( i - 1 ))]}"
    local src="${BASH_SOURCE[$i]}"
    [[ -z "$src" ]] && src='UNKNOWN'

    echo "  $i: File '$src', line $line, function '$func'"
  done
}

function tryexec() {
  "$@"
  retval=$?
  [[ $retval -eq 0 ]] && return 0

  echo 'A command has failed:'
  echo "  $@"
  echo "Value returned: ${retval}"
  print_stack
  exit $retval
}

function add_pg_sources() {
  target_file=$1
  read -d '' pg_source << EOF
deb http://192.168.10.167/archive-ubuntu/ubuntu/ precise main restricted universe multiverse
deb-src http://192.168.10.167/archive-ubuntu/ubuntu/ precise main restricted universe multiverse
deb http://192.168.10.167/archive-ubuntu/ubuntu/ precise-security main restricted universe multiverse
deb-src http://192.168.10.167/archive-ubuntu/ubuntu/ precise-security main restricted universe multiverse
deb http://192.168.10.167/archive-ubuntu/ubuntu/ precise-updates main restricted universe multiverse
deb-src http://192.168.10.167/archive-ubuntu/ubuntu/ precise-updates main restricted universe multiverse
deb http://192.168.10.167/archive-ubuntu/ubuntu/ precise-backports main restricted universe multiverse
deb-src http://192.168.10.167/archive-ubuntu/ubuntu/ precise-backports main restricted universe multiverse

deb http://192.168.10.167/plumgrid plumgrid unstable 
deb http://192.168.10.167/plumgrid-images plumgrid unstable
deb http://192.168.10.167/plumgrid-extra plumgrid unstable 
EOF
  echo "$pg_source" > /tmp/pg_sources
  sudo mv /tmp/pg_sources $1
}

function build_tools() {
  export LC_ALL=C
  echo "======Building Tools======"
  echo "Adding gerrit/jira to hosts file"
  tryexec sudo bash -c "cat >> /etc/hosts <<DELIM__
192.168.10.11   jira.plumgrid.com
192.168.10.77   gerrit.plumgrid.com gerrit
10.8.0.1        plumgrid-vpn1-internal
DELIM__"
  echo "Pointing sources.list to PLUMgrid repo"
  tryexec add_pg_sources "/etc/apt/sources.list.d/plumgrid.list"
  tryexec sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 554E46B2
  tryexec sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 40EADBBF
  echo "Running apt-get update"
  tryexec sudo apt-get update
  echo "Installing Packages: apache2=2.2.22-1ubuntu1.6 openssh-server=1:7.2p2-4ubuntu2.1 make=4.1-6 git g++=4:5.3.1-1ubuntu1 plumgrid-install-tools curl=7.47.0-1ubuntu2.1"
  tryexec sudo apt-get install apache2=2.2.22-1ubuntu1.6 openssh-server=1:7.2p2-4ubuntu2.1 make=4.1-6 git g++=4:5.3.1-1ubuntu1 plumgrid-install-tools curl=7.47.0-1ubuntu2.1 libfl-dev=2.5.35-10ubuntu3 libbison-dev=1:2.5.dfsg-2.1 mercurial-common=2.0.2-1ubuntu1 expect -y
  tryexec setup_git
  echo "Cloning Tools"
  /usr/bin/expect <<EOD
spawn git clone ssh://hassaanp@gerrit.plumgrid.com:29418/tools.git $HOME/work/tools
expect "Are you sure you want to continue connecting (yes/no)? "
send "yes\n" 
EOD
  tryexec git clone ssh://$git_username@gerrit.plumgrid.com:29418/tools.git ~/work/tools
  echo "Installing Packages: build-essential libboost-program-options1.48-dev libboost-regex1.48-dev libboost-system1.48-dev libboost-thread1.48-dev libboost-random1.48-dev libev4 libprotobuf-lite7 libdom4j-java libtk-img openssl liblua5.1-md5-dev plumgrid-zmq4 plumgrid-benchmark plumgrid-coumap libv8-dev=3.7.12.22-3 bison cpanminus curl git flex mercurial protobuf-compiler pax-utils puppet puppet-common facter cgroup-bin rubygems bridge-utils httperf libgtest-dev"
  tryexec  sudo apt-get install build-essential=12.1ubuntu2 libboost-program-options1.48-dev=1.48.0-3 libboost-regex1.48-dev=1.48.0-3 libboost-system1.48-dev=1.48.0-3 libboost-thread1.48-dev=1.48.0-3 libboost-random1.48-dev=1.48.0-3 libev4 libprotobuf-lite7 libdom4j-java=1.6.1+dfsg.2-5 libtk-img=1:1.3-release-11 openssl=1.0.2g-1ubuntu4.5 liblua5.1-md5-dev plumgrid-zmq4 plumgrid-benchmark plumgrid-coumap libv8-dev=3.7.12.22-3 bison=1:2.5.dfsg-2.1 cpanminus=1.5007-1 flex=2.5.35-10ubuntu3 mercurial=2.0.2-1ubuntu1 protobuf-compiler=2.4.1-1ubuntu2 pax-utils=0.2.3-2build2 puppet puppet-common facter cgroup-bin=0.37.1-1ubuntu10.1 rubygems=1.8.15-1ubuntu0.1 bridge-utils=1.5-2ubuntu7 httperf=0.9.0-2build1 libgtest-dev=1.6.0-1ubuntu4 libprotobuf-dev=2.4.1-1ubuntu2 -y
  tryexec sudo gem install --no-rdoc --no-ri sass
  echo "Purging: apport-symptoms python-apport"
  tryexec sudo apt-get purge -y apport apport-symptoms python-apport
  tryexec sysctl -q -p
  echo "Installing Packages: python-pcapy libpcap0.8 libprotobuf7 python-pip libc-ares2 libc6 libcairo2 libcap2 libgcrypt11 libgdk-pixbuf2.0-0 libgeoip1 libglib2.0-0 libgnutls26 libgtk2.0-0 libk5crypto3 libkrb5-3 liblua5.1-0 libpcap0.8 libportaudio2 libsmi2ldbl zlib1g"
  tryexec sudo apt-get install -y python-pcapy=0.10.8-1build1 libpcap0.8=1.7.4-2 libprotobuf7=2.4.1-1ubuntu2 python-pip=1.0-1build1 libc-ares2=1.7.5-1 libc6=2.23-0ubuntu3 libcairo2=1.14.6-1 libcap2=1:2.24-12 libgcrypt11=1.5.0-3ubuntu0.2 libgdk-pixbuf2.0-0=2.32.2-1ubuntu1.2 libgeoip1=1.6.9-1 libglib2.0-0=2.48.1-1~ubuntu16.04.1 libgnutls26=2.12.14-5ubuntu3.8 libgtk2.0-0=2.24.30-1ubuntu1 libk5crypto3=1.13.2+dfsg-5 libkrb5-3=1.13.2+dfsg-5 liblua5.1-0=5.1.5-8ubuntu1 libpcap0.8=1.7.4-2 libportaudio2=19+svn20140130-1build1 libsmi2ldbl=0.4.8+dfsg2-4build1 zlib1g=1:1.2.8.dfsg-2ubuntu4
  echo "Installing Packages: cmake dkms libcurl4-openssl-dev libyaml-dev libxml2-dev libssl-dev libsqlite3-dev libprotoc-dev libpq-dev libpcre3-dev libmnl-dev libmagic-dev liblua5.1-0-dev libedit-dev liblua5.1-0-dev gcc-4.7 g++-4.7 debhelper libpcap-dev libpango1.0-0 gcc-4.7 g++-4.7 rpm"
  tryexec sudo DEBIAN_FRONTEND=noninteractive apt-get install -y cmake dkms=2.2.0.3-2ubuntu11.2 libcurl4-openssl-dev=7.47.0-1ubuntu2.1 libyaml-dev=0.1.6-3 libxml2-dev=2.9.3+dfsg1-1ubuntu0.1 libssl-dev=1.0.2g-1ubuntu4.5 libsqlite3-dev=3.11.0-1ubuntu1 libprotoc-dev=2.4.1-1ubuntu2 libpq-dev=9.5.4-0ubuntu0.16.04 libpcre3-dev=2:8.38-3.1 libmnl-dev=1.0.3-5 libmagic-dev=1:5.25-2ubuntu1 liblua5.1-0-dev=5.1.5-8ubuntu1 libedit-dev=3.1-20150325-1ubuntu2 liblua5.1-0-dev=5.1.5-8ubuntu1 gcc-4.7=4.7.4-3ubuntu12 g++-4.7=4.7.4-3ubuntu12 debhelper=9.20160115ubuntu3 libpcap-dev=1.7.4-2 libpango1.0-0=1.38.1-1 gcc-4.7=4.7.4-3ubuntu12 g++-4.7=4.7.4-3ubuntu12 rpm=4.12.0.1+dfsg1-3build3
  echo "Adding openjdk repo, running apt-get and installing openjdk-7"
  tryexec sudo add-apt-repository ppa:openjdk-r/ppa -y
  tryexec sudo apt-get update
  tryexec sudo apt-get install -y openjdk-7-jdk
  echo "Installing Packages: libpcap-dev tcl8.5 tk8.5 iovisor-dkms libboost-python1.48-dev postgresql-server-dev-9.1 libprotobuf-java=2.4.1-1ubuntu2 gccgo=4:4.7.0~rc1-1ubuntu5 gcc-multilib=4:4.6.3-1ubuntu5 golang-go=2:1-5 libgd2-xpm librtmp0"
  tryexec sudo apt-get install libpcap-dev tcl8.5 tk8.5 -y
  tryexec sudo apt-get install -y iovisor-dkms libboost-python1.48-dev postgresql-server-dev-9.1 libprotobuf-java=2.4.1-1ubuntu2 gccgo=4:4.7.0~rc1-1ubuntu5 gcc-multilib=4:4.6.3-1ubuntu5 libgd2-xpm librtmp0
  tryexec sudo DEBIAN_FRONTEND=noninteractive apt-get install golang-go=2:1-5 -yq
  echo "Installing PLUMgrid Packages: plumgrid-psutil plumgrid-six plumgrid-requests plumgrid-python-keystoneclient plumgrid-python-novaclient plumgrid-requests plumgrid-netifaces plumgrid-netaddr plumgrid-pyroute2 plumgrid-argcomplete plumgrid-docopt plumgrid-esper plumgrid-gcc plumgrid-jira plumgrid-jshint plumgrid-jsonrpclib plumgrid-nodeapi plumgrid-rpyc plumgrid-sigmund plumgrid-tabulate plumgrid-websocket-client libluajit-5.1-dev"
  tryexec sudo apt-get install -y plumgrid-psutil plumgrid-six plumgrid-requests plumgrid-python-keystoneclient plumgrid-python-novaclient plumgrid-requests plumgrid-netifaces plumgrid-netaddr plumgrid-pyroute2 plumgrid-argcomplete plumgrid-docopt plumgrid-esper plumgrid-gcc plumgrid-jira plumgrid-jshint plumgrid-jsonrpclib plumgrid-nodeapi plumgrid-rpyc plumgrid-sigmund plumgrid-tabulate plumgrid-websocket-client libluajit-5.1-dev
  echo "Preparing /opt/pg directory"
  tryexec sudo mkdir -p /opt/local/bin
  tryexec sudo mkdir -p /opt/pg/{bin,core,debug,lib,echo,share,test,tmp,web}
  tryexec sudo chown -R $USER:$USER /opt/pg
  tryexec sudo chown -R $USER:$USER /opt/local/
  echo "Fixing /home/plumgrid/work/tools/packages/vijava/com/vmware/vim25/ws/WSClient.java"
  tryexec sed -i '128d' ~/work/tools/packages/vijava/com/vmware/vim25/ws/WSClient.java
  tryexec sed -i '127 a + " WSClient.invoke()# SOAP Req Retrying(MAX=5)"' ~/work/tools/packages/vijava/com/vmware/vim25/ws/WSClient.java
  echo "Commenting out CMakeLists.txt in tools folder"
  tryexec sed -i '23,26 s/^/#/' ~/work/tools/CMakeLists.txt
  echo "Creating build folder"
  tryexec mkdir ~/work/tools/build
  pushd ~/work/tools/build/
  echo "Running cmake"
  tryexec cmake ..
  tryexec sudo sh -c "export JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8; make install"
  echo "Installing Tools"
  sudo chown -R $USER:$USER /opt/local/
  sudo chown -R $USER:$USER /opt/local/share/
  sudo chown -R $USER:$USER ~/work/tools/build/
  tryexec make -C packages install
  popd
  pushd ~/work/tools/
  echo "libnet installing"
  tryexec packages/libnet_install
  echo "Installing Packages: ebtables iproute"
  tryexec sudo apt-get install -y ebtables iproute
  popd
  pushd ~/work/tools/packages/
  echo "Installing Packages: pep8_1.2-1_all.deb core_4.4-0ubuntu1_precise_amd64.deb wireshark-common_1.9.0pg1_amd64.deb wireshark_1.9.0pg1_amd64.deb nping_0.6.25-1_amd64.deb quagga_0.99.24.1-2_amd64-plumgrid.deb"
  sudo dpkg -i pep8_1.2-1_all.deb core_4.4-0ubuntu1_precise_amd64.deb wireshark-common_1.9.0pg1_amd64.deb wireshark_1.9.0pg1_amd64.deb nping_0.6.25-1_amd64.deb quagga_0.99.24.1-2_amd64-plumgrid.deb
  tryexec sudo mkdir -p /opt/pg/lib
  tryexec sudo chown $USER:$USER /opt/pg/lib
  echo "Untarring python.core.tar.bz2"
  tryexec tar xvf python.core.tar.bz2  -C /opt/pg/lib
  echo "Running various commands"
  sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.6 40 --slave /usr/bin/g++ g++ /usr/bin/g++-4.6
  sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.7 60 --slave /usr/bin/g++ g++ /usr/bin/g++-4.7
  sudo update-alternatives --set java /usr/lib/jvm/java-7-openjdk-amd64/jre/bin/java
  echo "Copying zPlum.conf to /etc/ld.so.conf.d/"
  tryexec sudo cp zPlum.conf /etc/ld.so.conf.d/
  tryexec sudo ldconfig
  echo "Linking libtcl8.5.so to /usr/lib/libtcl.so"
  tryexec sudo ln -s libtcl8.5.so /usr/lib/libtcl.so
  echo "Adding kernel core pattern to sysctl.conf"
  tryexec sudo sh -c "echo 'kernel.core_pattern = /opt/pg/core/core.%t.%p.%e' >> /etc/sysctl.conf"
  tryexec sudo sysctl kernel.core_pattern='/opt/pg/core/core.%t.%p.%e'
  popd
  echo "Uninstalling gccgo"
  tryexec sudo apt-get remove gccgo-4.7 -y
  tryexec sudo apt-get remove gccgo-6 -y
  echo "Installing gccgo"
  tryexec sudo apt-get install gccgo=4:4.7.0~rc1-1ubuntu5 -y
  echo "Configuring gccgo"
  tryexec sudo chown -R $USER:$USER /usr/lib/go/
  export GOPATH=/usr/lib/go;export PATH=$PATH:$GOPATH/bin
  tryexec /usr/bin/go get -compiler=gccgo -gccgoflags=-I/usr/lib/go/pkg/gccgo github.com/plumgrid/protobuf/{proto,protoc-gen-go}
  tryexec /usr/bin/go install -compiler=gccgo -gccgoflags=-I/usr/lib/go/pkg/gccgo github.com/plumgrid/protobuf/{proto,protoc-gen-go}
  tryexec sudo mkdir -p /usr/lib/go/pkg/gccgo
  tryexec sudo cp -r /usr/lib/go/pkg/gccgo_linux_amd64/github.com/ /usr/lib/go/pkg/gccgo/
  echo "Setting up gtest"
  tryexec sudo rm -rf /tmp/gtest
  tryexec sudo mkdir -p /tmp/gtest
  popd
  pushd /tmp/gtest
  tryexec sudo cmake /usr/src/gtest
  tryexec sudo make
  tryexec sudo mv libgtest* /usr/lib/
  popd
  tryexec sudo rm -rf /tmp/gtest
  echo "Installing virtualenv"
  tryexec sudo pip install virtualenv
  echo "======Tools Built Successfully======"
}

function build_corelib() {
  export LC_ALL=C
  echo "======Building Corelib======"
  echo "Purging python-protobuf libprotobuf-dev"
  tryexec sudo apt-get purge python-protobuf libprotobuf-dev -y
  echo "Installing python-protobuf=2.4.1-1ubuntu2 libprotobuf-dev=2.4.1-1ubuntu2"
  tryexec  sudo apt-get install python-protobuf=2.4.1-1ubuntu2 libprotobuf-dev=2.4.1-1ubuntu2 -y
  echo "Making some modifications using sed to /usr/include/boost/thread/xtime.hpp"
  tryexec sudo sed -i -e 's/TIME_UTC/TIME_UTC_/g' /usr/include/boost/thread/xtime.hpp
  tryexec sudo chown -R $USER:$USER /opt/pg
  echo "Cloning Corelib"
  tryexec git clone ssh://$git_username@gerrit.plumgrid.com:29418/corelib.git ~/work/corelib
  tryexec sed -i -e '/add_definitions(-Werror)/s/^/#/' ~/work/corelib/CMakeLists.txt
  tryexec mkdir cd ~/work/corelib/build
  pushd ~/work/corelib/build
  echo "Installing corelib"
  tryexec cmake ..
  tryexec make -j4 install
  popd
  echo "======Corelib Built Successfully======"
}

function build_alps()  {
  export LC_ALL=C
  echo "Building ALPS"
  tryexec source /opt/pg/env/alps.bashrc
  echo "Installing libnet1-dev apparmor-utils"
  tryexec sudo apt-get install libnet1-dev -y
  tryexec sudo apt-get install apparmor-utils -y
  echo "Cloning alps"
  tryexec git clone ssh://$git_username@gerrit.plumgrid.com:29418/alps.git ~/work/alps
  pushd ~/work/alps
  tryexec sed -i '/pgtop/s/^/#/' ~/work/alps/scripts/CMakeLists.txt
  tryexec scp -p -P 29418 $git_username@gerrit.plumgrid.com:hooks/commit-msg .git/hooks/
  tryexec mkdir build
  pushd ~/work/alps/build/
  echo "Installing alps"
  tryexec cmake ..
  tryexec make -k -j4
  tryexec make install
  sudo ldconfig
  popd
  popd
  echo "======ALPS Built Successfully======"
}

function build_balicek() {
  export LC_ALL=C
  echo "======Building Balicek======"
  tryexec source /opt/pg/env/alps.bashrc
  echo "Cloning Balicek"
  tryexec git clone ssh://$git_username@gerrit.plumgrid.com:29418//balicek.git ~/work/balicek
  pushd ~/work/balicek
  echo "Installing commit hook"
  tryexec scp -p -P 29418 $git_username@gerrit.plumgrid.com:hooks/commit-msg .git/hooks/
  echo "Creating build directory"
  tryexec mkdir build
  pushd ~/work/balicek/build
  echo "Installing balicek"
  tryexec cmake ..
  tryexec make -k -j4
  popd
  popd
  echo "======Balicek Built Successfully======"
}

function build_pgui() {
  echo "Skipping PG_UI because it has issues with 16.04. Please attempt to install at your own leisure."
}

function build_sal() {
  export LC_ALL=C
  echo "======Building SAL======"
  echo "Installing libpcre3-dev"
  tryexec sudo apt-get install libpcre3-dev -y
  echo "Cloning SAL"
  tryexec git clone ssh://$git_username@gerrit.plumgrid.com:29418//sal.git ~/work/sal
  pushd ~/work/sal
  echo "Installing commit hook"
  tryexec scp -p -P 29418 $git_username@gerrit.plumgrid.com:hooks/commit-msg .git/hooks/
  echo "Creating Build directory"
  tryexec mkdir build
  pushd ~/work/sal/build
  echo "Installing SAL"
  tryexec cmake ..
  tryexec make -k -j4
  echo "======SAL Build Successfully======"
}

function build_pkg {
  export LC_ALL=C
  echo "======Building PKG======"
  echo "Installing Packages: python-vm-builder libprotobuf-java=2.4.1-1ubuntu2 libboost-program-options1.48-dev puppet-common"
  tryexec sudo apt-get install python-vm-builder -y
  tryexec sudo apt-get install libprotobuf-java=2.4.1-1ubuntu2 -y
  tryexec sudo apt-get install libboost-program-options1.48-dev -y
  tryexec sudo apt-get install puppet-common -y
  echo "Installing puppet"
  tryexec curl -O https://apt.puppetlabs.com/puppetlabs-release-precise.deb && sudo dpkg -i puppetlabs-release-precise.deb # dpkg >= 1.17.7 # curl -o- https://apt.puppetlabs.com/puppetlabs-release-precise.deb | sudo dpkg --install -
  echo "Installing and configuring Selenium"
  tryexec wget -P /tmp http://192.168.10.167/tests/unstable/selenium-java-2.39.0/selenium-java-2.39.0.zip
  JAVA_DIR_FOR_SELENIUM='/opt/local/share/java/'
  tryexec unzip -o /tmp/selenium-java-2.39.0.zip -d /tmp/
  tryexec sudo mkdir -p "${JAVA_DIR_FOR_SELENIUM}"
  tryexec sudo cp /tmp/selenium-2.39.0/libs/* "${JAVA_DIR_FOR_SELENIUM}"
  tryexec sudo cp /tmp/selenium-2.39.0/libs/* "${JAVA_DIR_FOR_SELENIUM}"
  tryexec sudo cp /tmp/selenium-2.39.0/selenium-java-2.39.0.jar "${JAVA_DIR_FOR_SELENIUM}"
  tryexec sudo cp /tmp/selenium-2.39.0/selenium-java-2.39.0.jar "${JAVA_DIR_FOR_SELENIUM}"
  tryexec rm -rf /tmp/selenium-2.39.0
  echo "Running apt-get update"
  tryexec sudo apt-get update
  tryexec sudo apt-get install puppet -y
  echo "Cloning PKG"
  git clone ssh://$git_username@gerrit.plumgrid.com:29418//pkg.git ~/work/pkg
  pushd ~/work/pkg
  echo "Installing commit hook"
  tryexec scp -p -P 29418 $git_username@gerrit.plumgrid.com:hooks/commit-msg .git/hooks/ 
  tryexec mkdir build
  echo "Installing PKG"
  pushd ~/work/pkg/build
  tryexec cmake ..
  tryexec make -k -j4
  popd
  popd
  echo "======PKG Built Successfully======"
}

# Running the Bootstrap:
echo ">>>>>>>>>>Initializing Bootstrap<<<<<<<<<<"
build_tools
build_corelib
build_alps
build_balicek
build_pgui
build_sal
build_pkg
echo ">>>>>>>>>>Bootstrap Done<<<<<<<<<<"
