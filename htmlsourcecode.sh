mkdir -p headers responsebody
CURRENT_PATH=$(pwd)
for x in $(cat "$1"); do
    NAME=$(echo "$x" | awk -F/ '{print $3}')
    curl -s -I -H "X-Forwarded-For: evil.com" --connect-timeout 10 "$x" > "$CURRENT_PATH/headers/$NAME"
    curl -s -L -H "X-Forwarded-For: evil.com" --connect-timeout 10 "$x" > "$CURRENT_PATH/responsebody/$NAME"
done
