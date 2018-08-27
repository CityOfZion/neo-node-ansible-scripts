Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.ssh.insert_key = false

  # Setup the ip-addresses and port bindings
  config.vm.network :private_network, ip: "10.0.0.10"
  config.vm.synced_folder ".", "/vagrant"
end
