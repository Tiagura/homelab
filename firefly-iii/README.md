# Firefly III Docker Setup with Rclone Backup

This project sets up **Firefly III**, a personal finance manager, using **Docker** and **Rclone** for automated backups of your Firefly III data.

## Folder Structure

Here is the folder structure of the project:

```
firefly-iii
├── backup_firefly.sh
├── .db.env
├── docker-compose.yml
├── .env
└── firefly-iii-backuper.sh
```

## Requirements

Before setting up this project, ensure you have the following:

- **Docker** installed on your machine. You can find installation instructions on the official Docker page: [Docker Installation Guide](https://docs.docker.com/engine/install/).
- **Rclone** installed on your Docker host. Rclone is used to back up your Firefly III data to other storage. You can install it on Linux using the following command:

  ```
  sudo apt install -y rclone
  ```

  For other install methods, you can refer to the official Rclone documentation: [Rclone Install Guide](https://rclone.org/install/). Note that other methods of installing Rclone may result in different configurations or usage patterns, and you may need to make adjustments to this setup depending on how Rclone is installed and configured.
  
- **Rclone Configuration**: After installation, you need to configure Rclone for your chosen cloud storage provider. For guidance on setting up your storage, refer to the [Rclone Overview](https://rclone.org/overview/).
  
  Ensure that Rclone is correctly configured with access to your cloud storage before proceeding with the backup setup.

## Setup Steps

### 1. Clone the Repository

Get this folder to your target machine

### 2. Modify `.env` and `.db.env` Files

To configure your Firefly III and database settings, you need to modify the following files:

#### In the `.env` file:

```
SITE_OWNER=<your_email>                                     # Set this to your email address.
APP_KEY=<app_key>                                           # Change this to a string of exactly 32 characters. Avoid using the `#` character as it may break things.
TZ=<timezone>                                               # Set this to your time zone (e.g., `America/New_York`).
TRUSTED_PROXIES=                                            # Leave this undefined or set it to `**` if using a reverse proxy.
DB_DATABASE=<database_name>                                 # Set this to the value of `MYSQL_DATABASE` in the `.db.env` file.
DB_USERNAME=<database_user>                                 # Set this to the value of `MYSQL_USER` in the `.db.env` file.
DB_PASSWORD=<database_pwd>                                  # Set this to the value of `MYSQL_PASSWORD` in the `.db.env` file.
STATIC_CRON_TOKEN=<generated_token>                         # Generate a token with 32-characters and set it here.
APP_URL=<url used for access .i.e http://{IP or DNS Name}>  # Set this to the URL used to access your Firefly III instance.
```

In addition to these required variables, you can modify other optional variables in the `.env` file to fit your specific needs. These may include settings related to email configuration, logging, and more.

#### In the `.db.env` file:

```
MYSQL_USER=<database_user>      # The database username.
MYSQL_PASSWORD=<database_pwd>   # The database password.
MYSQL_DATABASE=<database_name>  # The name of the Firefly III database.
```

Make sure these values are consistent between both files.

### 4. Running the Docker Containers

Once you've configured the `.env` and `.db.env` files, you can start the Firefly III container and PostgreSQL database using Docker Compose:

```
docker-compose up -d
```

## Backup Process

The backup process follows the guidelines provided in the official Firefly III documentation for [Automated backup using a bash script and crontab](https://docs.firefly-iii.org/how-to/firefly-iii/advanced/backup/). The backup relies on two scripts: `firefly-iii-backuper.sh` and `backup-firefly.sh`. 

- **`firefly-iii-backuper.sh`** is responsible for compressing and backing up Firefly III data, including the database and files. It also supports restoring from backups. You can find this script [here](https://gist.github.com/dawid-czarnecki/8fa3420531f88b2b2631250854e23381).
- **`backup-firefly.sh`** manages the execution of the backup process, uploads the backup to cloud storage via Rclone, and deletes old backups. 

The backup itself is executed through the `backup-firefly.sh` script, which is responsible for running the `firefly-iii-backuper.sh` script, uploading the resulting backup to the remote storage, and managing old backups.

In the `backup-firefly.sh` script, you need to modify the following key variables:

```
WORK_DIR="/path/to/firefly-iii/"            # Working dir
RCLONE_REMOTE="remote:/backups/firefly"     # Rclone destination path, change the 'remote' name for the name of your remote storage in rclone 
MAX_BACKUPS=3                               # Maximum number of backups to keep on your remote storage
```

Make sure to set these according to your setup (directory, Rclone destination, and max backups).

### Automating the Backup Process

To ensure that your backup happens regularly, you can automate the process by creating a **cron job**. This will run the backup script at a specified interval, such as daily or weekly, without manual intervention.

#### Setting up a Cron Job

1. Open the **crontab** configuration by running the following command:
   ```bash
   crontab -e
   ```
   
2. Add a new line to schedule the backup. For example, to run the backup script every day at 7:15 AM, add the following line:
   ```bash
   15 7 * * * path/to/firefly-iii/backup_firefly.sh >> path/to/firefly-iii/backup_firefly.log 2>&1
   ```
