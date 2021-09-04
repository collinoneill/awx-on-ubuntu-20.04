Install AWX 17.0.1 on Ubuntu 20.04
==================================

System Requirements
-------------------
- At least 4 GB memory
- At least 2 CPU cores
- Running Docker, Openshift or Kubernetes
Prep the machine
----------------
```
sudo apt update -y  && sudo apt upgrade -y
sudo apt install ansible docker.io docker-compose -y
```
Clone Git repository
--------------------
```
git clone -b 17.0.1 https://github.com/ansible/awx.git
```
Edit the inventory file
-----------------------
```
cd ~awx/installer
nano inventory.yml
```
> Change admin_password to your own password -  or not. I discovered that this step does NOT work on 17.0.1.  Instead, you'll change the password later by signing into the docker container and using the awx_manage command to add a superuser.
```
admin_password=(your password)
```
Change the custom environmental folder for your local install
Uncomment ```custom_venv``` and replace it with
```
custom_venv=/home/[user]/virtual/awx
```
or, change it to another appropriate folder.
Run the install playbook
------------------------
```
cd ~awx/installer
ansible-playbook -i inventory install.yml
```
Verify containers are running
-----------------------------
```docker ps```
It should look like this:
```
CONTAINER ID   IMAGE                COMMAND                  CREATED         STATUS         PORTS                                   NAMES
04be3d9bfc6b   ansible/awx:17.0.1   "/usr/bin/tini -- /u…"   8 minutes ago   Up 8 minutes   8052/tcp                                awx_task
11d46e2b7d1e   ansible/awx:17.0.1   "/usr/bin/tini -- /b…"   8 minutes ago   Up 8 minutes   0.0.0.0:80->8052/tcp, :::80->8052/tcp   awx_web
97db08016c14   postgres:12          "docker-entrypoint.s…"   8 minutes ago   Up 8 minutes   5432/tcp                                awx_postgres
7d5f7ac2d4ee   redis                "docker-entrypoint.s…"   8 minutes ago   Up 8 minutes   6379/tcp                                awx_redis
```
Create a superuser
------------------
To be able to sign in, you must create a superuser. 
@reference [Reset Ansible AWX Tower Admin password](http://vcloud-lab.com/entries/devops/reset-ansible-awx-tower-admin-password)
```
docker ps
docker exec -it awx_web bash
awx_manage changepassword admin
exit
```
Sign into your instance
-----------------------
http://example.com
Note: A Handy Way to Wipe you Docker Environment
------------------------------------------------
To clear out your entire environment, use these commands.
```
for i in `docker ps -q`; do docker stop $i; done
docker prune --force
for i in `docker volume ls -q`; do docker volume rm $i; done
for i in `docker image ls -q`; do docker image rm $i; done
```
Then you can start from the ansible-playbook step.
