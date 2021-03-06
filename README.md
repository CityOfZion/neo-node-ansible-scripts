Ansible playbooks for setting up Ubuntu 18.04/16.04 servers as neo nodes:

* Basic server security setup
* [neo-cli nodes](http://docs.neo.org/en-us/node/introduction.html) and [notification servers](https://github.com/localhuman/neo-cli/blob/plugin-notification-restapi/notifications.md)
  * supervised and auto-started by systemd
  * Script to check increasing block-height, which restarts the service if it is stuck
* Nginx reverse proxy with IP rate-limit and caching, CORS, logging and logrotate
* Let's Encrypt certificates with auto-renewals
* Playbooks for upgrading nodes


#### Playbooks

* `server_base_setup.yml`: Security, user, software, unattended updates. Only incoming port allowed is 22. Note: Disables SSH login as root user.
* `neo_node_base.yml`: Basic neo-cli setup, bootstrap if available. No other open ports to the outside.
* `neo_node_notif_base.yml`: Basic notification-server setup, bootstrap if available. No other open ports to the outside.
* `neo_node_nginx.yml`: Nginx reverse proxy, 10s caching, Let's Encrypt certificate w/ auto renewal. Opens ports 80 and 443.
* `neo_node_upgrade.yml`: Update neo nodes (only works if the old chain compatible)
* `neo_node_notif_upgrade.yml`: Update neo nodes (only works if the old chain compatible)

After the basic server setup, you'll need to enable 2FA with google authenticator manually as described [here](https://github.com/CityOfZion/standards/blob/master/nodes.md#2-factor-authentication). Also, use your
YubiKey protected SSH key for login. See also [here](https://github.com/CityOfZion/standards/blob/master/nodes.md#ssh-authentication-keys)
for more infos.


#### Notes

* All custom software and scripts are located in `/server/` (configurable in `group_vars/all.yml`)
* Tested with ansible 2.6.1+
* Can be easily tested with a VM (`Vagrantfile` is included)
* Servers are based on Ubuntu 18.04 LTS (Bionic Beaver) 64 bit or Ubuntu 16.04
  * Note: the latest Ubuntu version does not include Python 2 anymore, only `/usr/bin/python3`, so we configure that in `inventory`
* See also:
  * https://github.com/CityOfZion/standards/blob/master/nodes.md


## Getting Started

The easiest start is to run the playbooks on a virtual machine. Included is a Vagrantfile which spins up an Ubuntu instance
with the IP 10.0.0.10 that you can use to experiment. If you want to change that IP, just update `Vagrantfile` and `inventory` and recreate the VM.


#### Code overview:

* General variables are in `group_vars/*.yml`
* The playbooks are in `playbooks/*.yml`
* The inventory lists your servers and defines the groups. See `inventory`
* Files and templates that are uploaded to the server can be found in the respective directories


## Running on a new server

Add the server(s) to `inventory` (perhaps remove the existing ones). If you want the Let's Encrypt/nginx setup, then use the FQDN in the `inventory` file rather than the IP address, as this is used for getting the certificates (alternatively, you can override this with a `fqdn` variable in `host_vars/<ip>.yml`. Then run the playbooks on all hosts like this:

    $ ansible-playbook -i inventory playbooks/server_base_setup.yml
    $ ansible-playbook -i inventory playbooks/node_neo_base.yml

If you want to provision the server with notification server instead of standard neo-cli:

    $ ansible-playbook -i inventory playbooks/node_neo_notif_base.yml

You can also limit it to a specific host, or to a full group like `node_neo`:

    $ ansible-playbook -i inventory --limit node_neo playbooks/server_base_setup.yml
    $ ansible-playbook -i inventory --limit node_neo playbooks/node_neo_base.yml

After neo-cli is setup, the server is running it with a systemd service called `neonode`. You can check the neo-cli node inside the server:

    server$ systemctl status neonode
    server$ journalctl -f -u neonode

Finally, run the nginx+letsencrypt playbook:

    $ ansible-playbook -i inventory --limit node_neo playbooks/node_neo_nginx.yml

Now you can do HTTPS request to the server.


### Updating nginx config

If you want to update the nginx config, just change the template file, and re-run `playbooks/node_neo_nginx.yml`.


## Testing with Vagrant

Start the VM:

    $ vagrant up

Test connectivity by running the ansible `ping` module:

    $ ansible -i inventory vm --limit 10.0.0.10 -m ping

Run the playbooks:

    $ ansible-playbook -i inventory --limit 10.0.0.10 playbooks/server_base_setup.yml
    $ ansible-playbook -i inventory --limit 10.0.0.10 playbooks/node_neo_base.yml

SSH into the VM:

    $ vagrant ssh

Inside the VM you can check the nginx proxy or the neo-cli service (`neonode`):

    vagrant$ systemctl status neonode
    vagrant$ systemctl start|stop|restart neonode

Destroy the VM and remove all content:

    $ vagrant destroy
