#!/bin/bash

DATABASE=""
USERNAME=""
PASSWORD=""

help()
{
    echo "This script sets up SSH, installs MDSD and runs the DB bootstrap"
    echo "Options:"
    echo "        --database Name of guacamole database"
    echo "        --username Username of guacamole database"
    echo "        --password Password of guacamole database"
}

parse_args()
{
    while [[ "$#" -gt 0 ]]
    do

        arg_value="${2}"
        shift_once=0

        if [[ "${arg_value}" =~ "--" ]]; 
        then
            arg_value=""
            shift_once=1
        fi

         # Log input parameters to facilitate troubleshooting
        echo "Option '${1}' set with value '"${arg_value}"'"

        case "$1" in
            --database)
                DATABASE="${arg_value}"
                ;;
            --username)
                USERNAME="${arg_value}"
                ;;
            --password)
                PASSWORD="${arg_value}"
                ;;
            -h|--help)  # Helpful hints
                help
                exit 2
                ;;
            *) # unknown option
                echo "Option '${BOLD}$1${NORM} ${arg_value}' not allowed."
                help
                exit 2
                ;;
        esac

        shift # past argument or value

        if [ $shift_once -eq 0 ]; 
        then
            shift # past argument or value
        fi
    done
}

# parse script arguments
parse_args $@

# If /root/.my.cnf exists then it won't ask for root password
if [ -f /root/.my.cnf ]; then
    
    sudo mysql -e "CREATE DATABASE ${DATABASE};"
    sudo mysql -e "CREATE USER ${DATABASE}@'%' IDENTIFIED BY '${PASSWORD}';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON ${DATABASE}.* TO '${DATABASE}''@'%';"
    sudo mysql -e "GRANT SELECT, INSERT, UPDATE, DELETE ON ${DATABASE}.* TO '${DATABASE}''@'%';"
    sudo mysql -e "FLUSH PRIVILEGES;"

# If /root/.my.cnf doesn't exist then it'll ask for root password   
else
    echo "Please enter root user MySQL password!"
    echo "Note: password will be hidden when typing"
    read -sp rootpasswd

    sudo mysql -u root -p${rootpasswd} -e "CREATE DATABASE ${DATABASE};"
    sudo mysql -u root -p${rootpasswd} -e "CREATE USER ${DATABASE}@'%' IDENTIFIED BY '${PASSWORD}';"
    sudo mysql -u root -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${DATABASE}.* TO '${DATABASE}''@'%';"
    sudo mysql -u root -p${rootpasswd} -e "GRANT SELECT, INSERT, UPDATE, DELETE ON ${DATABASE}.* TO '${DATABASE}''@'%';"
    sudo mysql -u root -p${rootpasswd} -e "FLUSH PRIVILEGES;"

fi