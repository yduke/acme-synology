# acme-synolgoy
Get Let's Encrypt SSL certification for Synology NAS automatically.
Cloudflare dns only
Thanks to [acme.sh](https://github.com/acmesh-official/acme.sh)

## How

- Download this repository to your local hard drive.
- Upload and unzip all file to a clear location on you NAS, eg "/volume1/docker/acme"
- Find task on your DSM control panel, create a new "User script task".
- Use root or admin account for this task. Repeat this task every week, or every month.
- Copy and paste the script below to this task, and save this task.

Script:
``  /volume1/docker/acme/issue_and_install.sh 2>&1 ``

Modify ``config`` file, and put your dns provider key.

Try to run this task for the first time, and see result on acme.log.
