while read -r domain; do
    curl -s "https://$domain" > "responsebody/$domain"
done < domains.txt
