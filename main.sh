#!/bin/bash

# Configuration
API_KEY="your_cloudflare_api_key"
ZONE_ID="your_zone_id"
RECORDS=("subdomain1.example.com" "subdomain2.example.com" "subdomain3.example.com")

# Get current IP address using upnpc
CURRENT_IP=$(upnpc -s | awk -F'= ' '/ExternalIPAddress/ { print $2 }')
echo "Current IP: $CURRENT_IP"

# Function to update DNS record
update_record() {
    local record="$1"
    local record_id=$(curl --request GET \
        --url "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$record" \
        --header "Content-Type: application/json" \
        --header "Authorization: Bearer $API_KEY" \
        | jq -r '.result[0].id')

    if [ "$record_id" != "null" ] && [ -n "$record_id" ]; then
        echo "Found existing record $record with ID $record_id"
        curl --request PUT \
            --url https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$record_id \
            --header "Content-Type: application/json" \
            --header "Authorization: Bearer $API_KEY" \
            --data "{\"content\":\"$CURRENT_IP\",\"name\":\"$record\",\"proxied\":false,\"type\":\"A\",\"ttl\":3600}"
        echo "Updated $record to $CURRENT_IP"
    else
        echo "No A record found for $record, creating a new one"
        curl --request POST \
            --url https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records \
            --header "Content-Type: application/json" \
            --header "Authorization: Bearer $API_KEY" \
            --data "{\"content\":\"$CURRENT_IP\",\"name\":\"$record\",\"proxied\":false,\"type\":\"A\",\"ttl\":3600}"
        echo "Created A record for $record with IP $CURRENT_IP"
    fi
}

# Update DNS records
for record in "${RECORDS[@]}"; do
    update_record "$record"
done
