#!/bin/bash

echo
echo

if ! command -v python3 &> /dev/null;
then
    echo Python3 is not installed
    exit 1
fi

cd "$(dirname "$0")" || exit

if [ ! -d "venv" ];
then
    echo Creating virtual environment
    python3 -m venv venv

    . venv/bin/activate

    echo Installing dependencies
    command pip3 install -r requirements.txt --upgrade

    # Creating environemnt file
    if [[ ! -e .env ]]; then
        touch -c .env
        echo "DB_NAME='your db name'\nDB_USER='your db username'\nDB_PASSWORD='your db password'\nDB_HOST='your db host'\nDB_PORT=5432\nSECRET_KEY='your secret key'\nDEBUG=false\nLOG_LEVEL=INFO" > .env
    fi    

    echo
    echo

    echo "Please enter your Postgres database information in the file '.env' now."
    echo You can use this generated key as your SECRET_KEY if you want:
    #generating a secret key
    secret_key="$(openssl rand -hex 36)"

    #printing the secret key
    echo "Secret key: $secret_key"

    # echo Press any key to continue
    echo
    read -n1 -s -r -p $'Press any key to continue...\n' key
    echo
    echo Running migrations for site
    command piccolo migrations forwards user
    command piccolo migrations forwards session_auth
    for d in */; do
        if [ -f "$d/tables.py" ]; then
            command piccolo migrations new "${d%/}" --auto
            command piccolo migrations forwards "${d%/}"
        fi
    done    ## create admin user
    echo
    echo Assuming this is the first run... Creating new user...
    command piccolo user create

else
    echo
    echo Activating virtual environment
    . venv/bin/activate
fi

if [ "$1" = "--install" ];
then
    shift
    echo
    echo Installing dependencies
    command pip3 install -r requirements.txt --upgrade
    ## runing migrations for site
    # command piccolo migrations forwards user
    # command piccolo migrations forwards session_auth
    # for d in */; do
    #     if [ -f "$d/tables.py" ]; then
    #         echo piccolo migrations for "${d%/}"
    #         command piccolo migrations new "${d%/}" --auto
    #         command piccolo migrations forwards "${d%/}"
    #     fi
    # done    ## create admin user
    echo 
    echo To install a new user, run: piccolo user create
fi

if [ "$1" = "--migrate" ];
then
    shift
    echo
    echo Migrating databases
    echo WARNING: This is automated. If there is an issue, you will have to reverse the migration.
    echo
    ## runing migrations for site
    command piccolo migrations forwards user
    command piccolo migrations forwards session_auth
    for d in */; do
        if [ -f "$d/tables.py" ]; then
            echo piccolo migrations new "${d%/}"
            command piccolo migrations new "${d%/}" --auto
        fi
    done
    for d in */; do
        if [ -f "$d/tables.py" ]; then
            echo piccolo migrations forwards "${d%/}"
            command piccolo migrations forwards "${d%/}"
        fi
    done


fi

echo
echo
echo
echo Starting Server with args: "$@"
# python3 main.py "$@"
uvicorn app:app --port 8000 --host 0.0.0.0 "$@" 
