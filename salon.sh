#! /bin/bash

set -e

db_query() {
  psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet -v ON_ERROR_STOP=1 "$@"
}

sql_quote() {
  local escaped
  escaped=$(printf '%s' "$1" | sed "s/'/''/g")
  printf "'%s'" "$escaped"
}

print_services() {
  local services
  services=$(db_query -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id;")
  printf '%s\n' "$services"
}

printf '\n~~~~~ MY SALON ~~~~~\n\n'
printf 'Welcome to My Salon, how can I help you?\n\n'
print_services

while true; do
  read SERVICE_ID_SELECTED
  SERVICE_EXISTS=false
  if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
    SERVICE_EXISTS=$(db_query -c "SELECT EXISTS (SELECT 1 FROM services WHERE service_id = $SERVICE_ID_SELECTED);")
  fi
  if [[ "$SERVICE_EXISTS" == "t" ]]; then
    break
  fi

  printf '\nI could not find that service. What would you like today?\n'
  print_services
done

SERVICE_NAME=$(db_query -c "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")

printf "\nWhat's your phone number?\n"
read CUSTOMER_PHONE

CUSTOMER_ID=$(db_query -c "SELECT customer_id FROM customers WHERE phone = $(sql_quote "$CUSTOMER_PHONE");")

if [[ -z "$CUSTOMER_ID" ]]; then
  printf "\nI don't have a record for that phone number, what's your name?\n"
  read CUSTOMER_NAME
  CUSTOMER_ID=$(db_query -c "INSERT INTO customers (name, phone) VALUES ($(sql_quote "$CUSTOMER_NAME"), $(sql_quote "$CUSTOMER_PHONE")) RETURNING customer_id;")
else
  CUSTOMER_NAME=$(db_query -c "SELECT name FROM customers WHERE phone = $(sql_quote "$CUSTOMER_PHONE");")
fi

printf "\nWhat time would you like your %s, %s?\n" "$SERVICE_NAME" "$CUSTOMER_NAME"
read SERVICE_TIME

db_query -c "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, $(sql_quote "$SERVICE_TIME"));"

printf '\nI have put you down for a %s at %s, %s.\n' "$SERVICE_NAME" "$SERVICE_TIME" "$CUSTOMER_NAME"
