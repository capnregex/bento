#!/bin/sh -eux
# Install Ruby, Git, Node, Postgres, and Redis

# Use UTF-8 for everything
sudo locale-gen en_US.UTF-8

echo "LANG=en_US.UTF-8
LANGUAGE=
LC_CTYPE="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
LC_ALL=en_US.UTF-8" | sudo tee /etc/default/locale

# Download no additional languages
sudo touch /etc/apt/apt.conf.d/00aptitude
echo 'Acquire::Languages "none";' | sudo cat /etc/apt/apt.conf.d/00aptitude

sudo apt-get -y install \
  linux-headers-$(uname -r) \
  apt-transport-https \
  asciidoc \
  automake \
  build-essential \
  ca-certificates \
  curl \
  docbook2x \
  dkms \
  firefox \
  fontconfig \
  g++ \
  gcc \
  gettext \
  git-core \
  graphviz \
  gstreamer1.0-plugins-base \
  gstreamer1.0-tools \
  gstreamer1.0-x \
  libssl-dev \
  libcurl4-openssl-dev \
  libevent-dev \
  libexpat1-dev \
  libffi-dev \
  libgdbm-dev \
  libgdbm3 \
  libqt5webkit5-dev \
  libreadline-dev \
  libsqlite3-dev \
  libxml2-dev \
  libxslt1-dev \
  libxslt-dev \
  libsqlite3-dev \
  libssl-dev \
  libyaml-dev \
  linux-image-extra-virtual \
  make \
  ncurses-dev \
  python-software-properties \
  qt5-default \
  software-properties-common \
  sqlite3 \
  tcl \
  unzip \
  vim \
  wget \
  x11-xkb-utils \
  xfonts-100dpi \
  xfonts-75dpi \
  xfonts-scalable \
  xfonts-cyrillic \
  xmlto \
  xvfb \
  zlib1g-dev \
  zsh

# Install newer version of git
sudo apt-get -y install git # should be at least 2.9.0

# Use asdf to manage ruby versions
git clone https://github.com/asdf-vm/asdf.git /home/vagrant/.asdf --branch v0.2.1

# Default for bash
echo '. $HOME/.asdf/asdf.sh
. $HOME/.asdf/autocompletions/asdf.bash' | sudo tee -a /etc/bashrc

# Default for ZSH
echo '. $HOME/.asdf/asdf.sh
. $HOME/.asdf/autocompletions/asdf.bash' | sudo tee -a /etc/zshrc

/home/vagrant/.asdf/bin/asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby
/home/vagrant/.asdf/bin/asdf install ruby 2.3.3

/home/vagrant/.asdf/bin/asdf global ruby 2.3.3

# Install node
# this forces install of some missing support packages, may not be necessary
# but was when tested manually
sudo apt-get -y -f install
# this is MUCH faster than compiling
sudo apt-get -y install nodejs # should be at least 6.2.0

# install postgres 9.6
cd ~
sudo touch /etc/apt/sources.list.d/pgdg.list
echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' | sudo tee -a /etc/apt/sources.list.d/pgdg.list
# sometimes this fails behind a proxy
# http://unix.stackexchange.com/a/82602
sudo -E wget --quiet https://www.postgresql.org/media/keys/ACCC4CF8.asc && break
# add the key
sudo -E apt-key add ACCC4CF8.asc
rm -f ACCC4CF8.asc

sudo apt-get -y update

sudo apt-get -y install postgresql-9.6 postgresql-client-9.6 postgresql-contrib-9.6 libpq-dev postgresql-server-dev-9.6 expect

# Setup pg_hba.conf file so postgres can connect locally
sudo rm -f /etc/postgresql/9.6/main/pg_hba.conf

echo "# Administrative login with Unix domain sockets
local   all             postgres                                trust
# local   all             vagrant                                 trust
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5" | sudo tee -a /etc/postgresql/9.6/main/pg_hba.conf

# Reload postgres
sudo /etc/init.d/postgresql reload

# create a ubuntu user, for connecting locally if needed
# sudo -u postgres createuser vagrant --createdb --no-superuser --no-createrole

# install redis
# https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-redis-on-ubuntu-16-04
cd ~
wget http://download.redis.io/redis-stable.tar.gz
tar xzf redis-stable.tar.gz
cd redis-stable
make
# make test
sudo make install
cd utils
# install non-interactively with defaults
echo -n | sudo ./install_server.sh


sudo service redis_6379 start
# other commands include:
# sudo service redis_6379 stop
# sudo service redis_6379 status

sudo rm -rf ~/redis-*

# install tmux
cd /home/vagrant
git clone https://github.com/tmux/tmux.git
# Dependencies were already installed in VM, but in case they weren't
# sudo apt-get -y install automake libevent-dev ncurses-dev
cd tmux
sh autogen.sh
./configure && make
sudo make install
sudo rm -rf /home/vagrant/tmux

# don't do this by default any longer
# echo "gem: --no-document --suggestions
# benchmark: false
# verbose: true
# update_sources: true
# backtrace: true
# gemhome: ~/.gem
# gempath: ~/.gem" | sudo tee -a /etc/gemrc

# # never manually edit sudoers file. except now
sudo sed -i '/Defaults\senv_reset/ a\Defaults\tenv_keep +="HTTP_PROXY"' /etc/sudoers
sudo sed -i '/Defaults\senv_reset/ a\Defaults\tenv_keep +="HTTPS_PROXY"' /etc/sudoers
sudo sed -i '/Defaults\senv_reset/ a\Defaults\tenv_keep +="NO_PROXY"' /etc/sudoers
sudo sed -i '/Defaults\senv_reset/ a\Defaults\tenv_keep +="http_proxy"' /etc/sudoers
sudo sed -i '/Defaults\senv_reset/ a\Defaults\tenv_keep +="https_proxy"' /etc/sudoers
sudo sed -i '/Defaults\senv_reset/ a\Defaults\tenv_keep +="no_proxy"' /etc/sudoers

# # unused paths
# sudo sed -i 's/:\/usr\/games:\/usr\/local\/games//' /etc/environment

# # the box is already getting kind of big, but these seem to be pretty requested,
# # especially for people on windows. what's another GB? or two? fiber ftw

# install a lightweight desktop
sudo apt-get -y install xubuntu-desktop --no-install-recommends
sudo apt-get -y install xfce4-terminal
sudo apt-get -y install xfce4-screenshooter xfce4-whiskermenu-plugin xfpanel-switch xfce4-taskmanager xfce4-quicklauncher-plugin xfce4-indicator-plugin ristretto mugshot libxfce4ui-utils file-roller xfce4-clipman-plugin xfce4-linelight-plugin thunar-archive-plugin xfce4-power-manager gtk3-engines-xfce
sudo apt-get -y install qpdfview # pdf viewer

# # # but not libreoffice
# # sudo apt-get -y remove --purge libreoffice*
# # sudo apt-get autoclean # removes .deb files for packages no longer installed on your system

# # sublime ftw. if you don't own a license already, please support!
sudo -E add-apt-repository -y ppa:webupd8team/sublime-text-3
sudo apt-get -y update
sudo apt-get -y install sublime-text-installer

sudo apt-get -f -y install

# chrome ftw
cd /home/vagrant/
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i --force-depends google-chrome-stable_current_amd64.deb
rm -rf google-chrome-stable_current_amd64.deb

sudo apt-get -f -y install

# put an awesome font in the font cache
mkdir -p /home/vagrant/.fonts
chown vagrant:vagrant /home/vagrant/.fonts
cd /home/vagrant/.fonts
wget https://github.com/powerline/fonts/raw/master/DroidSansMonoSlashed/Droid%20Sans%20Mono%20Slashed%20for%20Powerline.ttf
chown vagrant:vagrant Droid\ Sans\ Mono\ Slashed\ for\ Powerline.ttf
sudo fc-cache -f -v
