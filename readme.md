# Laravel Setup Script for DigitalOcean

This repo contains a Bash script to help you set up and deploy Laravel projects on a DigitalOcean droplet (Ubuntu). The script automates the process of configuring your server with PHP, Nginx, MySQL, Composer, and Git, while creating a reliable deployment 
structure.

## The Idea

The plan is to create one script that sets up everything you need on a DigitalOcean droplet for your Laravel project. Just run this script, and it configures the server and gets your project up and running.

When you want to make updates later, you should only need to run one command to deploy the new version, with no downtime.


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

This script is a solid starting point for Laravel deployment on DigitalOcean, with room for more features to make it production-ready.
