# -*- mode: ruby -*-
# vi: set ft=ruby :

BOX_BASE =  'ubuntu/yakkety64'.freeze

SWIFT_PATH = 'https://swift.org/builds/swift-3.1-branch/ubuntu1610/swift-3.1-DEVELOPMENT-SNAPSHOT-2017-03-02-a'.freeze
SWIFT_DIRECTORY = 'swift-3.1-DEVELOPMENT-SNAPSHOT-2017-03-02-a-ubuntu16.10'.freeze
SWIFT_FILE = "#{SWIFT_DIRECTORY}.tar.gz".freeze
SWIFT_HOME = "/home/vagrant/#{SWIFT_DIRECTORY}".freeze

Vagrant.configure(2) do |config|
  config.vm.define :micro do |micro|
    micro.vm.box = BOX_BASE
    micro.vm.network :private_network, ip: "10.0.0.10"
    micro.vm.hostname = "micro"
    micro.vm.network 'forwarded_port', guest: 8090, host: 8090
    micro.vm.synced_folder ".", "/Project"

  	micro.vm.provider "virtualbox" do |v|
  	  v.memory = 1024
  	  v.cpus = 2
  	end

    # Prevents "stdin: is not a tty" on Ubuntu (https://github.com/mitchellh/vagrant/issues/1673)
    micro.vm.provision 'fix-no-tty', type: 'shell' do |s|
      s.privileged = false
      s.inline = "sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
    end

    micro.vm.provision 'shell', privileged: false, inline: <<-SHELL

  ### Install packages
  # 0. Update latest package lists
  	sudo apt-get --assume-yes update
  # 1. Install compiler, autotools
      sudo apt-get --assume-yes install clang
      sudo apt-get --assume-yes install autoconf libtool pkg-config libpython2.7
  # 2. Install dtrace (to generate provider.h)
      sudo apt-get --assume-yes install systemtap-sdt-dev
  # 3. Install libdispatch pre-reqs
      sudo apt-get --assume-yes install libblocksruntime-dev libkqueue-dev libpthread-workqueue-dev libbsd-dev
  # 4. Kitura packages
      sudo apt-get --assume-yes install libhttp-parser-dev libcurl4-openssl-dev libhiredis-dev
  # 5. Perfect.org packages
    sudo apt-get --assume-yes install openssl libssl-dev uuid-dev
    sudo apt-get --assume-yes install expect

  ### Download Swift binary if not found, install it, and add it to the path
      if [ ! -f "#{SWIFT_FILE}" ]; then
          curl -O "#{SWIFT_PATH}/#{SWIFT_FILE}"
      fi
      sudo tar -xzf #{SWIFT_FILE} --directory / --strip-components=1
      sudo find /usr/lib/swift -type d -print0 | sudo xargs -0 chmod a+rx
      sudo find /usr/lib/swift -type f -print0 | sudo xargs -0 chmod a+r

  	  sudo sh -c "echo '10.0.0.11       ssldemo.linuxswift.com' >> /etc/hosts"
      
      sudo curl https://letsencrypt.org/certs/isrgrootx1.pem.txt -o /usr/local/share/ca-certificates/isrgrootx1.crt
      sudo curl https://letsencrypt.org/certs/letsencryptauthorityx1.pem.txt -o /usr/local/share/ca-certificates/letsencryptauthorityx1.crt
      sudo curl https://letsencrypt.org/certs/letsencryptauthorityx2.pem.txt -o /usr/local/share/ca-certificates/letsencryptauthorityx2.crt
      sudo curl https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem.txt -o /usr/local/share/ca-certificates/letsencryptx1.crt
      sudo curl https://letsencrypt.org/certs/lets-encrypt-x2-cross-signed.pem.txt -o /usr/local/share/ca-certificates/letsencryptx2.crt
      sudo curl https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o /usr/local/share/ca-certificates/letsencryptx3.crt
      sudo curl https://letsencrypt.org/certs/lets-encrypt-x4-cross-signed.pem.txt -o /usr/local/share/ca-certificates/letsencryptx4.crt
      curl -O https://raw.githubusercontent.com/carlbrown/SpaceTimeMilieuMicro/master/add_certs.exp
    
      chmod 755 add_certs.exp
      sudo ./add_certs.exp

  ### Export LD_LIBRARY_PATH
      if [ $(grep -c "LD_LIBRARY_PATH=/usr/local/lib" .profile) -eq 0 ]; then
          echo "export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH" >> .profile
          source .profile
      fi

    SHELL
  end
  config.vm.define :elevation do |elevation|
    elevation.vm.box = BOX_BASE
    elevation.vm.network :private_network, ip: "10.0.0.11"
    elevation.vm.hostname = "elevation"
    elevation.vm.network 'forwarded_port', guest: 8091, host: 8091
    elevation.vm.synced_folder "../SpaceTimeMilieuElevation", "/Project"

  	elevation.vm.provider "virtualbox" do |v|
  	  v.memory = 1024
  	  v.cpus = 2
  	end

    # Prevents "stdin: is not a tty" on Ubuntu (https://github.com/mitchellh/vagrant/issues/1673)
    elevation.vm.provision 'fix-no-tty', type: 'shell' do |s|
      s.privileged = false
      s.inline = "sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
    end

    elevation.vm.provision 'shell', privileged: false, inline: <<-SHELL

  ### Install packages
  # 0. Update latest package lists
  	sudo apt-get --assume-yes update
  # 1. Install compiler, autotools
      sudo apt-get --assume-yes install clang
      sudo apt-get --assume-yes install autoconf libtool pkg-config libpython2.7
  # 2. Install dtrace (to generate provider.h)
      sudo apt-get --assume-yes install systemtap-sdt-dev
  # 3. Install libdispatch pre-reqs
      sudo apt-get --assume-yes install libblocksruntime-dev libkqueue-dev libpthread-workqueue-dev libbsd-dev
  # 4. Kitura packages
      sudo apt-get --assume-yes install libhttp-parser-dev libcurl4-openssl-dev libhiredis-dev
  # 5. Perfect.org packages
      sudo apt-get --assume-yes install openssl libssl-dev uuid-dev
      sudo apt-get --assume-yes install expect

  ### Download Swift binary if not found, install it, and add it to the path
      if [ ! -f "#{SWIFT_FILE}" ]; then
          curl -O "#{SWIFT_PATH}/#{SWIFT_FILE}"
      fi
      sudo tar -xzf #{SWIFT_FILE} --directory / --strip-components=1
      sudo find /usr/lib/swift -type d -print0 | sudo xargs -0 chmod a+rx
      sudo find /usr/lib/swift -type f -print0 | sudo xargs -0 chmod a+r
	  
	  sudo sh -c "echo '10.0.0.10       ssldemo.linuxswift.com' >> /etc/hosts"
    
    sudo curl https://letsencrypt.org/certs/isrgrootx1.pem.txt -o /usr/local/share/ca-certificates/isrgrootx1.crt
    sudo curl https://letsencrypt.org/certs/letsencryptauthorityx1.pem.txt -o /usr/local/share/ca-certificates/letsencryptauthorityx1.crt
    sudo curl https://letsencrypt.org/certs/letsencryptauthorityx2.pem.txt -o /usr/local/share/ca-certificates/letsencryptauthorityx2.crt
    sudo curl https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem.txt -o /usr/local/share/ca-certificates/letsencryptx1.crt
    sudo curl https://letsencrypt.org/certs/lets-encrypt-x2-cross-signed.pem.txt -o /usr/local/share/ca-certificates/letsencryptx2.crt
    sudo curl https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o /usr/local/share/ca-certificates/letsencryptx3.crt
    sudo curl https://letsencrypt.org/certs/lets-encrypt-x4-cross-signed.pem.txt -o /usr/local/share/ca-certificates/letsencryptx4.crt
    sudo curl https://letsencrypt.org/certs/lets-encrypt-x4-cross-signed.pem.txt -o /usr/local/share/ca-certificates/letsencryptx4.crt
    curl -O https://raw.githubusercontent.com/carlbrown/SpaceTimeMilieuMicro/master/add_certs.exp
    
    chmod 755 add_certs.exp
    sudo ./add_certs.exp

  ### Export LD_LIBRARY_PATH
      if [ $(grep -c "LD_LIBRARY_PATH=/usr/local/lib" .profile) -eq 0 ]; then
          echo "export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH" >> .profile
          source .profile
      fi

    SHELL
  end
end
