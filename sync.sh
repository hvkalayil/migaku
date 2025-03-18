#!/bin/bash

CSV_FILE="projects.csv"

mkdir -p projects

tail -n +2 "$CSV_FILE" | while IFS=',' read -r _ GIT_URL WEB_URL LOCAL_URL; do
    echo -e "\e[1m\e[42m Cloning/Updating $(basename "$GIT_URL" .git) \e[0m"
    echo -e "\t\e[1mWeb: \e[0m$WEB_URL"
    echo -e "\t\e[1mLocal: \e[0m$LOCAL_URL"

    REPO_NAME=$(basename "$GIT_URL" .git)
    if [ -d "projects/$REPO_NAME/.git" ]; then
        echo -e "\t\e[1;34mUpdating existing repository...\e[0m"
        (cd "projects/$REPO_NAME" && git pull --quiet)
    else
        echo -e "\t\e[1;32mCloning new repository...\e[0m"
        (cd projects && git clone --quiet "$GIT_URL")
    fi

done