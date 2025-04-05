#!/bin/bash

CSV_FILE="projects.csv"

mkdir -p projects

# 🔐 Prompt for encryption key once
read -s -p "Enter encryption key: " ENCRYPTION_KEY
echo

# 🧙‍♂️ Summoning rune-keeper
if [ -d "rune-keeper" ]; then
    echo -e "\t\e[1;34mUpdating Rune Keeper...\e[0m"
    cd rune-keeper && git pull --quiet && cd ../
else
    echo -e "\t\e[1;32mCloning Rune Keeper...\e[0m"
    git clone --quiet https://github.com/hvkalayil/rune-keeper.git
fi

# 🔁 Loop through the CSV file
tail -n +2 "$CSV_FILE" | while IFS=',' read -r _ GIT_URL WEB_URL LOCAL_URL ENV_FILES; do
    echo -e "\e[1m\e[42m Cloning/Updating $(basename "$GIT_URL" .git) \e[0m"
    echo -e "\t\e[1mWeb: \e[0m$WEB_URL"
    echo -e "\t\e[1mLocal: \e[0m$LOCAL_URL"

    # 🛠️ Create the project
    REPO_NAME=$(basename "$GIT_URL" .git)
    if [ -d "projects/$REPO_NAME/.git" ]; then
        echo -e "\t\e[1;34mUpdating existing repository...\e[0m"
        (cd "projects/$REPO_NAME" && git pull --quiet)
    else
        echo -e "\t\e[1;32mCloning new repository...\e[0m"
        (cd projects && git clone --quiet "$GIT_URL")
    fi

    # 🗝️ Decrypt .env files if listed in CSV
    if [ -n "$ENV_FILES" ]; then
        echo -e "\t\e[1;35mDecrypting environment files...\e[0m"
        for ENV_FILE in $(echo "$ENV_FILES" | tr ';' ' '); do
            ENCRYPTED_FILE="rune-keeper/$REPO_NAME/$ENV_FILE.enc"
            TARGET_FILE="projects/$REPO_NAME/$ENV_FILE"
            if [ -f "$ENCRYPTED_FILE" ]; then
                openssl enc -aes-256-cbc -d -pbkdf2 -in "$ENCRYPTED_FILE" -out "$TARGET_FILE" -k "$ENCRYPTION_KEY"
                echo -e "\t\e[1;32mDecrypted $ENV_FILE\e[0m"
            else
                echo -e "\t\e[1;31mEncrypted file $ENV_FILE.enc not found\e[0m"
            fi
        done
    fi

done