#!/bin/bash

# Function to check CPU and memory usage
check_usage() {
    echo "CPU Usage:"
    top -b -n 1 | grep "Cpu(s)" | awk '{print $2 + $4 "%"}'
    echo "Memory Usage:"
    free -m | grep Mem | awk '{print $3 " MB used out of " $2 " MB (" $3/$2*100 "%)"}'
}

# Function to list top-consuming processes
list_processes() {
    echo "Top-consuming processes:"
    ps aux --sort=-%cpu,-%mem | head -n 11
}

# Function to configure MySQL database backup
configure_mysql_backup() {
    # Set MySQL credentials
    MYSQL_USER="test"
    MYSQL_PASSWORD="test123"
    MYSQL_DB="test_db"

    # Set backup directory
    BACKUP_DIR="/backup"

    # Backup MySQL database
    mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DB > $BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql

    # Check if backup was successful
    if [ $? -eq 0 ]; then
        echo "MySQL database backup completed successfully."
    else
        echo "Error: MySQL database backup failed."
    fi
}

# Main menu
echo "Welcome to System Monitoring and MySQL Backup Script"
echo "Choose an option:"
echo "1. Check CPU and memory usage"
echo "2. List top-consuming processes"
echo "3. Configure MySQL database backup"
echo "4. Exit"

read -p "Enter your choice: " choice

case $choice in
    1)
        check_usage
        ;;
    2)
        list_processes
        ;;
    3)
        configure_mysql_backup
        ;;
    4)
        echo "Exiting script."
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting script."
        exit 1
        ;;
esac
