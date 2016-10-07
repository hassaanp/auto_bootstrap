#!/bin/bash
echo "Please enter your git username: "
read git_username
echo "You entered: $git_username"
echo "Please enter your pg email: "
read git_email
echo "You entered: $git_email"

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
  echo "======Building Tools======"
  echo "Pointing sources.list to PLUMgrid repo"
  if [ -f "/etc/apt/sources.list.backup" ]
  then
    echo "sources.backup exists... skipping backup creation"
  else
    tryexec sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
  fi
  tryexec add_pg_sources "/etc/apt/sources.list"
  tryexec sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 554E46B2
  tryexec sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 40EADBBF
  echo "Running apt-get update"
  tryexec sudo apt-get update
  echo "Installing Packages: apache2 openssh-server make git g++ plumgrid-install-tools curl"
  tryexec sudo apt-get install apache2 openssh-server make git g++ plumgrid-install-tools curl -y
  tryexec setup_git
  echo "Cloning Tools"
  tryexec git clone ssh://$git_username@gerrit.plumgrid.com:29418/tools.git ~/work/tools
  echo "Installing Packages: build-essential libboost-program-options1.48-dev libboost-regex1.48-dev libboost-system1.48-dev libboost-thread1.48-dev libboost-random1.48-dev libev4 libprotobuf-lite7 libdom4j-java libtk-img openssl liblua5.1-md5-dev plumgrid-zmq4 plumgrid-benchmark plumgrid-coumap libv8-dev=3.7.12.22-3 bison cpanminus curl git flex mercurial protobuf-compiler pax-utils puppet puppet-common facter cgroup-bin rubygems bridge-utils httperf libgtest-dev"
  tryexec  sudo apt-get install build-essential libboost-program-options1.48-dev libboost-regex1.48-dev libboost-system1.48-dev libboost-thread1.48-dev libboost-random1.48-dev libev4 libprotobuf-lite7 libdom4j-java libtk-img openssl liblua5.1-md5-dev plumgrid-zmq4 plumgrid-benchmark plumgrid-coumap libv8-dev=3.7.12.22-3 bison cpanminus curl git flex mercurial protobuf-compiler pax-utils puppet puppet-common facter cgroup-bin rubygems bridge-utils httperf libgtest-dev -y
  tryexec sudo gem install --no-rdoc --no-ri sass
  echo "Purging: apport-symptoms python-apport"
  tryexec sudo apt-get purge -y apport apport-symptoms python-apport
  tryexec sysctl -q -p
  echo "Installing Packages: python-pcapy libpcap0.8 libprotobuf7 python-pip libc-ares2 libc6 libcairo2 libcap2 libgcrypt11 libgdk-pixbuf2.0-0 libgeoip1 libglib2.0-0 libgnutls26 libgtk2.0-0 libk5crypto3 libkrb5-3 liblua5.1-0 libpcap0.8 libportaudio2 libsmi2ldbl zlib1g"
  tryexec sudo apt-get install -y python-pcapy libpcap0.8 libprotobuf7 python-pip libc-ares2 libc6 libcairo2 libcap2 libgcrypt11 libgdk-pixbuf2.0-0 libgeoip1 libglib2.0-0 libgnutls26 libgtk2.0-0 libk5crypto3 libkrb5-3 liblua5.1-0 libpcap0.8 libportaudio2 libsmi2ldbl zlib1g
  echo "Reverting sources.list to Xenial"
  tryexec sudo mv /etc/apt/sources.list.backup /etc/apt/sources.list
  echo "Running apt-get update"
  tryexec sudo apt-get update
  echo "Installing Packages: cmake dkms libcurl4-openssl-dev libyaml-dev libxml2-dev libssl-dev libsqlite3-dev libprotoc-dev libpq-dev libpcre3-dev libmnl-dev libmagic-dev liblua5.1-0-dev libedit-dev liblua5.1-0-dev gcc-4.7 g++-4.7 debhelper libpcap-dev libpango1.0-0 gcc-4.7 g++-4.7 rpm"
  tryexec sudo apt-get install -y cmake dkms libcurl4-openssl-dev libyaml-dev libxml2-dev libssl-dev libsqlite3-dev libprotoc-dev libpq-dev libpcre3-dev libmnl-dev libmagic-dev liblua5.1-0-dev libedit-dev liblua5.1-0-dev gcc-4.7 g++-4.7 debhelper libpcap-dev libpango1.0-0 gcc-4.7 g++-4.7 rpm
  echo "Adding openjdk repo, running apt-get and installing openjdk-7"
  tryexec sudo add-apt-repository ppa:openjdk-r/ppa -y
  tryexec sudo apt-get update
  tryexec sudo apt-get install -y openjdk-7-jdk
  echo "Adding PG sources to plumgrid.list"
  tryexec add_pg_sources "/etc/apt/sources.list.d/plumgrid.list"
  echo "Running apt-get update"
  tryexec sudo apt-get update
  echo "Installing Packages: libpcap-dev tcl8.5 tk8.5 iovisor-dkms libboost-python1.48-dev postgresql-server-dev-9.1 libprotobuf-java=2.4.1-1ubuntu2 gccgo=4:4.7.0~rc1-1ubuntu5 gcc-multilib=4:4.6.3-1ubuntu5 golang-go=2:1-5 libgd2-xpm librtmp0"
  tryexec sudo apt-get install libpcap-dev tcl8.5 tk8.5 -y
  tryexec sudo apt-get install -y iovisor-dkms libboost-python1.48-dev postgresql-server-dev-9.1 libprotobuf-java=2.4.1-1ubuntu2 gccgo=4:4.7.0~rc1-1ubuntu5 gcc-multilib=4:4.6.3-1ubuntu5 golang-go=2:1-5 libgd2-xpm librtmp0
  echo "Installing PLUMgrid Packages: plumgrid-psutil plumgrid-six plumgrid-requests plumgrid-python-keystoneclient plumgrid-python-novaclient plumgrid-requests plumgrid-netifaces plumgrid-netaddr plumgrid-pyroute2 plumgrid-argcomplete plumgrid-docopt plumgrid-esper plumgrid-gcc plumgrid-jira plumgrid-jshint plumgrid-jsonrpclib plumgrid-nodeapi plumgrid-rpyc plumgrid-sigmund plumgrid-tabulate plumgrid-websocket-client libluajit-5.1-dev"
  tryexec sudo apt-get install -y plumgrid-psutil plumgrid-six plumgrid-requests plumgrid-python-keystoneclient plumgrid-python-novaclient plumgrid-requests plumgrid-netifaces plumgrid-netaddr plumgrid-pyroute2 plumgrid-argcomplete plumgrid-docopt plumgrid-esper plumgrid-gcc plumgrid-jira plumgrid-jshint plumgrid-jsonrpclib plumgrid-nodeapi plumgrid-rpyc plumgrid-sigmund plumgrid-tabulate plumgrid-websocket-client libluajit-5.1-dev
  echo "Preparing /opt/pg directory"
  tryexec sudo mkdir -p /opt/local/bin
  tryexec sudo mkdir -p /opt/pg/{bin,core,debug,lib,echo,share,test,tmp,web}
  tryexec sudo chown -R $USER:$USER /opt/pg
  tryexec sudo chown -R $USER:$USER /opt/local/
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
