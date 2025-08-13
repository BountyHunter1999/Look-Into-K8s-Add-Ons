run:
	vagrant up --provider=virtualbox

add_plugins:
	vagrant plugin install vagrant-vboxmanage
	vagrant plugin install vagrant-vbguest

health:
	curl https://192.168.56.101

destroy:
	vagrant destroy -f