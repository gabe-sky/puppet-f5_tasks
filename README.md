# Overview

This module holds a few ad-hoc Bolt tasks to perform actions on an f5.  These were written with specific needs in mind, and may only partially suit your own purposes.  Go ahead and open issues or submit pull requests, as desired.

These tasks are intended for one-off actions like changing nodes' states and triggering backups.  If you want to *maintain* the state of an f5, you should use the [f5-f5](https://forge.puppet.com/f5/f5) module for that.


# Running Tasks

## Command Line

These tasks are interesting, since you can't run a task *on* an f5 -- you have to run a task on a node (Linux examples given, but should work on Windows) that then does the request to the iControl API for you.

  * Pick a system that can reach the f5 on port 443.
  * [Install Bolt](https://puppet.com/docs/bolt/latest/bolt_installing.html).
  * Copy this `f5_tasks` module to that system.
  * Run commands from the directory that holds the `f5_tasks` module code.

You'll be running the tasks on `--nodes localhost` because that's where the Ruby code is running.  To tell the task what f5 to manage, you'll supply a `device_name` parameter.  Here's an example of running one of this module's tasks, assuming that you've copied the `f5_tasks` module into your home directory.

```shell
bolt task run --modulepath ~ --nodes localhost f5_tasks::set_password \
  device_name=lab-bigip.puppetlabs.vm \
  api_user=admin \
  api_password=admin \
  target_user=gabe \
  target_password='$6$TU93N6WE$4HVyTooManySecretsROiWnjEgIi9ufEn'
```

If you get tired of having to put all the parameters onto the command line, you can stash them in a JSON file and tell bolt to read that.  (You might, in fact, have a directory full of JSON files for commonly used parameter sets.)  For instance the JSON to match that last command looks like this:

```json
{
  "device_name": "lab-bigip.puppetlabs.vm",
  "device_port": "443",
  "api_user": "admin",
  "api_password": "admin",
  "target_user": "gabe",
  "target_password":"$6$TU93N6WE$4HSetecAstronomyROiWnjEgIi9ufEn"
}
```

They you use the `--params` flag and aim it at the file with an `@` in front of the name.  For instance if you stored the parameters in a file called `input_file.json`:

```shell
bolt task run --modulepath ~ --nodes localhost f5_tasks::set_password \
  --params @input_file.json
```

## Puppet Enterprise Console

These tasks should work just as well from the Puppet Enterprise Console, if you like RBAC and/or graphical interfaces.  Just remember, the "target" system you're running the tasks on is some node that can reach the f5 on port 443.  You'll specify the name of the f5 with the `device_name` parameter.


# Task Reference

## `f5_tasks::set_password`

From time to time you need to update passwords on your f5 devices.  This simple task uses the iControl REST API to accomplish that.

device_name: The resolvable name or IP of the target f5 device
device_port: The port to connect to the API over.  Omit this to use 443.
api_user: The name of the user to use when authenticating to the API (Defaults to 'admin')
api_password: The password of the user that authenticates to the API (Defaults to 'admin')
target_user: The user on the f5 that you wish to modify
target_password: The hashed password for the user that you are modifying

## `f5_tasks::set_node_state`

A simple task makes it easy to toggle a node (distinct from a pool member, which is another task) into enabled, disabled, or offline state.

device_name: The resolvable name or IP of the target f5 device
device_port: The port to connect to the API over.  Omit this to use 443.
api_user: The name of the user to use when authenticating to the API (Defaults to 'admin')
api_password: The password of the user that authenticates to the API (Defaults to 'admin')
node_name: The node you want to work with.
node_state: The desired state of the node. ('enabled', 'disabled', or 'offline')

## `f5_tasks::set_pool_member_state`
This task makes it easy to toggle a pool member (distinct from a node, which is another task) into enabled, disabled, or offline state.

device_name: The resolvable name or IP of the target f5 device
device_port: The port to connect to the API over.  Omit this to use 443.
api_user: The name of the user to use when authenticating to the API (Defaults to 'admin')
api_password: The password of the user that authenticates to the API (Defaults to 'admin')
pool_name: The pool to operate on.
partition_name: The partition to work in.  (Defaults to 'Common')
member_name: The member we're working with.
member_state: The desired state of the pool member. ('enabled', 'disabled', or 'offline')

## `f5_tasks::ucs_save`
This task instructs an f5 device to immediately make a .ucs backup file in the specified location.

device_name: The resolvable name or IP of the target f5 device
device_port: The port to connect to the API over.  Omit this to use 443.
api_user: The name of the user to use when authenticating to the API (Defaults to 'admin')
api_password: The password of the user that authenticates to the API (Defaults to 'admin')
file_path: Where on the f5 to store the archive.  (Defaults to /var/local/ucs/backup-*<DATE>*.ucs, same as the GUI does.)

## `f5_tasks::config_save`
This task instructs the f5 device to immediately save its .conf files.

device_name: The resolvable name or IP of the target f5 device
device_port: The port to connect to the API over.  Omit this to use 443.
api_user: The name of the user to use when authenticating to the API (Defaults to 'admin')
api_password: The password of the user that authenticates to the API (Defaults to 'admin')

## `f5_tasks::config_sync`
This task forces a configuration sync among members of the desired device group.

device_name: The resolvable name or IP of the target f5 device
device_port: The port to connect to the API over.  Omit this to use 443.
api_user: The name of the user to use when authenticating to the API (Defaults to 'admin')
api_password: The password of the user that authenticates to the API (Defaults to 'admin')
device_group: The device group to sync.  (Defaults to device_trust_group)
# Plans

## `f5_tasks::save_and_fetch_archive`
This plan uses the tasks that save and delete archives, to trigger an immediate save of an archive, then transfer it to the local system, and finally delete the archive from the f5 node.

device_name: The resolvable name or IP of the target f5 device
device_port: The port to connect to the API over.  Omit this to use 443.
api_user: The name of the user to use when authenticating to the API (Defaults to 'admin')
api_password: The password of the user that authenticates to the API (Defaults to 'admin')
scp_user: Account to use for the `scp` command.  (Defaults to 'admin')
scp_identity_file:  Where the private key for that user is.  (Defaults to '~/.ssh/id_rsa')
local_backup_dir: Where to store the fetched archive file.  (Defaults to '/tmp/f5')
tidy_backup_dir: Whether or not to tidy up by deleting two-week-old archive files from the backup dir.  (Defaults to true)
