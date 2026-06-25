#!/bin/bash

set -e

JSON_FILE="projects.json"

mkdir -p projects

# 🔐 Prompt for encryption key once
read -s -p "Enter encryption key: " ENCRYPTION_KEY
echo

# 🧙‍♂️ Summoning rune-keeper
if [ -d "rune-keeper/.git" ]; then
  echo -e "\t\e[1;34mUpdating Rune Keeper...\e[0m"

  (
    cd rune-keeper \
      && git pull --quiet
  )
else
  echo -e "\t\e[1;32mCloning Rune Keeper...\e[0m"

  git clone --quiet https://github.com/hvkalayil/rune-keeper.git
fi

# 🔁 Loop through JSON
jq -c '.[]' "$JSON_FILE" | while read -r PROJECT; do

  # Remove possible CRLF characters
  PROJECT=$(echo "$PROJECT" | tr -d '\r')

  GIT_URL=$(echo "$PROJECT" | jq -r '.git_url')
  WEB_URL=$(echo "$PROJECT" | jq -r '.web_url')
  LOCAL_URL=$(echo "$PROJECT" | jq -r '.local_url')

  REPO_NAME=$(basename "$GIT_URL" .git)

  echo
  echo -e "\e[1m\e[42m Cloning/Updating $REPO_NAME \e[0m"
  echo -e "\t\e[1mWeb:\e[0m   $WEB_URL"
  echo -e "\t\e[1mLocal:\e[0m $LOCAL_URL"

  # 📦 Clone or update repo
  if [ -d "projects/$REPO_NAME/.git" ]; then

    echo -e "\t\e[1;34mUpdating existing repository...\e[0m"

    (
      cd "projects/$REPO_NAME" \
        && git pull --quiet
    )

  else

    echo -e "\t\e[1;32mCloning new repository...\e[0m"

    (
      cd projects \
        && git clone --quiet "$GIT_URL"
    )

  fi

  # 🗝️ Decrypt env files
  if echo "$PROJECT" | jq -e '.env_files' > /dev/null 2>&1; then

    echo -e "\t\e[1;35mDecrypting environment files...\e[0m"

    echo "$PROJECT" \
      | jq -r '.env_files[]?' \
      | tr -d '\r' \
      | while read -r ENV_FILE; do

        [ -z "$ENV_FILE" ] && continue

        ENCRYPTED_FILE="rune-keeper/$REPO_NAME/$ENV_FILE.enc"
        TARGET_FILE="projects/$REPO_NAME/$ENV_FILE.env"

        echo -e "\t\e[36mEncrypted:\e[0m $ENCRYPTED_FILE"
        echo -e "\t\e[36mTarget:\e[0m    $TARGET_FILE"

        if [ -f "$ENCRYPTED_FILE" ]; then

          mkdir -p "$(dirname "$TARGET_FILE")"

          openssl enc -aes-256-cbc -d -pbkdf2 \
            -in "$ENCRYPTED_FILE" \
            -out "$TARGET_FILE" \
            -k "$ENCRYPTION_KEY"

          echo -e "\t\e[1;32m✓ Decrypted $ENV_FILE\e[0m"

        else

          echo -e "\t\e[1;31m✗ Missing encrypted file: $ENCRYPTED_FILE\e[0m"

        fi

      done
  fi

done

echo
echo -e "\e[1;32mAll projects processed successfully.\e[0m"