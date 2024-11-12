# Laravel Setup Script for DigitalOcean

This repo contains a Bash script to help you set up and deploy Laravel projects on a DigitalOcean droplet (Ubuntu). The script automates the process of configuring your server with PHP, Nginx, MySQL, Composer, and Git, while creating a reliable deployment 
structure.

## The Idea

The plan is to create one script that sets up everything you need on a DigitalOcean droplet for your Laravel project. Just run this script, and it configures the server and gets your project up and running.

When you want to make updates later, you should only need to run one command to deploy the new version, with no downtime.


## What the script does

- Provision a new DigitalOcean droplet with a supported Ubuntu version (e.g., 24.04 Noble, compatible with [ppa:ondrej/php](https://launchpad.net/~ondrej/+archive/ubuntu/php)).
- Download the setup script: `wget https://raw.githubusercontent.com/lucidpolygon/laravel-deployment-script/main/setup.sh`
- Make the script executable: `chmod +x setup.sh`
- Open the script and update details as needed, including Project Name, Database credentials, and Project Repository URL using a fine-grain access token.
- Run the setup script: `./setup.sh`
- The script will create a config file at `/etc/laravel-deploy/config.sh`, used for initial setup and future deployments.
- The script installs PHP, related packages, Node.js, NPM, and configures Nginx according to Laravel’s requirements.
- The script will create deployment structures.
    - root (Laravel)
        - shared (The shared folder will contain the .env file and storage directory, both shared across all releases.)
        - releases (keeps upto 5 last versions of the project)
- It clones the project repository into a releases folder inside the initial directory, installs dependencies, and builds assets with npm run prod.
- If the storage folder exists in Git, it will be moved to shared; otherwise, new storage folders will be created.
- Sets correct permissions for all project folders.
- Copies the .env.example file to the shared folder. You will have to update this with your correct .env
- Creates initial symlinks from the shared folder to the initial folder.
- Marks the initial release as the current active version by symlinking the intial folder to current folder.
- Creates a deployment script at `/usr/local/bin/deploy-laravel` for future deployments. This script:
    - Uses config variables from `/etc/laravel-deploy/config.sh`.
    - Creates a new timestamped folder inside releases.
    - Clones the GitHub repository, installs dependencies, and builds assets.
    - Links the shared .env and storage resources.
    - Removes the newly cloned storage directory to continue using the original shared one.
    - Optimizes Laravel and switches to the new release (atomic switch).
    - Retains only the latest five releases in releases.
    - Restarts PHP-FPM.
- Makes this deployment script executable so that running `deploy-laravel` will launch the new version.
- Adds a rollback script in `/usr/local/bin/rollback-laravel` to restore the previous release if needed. This script:
    - Identifies and switches to the previous release.
    - Restarts PHP and Nginx.
- Makes the rollback script executable, allowing rollback-laravel to switch back to the previous live version.
- Setup is complete; ensure .env is updated with real values and run php artisan optimize to launch the project.


## Laravel Documentation

https://laravel.com/docs/11.x/deployment#server-requirements

## Features

- **Nginx Setup**: Configures Nginx as the web server.
- **PHP Install**: Installs PHP with required extensions.
- **Composer**: Installs Composer and sets up dependencies.
- **MySQL Setup**: Installs MySQL and creates a database user.
- **PHP Tweaks**: Adjusts PHP settings for Laravel performance.
- **Deployment Structure**: Sets up a release system for zero-downtime deployments.
- **Shared Directories**: Creates shared folders for the `.env` file and storage.
- **Permissions**: Sets secure permissions for files and directories.
- **Deployment Script**: Adds a reusable `deploy-laravel` script for future updates.
- **Initial `.env` File**: Copies an example `.env` to get you started.
- **Symlinks**: Links shared resources to the current release.
- **Activate First Release**: Marks the initial release as live.

## Planned Improvements

- **.env Updates**: Add a way to safely compare and update the `.env` file.
- **Staging Support**: Set up a staging environment alongside production.
- **DB Management**: Include a database GUI like Adminer or phpMyAdmin.
- **Backups**: Automate file and database backups.
- **Error Logs**: Improve logging and error handling.
- **Domain Config**: Add domain and SSL setup steps.
- **Setup Firewalls**: Add a firewall