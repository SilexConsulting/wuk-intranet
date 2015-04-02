#!/bin/bash
set -e

puppet_base='/vagrant/puppet'
to_provision='/vagrant/puppet/manifests/site.pp'

if [ -f /vagrant/vagrant.pp ] ;
then
  echo 'Found local vagrant.pp - using that instead'
  to_provision='/vagrant/vagrant.pp'
fi

# Don't change config if there are already keys
if [ ! -f /home/vagrant/.ssh/id_rsa ];
then
    sed -i '1s/^/nameserver 8.8.8.8\n/' /etc/resolv.conf
    yum install puppet -y
    yum install ruby -y
    yum install gcc g++ make automake autoconf curl-devel openssl-devel zlib-devel httpd-devel apr-devel apr-util-devel sqlite-devel -y
    yum install ruby-rdoc ruby-devel -y
    yum install rubygems -y

    # for building php 5.2.x
    yum install libxml2 libxml2-devel pcre-devel bzip2-devel libjpeg-devel libpng-devel libXpm-devel -y
    yum install freetype-devel gmp-devel mysql-devel unixODBC-devel readline-devel net-snmp-devel -y
    yum install libxslt-devel -y

    gem update
    gem install hiera
    gem install hiera-eyaml
    gem install hiera-puppet
    #gem install librarian-puppet

    rm -rf /vagrant/puppet/modules/hiera-puppet
    ln -s /usr/lib/ruby/gems/1.8/gems/hiera-puppet-1.0.0/ /vagrant/puppet/modules/hiera-puppet
    rm -rf /etc/puppet
    ln -sf /vagrant/puppet /etc/
    ln -sf /vagrant/puppet/hiera.yaml /etc/
    ln -sf /vagrant/hieradata /etc/


    touch  /home/vagrant/.ssh/id_rsa

fi

# runs once
if [ ! -f /vagrant/keys/private_key.pkcs7.pem ];
then
    cd /home/vagrant
    eyaml createkeys
fi

/usr/bin/puppet apply --verbose \
  --manifestdir=${puppet_base}/manifests \
  --modulepath=${puppet_base}/modules \
  ${to_provision}
