# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant multi machine configuration

require 'yaml'
config_yml = YAML.load_file(File.open(__dir__ + '/vagrant-config.yml'))

NON_ROOT_USER = 'vagrant'.freeze


$fix_perm = <<SHELL
sudo chmod 600 /home/vagrant/.ssh
sudo chmod 600 /home/vagrant/.ssh/id_rsa

sudo mkdir -p /root/.ssh
sudo chmod 600 /root/.ssh

sudo cp /home/vagrant/.ssh/id_rsa /root/.ssh/id_rsa
sudo chmod 600 /root/.ssh/id_rsa
SHELL


$fix_ulimit = <<SHELL
    set -x;
    # install docker v17.03
    # reason for not using docker provision is that it always installs latest version of the docker, but kubeadm requires 17.03 or older
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    # curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    # add-apt-repository "deb https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
    # apt-get update && apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep 18.09 | head -1 | awk '{print $3}')
    # apt-mark hold docker-ce
    # curl -fsSL https://get.docker.com -o get-docker.sh
    # sh get-docker.sh

    # # run docker commands as vagrant user (sudo not required)
    # usermod -aG docker vagrant

    # install kubeadm
    apt-get install -y apt-transport-https curl
    # apt-mark hold kubelet kubeadm kubectl

    # kubelet requires swap off
    sudo swapoff -a

    # keep swap off after reboot
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

    # ip of this box
    IP_ADDR=`ifconfig enp0s8 | grep Mask | awk '{print $2}'| cut -f2 -d:`
    sudo apt-get -y install python-minimal python-apt
    sudo apt-get install -y \
              bash-completion \
              curl \
              git \
              vim
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python-six python-pip

    sudo modprobe ip_vs_wrr
    sudo modprobe ip_vs_rr
    sudo modprobe ip_vs_sh
    sudo modprobe ip_vs
    sudo modprobe nf_conntrack_ipv4
    sudo modprobe bridge
    sudo modprobe br_netfilter

    sudo cat <<EOF >/etc/modules-load.d/k8s_ip_vs.conf
ip_vs_wrr
ip_vs_rr
ip_vs_sh
ip_vs
nf_conntrack_ipv4
EOF

    sudo cat <<EOF >/etc/modules-load.d/k8s_bridge.conf
bridge
EOF

    sudo cat <<EOF >/etc/modules-load.d/k8s_br_netfilter.conf
br_netfilter
EOF

  sudo apt-get install -y conntrack ipset

  sudo sysctl -w vm.min_free_kbytes=1024000
  sudo sync; sudo sysctl -w vm.drop_caches=3; sudo sync


  echo 1 | sudo tee /sys/kernel/mm/ksm/run
  echo 1000 | sudo tee /sys/kernel/mm/ksm/sleep_millisecs

  # SOURCE: https://blog.openai.com/scaling-kubernetes-to-2500-nodes/ ( VERY GOOD )

  echo "vm.min_free_kbytes=1024000" | sudo tee -a /etc/sysctl.d/kube.conf
  echo "net.ipv4.neigh.default.gc_thresh1 = 80000" | sudo tee -a /etc/sysctl.d/kube.conf
  echo "net.ipv4.neigh.default.gc_thresh2 = 90000" | sudo tee -a /etc/sysctl.d/kube.conf
  echo "net.ipv4.neigh.default.gc_thresh3 = 100000" | sudo tee -a /etc/sysctl.d/kube.conf
  # echo "sys.kernel.mm.ksm.run = 1" | sudo tee -a /etc/sysctl.d/kube.conf
  # echo "sys.kernel.mm.ksm.sleep_millisecs = 1000" | sudo tee -a /etc/sysctl.d/kube.conf
  # echo "fs.file-max = 2097152" | sudo tee -a /etc/sysctl.d/kube.conf
  sysctl -p


  echo "* soft     nproc          500000" | sudo tee /etc/security/limits.d/perf.conf
  echo "* hard     nproc          500000" | sudo tee -a /etc/security/limits.d/perf.conf
  echo "* soft     nofile         500000" | sudo tee -a /etc/security/limits.d/perf.conf
  echo "* hard     nofile         500000"  | sudo tee -a /etc/security/limits.d/perf.conf
  echo "root soft     nproc          500000" | sudo tee -a /etc/security/limits.d/perf.conf
  echo "root hard     nproc          500000" | sudo tee -a /etc/security/limits.d/perf.conf
  echo "root soft     nofile         500000" | sudo tee -a /etc/security/limits.d/perf.conf
  echo "root hard     nofile         500000" | sudo tee -a /etc/security/limits.d/perf.conf

  sudo sed -i '/pam_limits.so/d' /etc/pam.d/sshd
  echo "session    required   pam_limits.so" | sudo tee -a /etc/pam.d/sshd
  sudo sed -i '/pam_limits.so/d' /etc/pam.d/su
  echo "session    required   pam_limits.so" | sudo tee -a /etc/pam.d/su
  sudo sed -i '/session required pam_limits.so/d' /etc/pam.d/common-session
  echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session
  sudo sed -i '/session required pam_limits.so/d' /etc/pam.d/common-session-noninteractive
  echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session-noninteractive
  # NOTE: https://medium.com/@muhammadtriwibowo/set-permanently-ulimit-n-open-files-in-ubuntu-4d61064429a
  # TODO: Put into playbook
  # echo "2097152" | sudo tee /proc/sys/fs/file-max
SHELL




# This script to install k8s using kubeadm will get executed after a box is provisioned
$configureBox = <<-SCRIPT
    mkdir -p ~vagrant/dev
    git clone https://github.com/viasite-ansible/ansible-role-zsh ~/dev/ansible-role-zsh
    git clone https://github.com/bossjones/docker-kernel-ide ~/dev/docker-kernel-ide
    sudo git clone https://github.com/bossjones/debug-tools /usr/local/src/debug-tools
    sudo git clone https://github.com/itwars/k3s-ansible /usr/local/src/k3s-ansible
    sudo /usr/local/src/debug-tools/update-bossjones-debug-tools
    sudo chown vagrant:vagrant -Rv ~vagrant
    sudo apt-get install software-properties-common -y
    sudo apt-add-repository ppa:ansible/ansible -y
    sudo apt-get update
    sudo apt-get install ansible -y

    sudo apt-get -y install bison build-essential cmake flex git libedit-dev \
    libllvm6.0 llvm-6.0-dev libclang-6.0-dev python zlib1g-dev libelf-dev

    sudo apt-get -y install luajit luajit-5.1-dev

    sudo chown vagrant:vagrant -R /usr/local/bin

    cd /usr/local/bin
    wget -O grv https://github.com/rgburke/grv/releases/download/v0.3.1/grv_v0.3.1_linux64
    chmod +x ./grv
    cd -

    # git clone https://github.com/iovisor/bcc.git
    # mkdir bcc/build; cd bcc/build
    # cmake .. -DCMAKE_INSTALL_PREFIX=/usr
    # make
    # sudo make install

    ### add packages (both necessary and convenient)
    echo Adding packages...
    sudo apt-get install -y gcc make ncurses-dev libssl-dev bc
    echo Adding packages for perf...
    sudo apt-get install -y flex bison libelf-dev libdw-dev libaudit-dev
    echo Adding packages for perf TUI...
    sudo apt-get install -y libnewt-dev libslang2-dev
    echo Adding packages for convenience...
    sudo apt-get install -y sharutils sysstat bc
    sudo apt-get -y install etckeeper


    sudo cat <<EOF >/etc/etckeeper/etckeeper.conf
## Ansible managed

# The VCS to use.
VCS="git"

# Options passed to git commit when run by etckeeper.
GIT_COMMIT_OPTIONS=""

# Options passed to hg commit when run by etckeeper.
HG_COMMIT_OPTIONS=""

# Options passed to bzr commit when run by etckeeper.
BZR_COMMIT_OPTIONS=""

# Options passed to darcs record when run by etckeeper.
DARCS_COMMIT_OPTIONS="-a"

# Uncomment to avoid etckeeper committing existing changes
# to /etc automatically once per day.
AVOID_DAILY_AUTOCOMMITS=0

# Uncomment the following to avoid special file warning
# (the option is enabled automatically by cronjob regardless).
AVOID_SPECIAL_FILE_WARNING=0

# Uncomment to avoid etckeeper committing existing changes to
# /etc before installation. It will cancel the installation,
# so you can commit the changes by hand.
AVOID_COMMIT_BEFORE_INSTALL=0

# The high-level package manager that's being used.
# (apt, pacman-g2, yum, dnf, zypper etc)
HIGHLEVEL_PACKAGE_MANAGER=apt

# The low-level package manager that's being used.
# (dpkg, rpm, pacman, pacman-g2, etc)
LOWLEVEL_PACKAGE_MANAGER=dpkg

# To push each commit to a remote, put the name of the remote here.
# (eg, "origin" for git). Space-separated lists of multiple remotes
# also work (eg, "origin gitlab github" for git).
PUSH_REMOTE=""
EOF

    # /proc/sys/fs/inotify/max_user_watches
    # bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait --non-interactive

    sudo apt-get install ccze socat iptables htop -y


    # kubectl
    # curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
    # sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
    # sudo apt install kubectl -y
    mkdir -p ~/.kube
    # cp -a /etc/rancher/k3s/k3s.yaml ~/.kube/config

    # EXAMPLE USAGE:
    # sudo k3s server &
    # # Kubeconfig is written to /etc/rancher/k3s/k3s.yaml
    # sudo k3s kubectl get node

    # # On a different node run the below. NODE_TOKEN comes from /var/lib/rancher/k3s/server/node-token
    # # on your server
    # sudo k3s agent --server https://myserver:6443 --token ${NODE_TOKEN}

SCRIPT

Vagrant.configure(2) do |config|
  # set auto update to false if you do NOT want to check the correct additions version when booting this machine
  # config.vbguest.auto_update = true

  config_yml[:vms].each do |name, settings|
    # use the config key as the vm identifier
    config.vm.define name.to_s, autostart: true, primary: true do |vm_config|
      config.ssh.insert_key = false
      vm_config.vm.usable_port_range = (2200..2250)

      # This will be applied to all vms

      # set auto_update to false, if you do NOT want to check the correct
      # additions version when booting this machine
      vm_config.vbguest.auto_update = true

      vm_config.vm.box = settings[:box]
      vm_config.disksize.size = settings[:disk]

      # config.vm.box_version = settings[:box_version]
      vm_config.vm.network 'private_network', ip: settings[:eth1]

      vm_config.vm.hostname = settings[:hostname]

      config.vm.provider 'virtualbox' do |v|
        # make sure that the name makes sense when seen in the vbox GUI
        v.name = settings[:hostname]

        v.gui = false
        v.customize ['modifyvm', :id, '--groups', '/k3slab Development']
        v.customize ['modifyvm', :id, '--memory', settings[:mem]]
        v.customize ['modifyvm', :id, '--cpus', settings[:cpu]]
      end

      hostname_with_hyenalab_tld = "#{settings[:hostname]}.hyenalab.home"

      aliases = [hostname_with_hyenalab_tld, settings[:hostname]]

      if Vagrant.has_plugin?('vagrant-hostsupdater')
        puts 'IM HERE BABY'
        config.hostsupdater.aliases = aliases
        vm_config.hostsupdater.aliases = aliases
      elsif Vagrant.has_plugin?('vagrant-hostmanager')
        puts 'IM HERE HONEY'
        vm_config.hostmanager.enabled = true
        vm_config.hostmanager.manage_host = true
        vm_config.hostmanager.manage_guests = true
        vm_config.hostmanager.ignore_private_ip = false
        vm_config.hostmanager.include_offline = true
        vm_config.hostmanager.aliases = aliases
      end

      vm_config.vm.provision 'shell', inline: $fix_ulimit

      vm_config.vm.provision :reload

      vm_config.vm.provision 'shell', inline: $configureBox

      # # copy private key so hosts can ssh using key authentication (the script below sets permissions to 600)
      # config.vm.provision :file do |file|
      #   file.source      = './keys/vagrant_id_rsa'
      #   file.destination = '/home/vagrant/.ssh/id_rsa'
      # end

      # # fix permissions on private key file
      # config.vm.provision :shell, inline: $fix_perm


    end
  end
end
