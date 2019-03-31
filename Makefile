
PROJECT_ROOT_DIR=${shell pwd}


download-roles:
	ansible-galaxy install -r requirements.yml --roles-path ./roles/

download-roles-force:
	ansible-galaxy --force install -r requirements.yml --roles-path ./roles/

download-roles-global:
	ansible-galaxy install -r requirements.yml --roles-path=/etc/ansible/roles

download-roles-global-force:
	ansible-galaxy install --force -r requirements.yml --roles-path=/etc/ansible/roles

clone-k3s-ansible:
	git clone https://github.com/itwars/k3s-ansible ~/dev/k3s-ansible
	cp -av /vagrant/site.yml ~/dev/k3s-ansible/site.yml
	cp -avs /vagrant/site.yml ~/dev/k3s-ansible/site.yaml

local-clone-k3s-ansible:
	[ ! -d "roles/k3s-ansible/.git" ] && git clone https://github.com/itwars/k3s-ansible roles/k3s-ansible || echo "already cloned k3s-ansible"
	cp -av site.yml roles/k3s-ansible/site.yml
	cp -av site.yml roles/k3s-ansible/site.yaml

provision-ks3:
	-ansible-playbook -v roles/k3s-ansible/site.yml -i inventory.ini
	-ansible-playbook -v roles/k3s-ansible/site.yml -i inventory.ini


multi-ssh-k3lab:
	i2cssh -XF=$(PROJECT_ROOT_DIR)/ssh_config.k3lab.conf -Xi=~/.ssh/vagrant_id_rsa k3lab

i2cssh-k3lab: multi-ssh-k3lab

k3lab-ssh: multi-ssh-homelab

up:
	vagrant up

destroy:
	vagrant destroy -f

dev: up local-clone-k3s-ansible provision-ks3

bootstrap: dev

rebootstrap: destroy bootstrap
