#!/bin/bash/

set -e

if [ $# -lt 1 ] || [ "$1" != "--filename" ]; then
  echo "Ошибка: Не указан обязательный аргумент --filename"
  exit 1
fi

filename=$2

if [[ $filename != *".csv" ]]; then
    echo "Error, file isn't .csv"
    exit 1
fi    

while IFS=, read -r username groups; do
  username=$(echo "$username" | tr ',' '_')
  if ! id -u "$username" >/dev/null 2>&1; then
    password=$(date +%s | sha256sum | base64 | head -c 12)
    useradd -m -p "$password" "$username"
  fi

  for group in $(echo "$groups" | tr ',' ' '); do
    group=$(echo "$group" | sed 's/[^a-zA-Z0-9_-]//g')
    if [ "$group" = "backup" ]; then
       backup_dir="/backup/$username"
       mkdir -p "$backup_dir"
       tar -czf "$backup_dir/$username-$(date +\%Y\%m\%d).tar.gz" -C "/home/$username"

       (crontab -l ; echo "0 0 * * * tar -czf \"$backup_dir/$username-$(date +\%Y\%m\%d).tar.gz\" -C \"/home/$username\" .") | crontab -
    fi
    if [ -n "$group" ] && ! getent group "$group" >/dev/null 2>&1; then
      groupadd "$group"
    fi
    if [ -n $"group" ]; then
      usermod -a -G "$group" "$username"
    fi
  done
  timestamp=$(date +"%d/%m/%y:%H:%M")
  echo "[$timestamp] $username был создан и добавлен в группу $groups"
done < "$filename"









 