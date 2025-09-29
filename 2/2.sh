#!/bin/bash

USER=guest
PASS=guest
HOST=51.250.102.202
PORT=15672

r() {
  rabbitmqadmin -u $USER -p $PASS -H $HOST -P $PORT "$@"
}


# Создаём обменники

r declare exchange name=x_main type=fanout durable=true
r declare exchange name=orders type=topic durable=true
r declare binding source=x_main destination=orders


# Создаём очереди


# Billing
r declare queue name=q_billing durable=true

# Packaging
r declare queue name=q_packaging_europe durable=true
r declare queue name=q_packaging_asia durable=true

# Delivery
r declare queue name=q_delivery_msk durable=true
r declare queue name=q_delivery_spb durable=true
r declare queue name=q_delivery_ekb durable=true
r declare queue name=q_delivery_nsb durable=true
r declare queue name=q_delivery_large durable=true

# Call Center
r declare queue name=q_call_center durable=true

# Monitoring (stream)
r declare queue name=q_monitoring durable=true arguments='{"x-queue-type":"stream"}'

# Notification (TTL 60 минут = 3600000 ms)
r declare queue name=q_notification durable=true arguments='{"x-message-ttl":3600000}'


# Привязки с routing_key и хедерами


cities=("msk" "spb" "ekb" "nsb")
order_sizes=("small" "medium" "large")
cancel_reasons_billing=("not_payed" "payment_cancelled")
cancel_reasons_call_center=("client_request")


# Billing

for city in "${cities[@]}"; do
  r declare binding source=orders destination=q_billing routing_key="order.placed" arguments="{\"x-match\":\"all\",\"city\":\"$city\"}"
  r declare binding source=orders destination=q_billing routing_key="order.billed" arguments="{\"x-match\":\"all\",\"city\":\"$city\"}"
  r declare binding source=orders destination=q_billing routing_key="order.payed" arguments="{\"x-match\":\"all\",\"city\":\"$city\"}"
  for reason in "${cancel_reasons_billing[@]}"; do
    r declare binding source=orders destination=q_billing routing_key="order.cancelled" arguments="{\"x-match\":\"all\",\"city\":\"$city\",\"cancel-reason\":\"$reason\"}"
  done
done


# Packaging

# Европа (msk, spb)
for city in "msk" "spb"; do
  r declare binding source=orders destination=q_packaging_europe routing_key="order.payed" arguments="{\"x-match\":\"all\",\"city\":\"$city\"}"
  r declare binding source=orders destination=q_packaging_europe routing_key="order.cancelled" arguments="{\"x-match\":\"all\",\"city\":\"$city\"}"
  r declare binding source=orders destination=q_packaging_europe routing_key="order.cancelled.returned" arguments="{\"x-match\":\"all\",\"city\":\"$city\"}"
done

# Азия (ekb, nsb)
for city in "ekb" "nsb"; do
  for size in "${order_sizes[@]}"; do
    r declare binding source=orders destination=q_packaging_asia routing_key="order.payed" arguments="{\"x-match\":\"all\",\"city\":\"$city\",\"order-size\":\"$size\"}"
  done
  r declare binding source=orders destination=q_packaging_asia routing_key="order.cancelled" arguments="{\"x-match\":\"all\",\"city\":\"$city\"}"
  r declare binding source=orders destination=q_packaging_asia routing_key="order.cancelled.returned" arguments="{\"x-match\":\"all\",\"city\":\"$city\"}"
done


# Delivery

# Для городов
for city_queue in msk spb ekb nsb; do
  queue="q_delivery_$city_queue"
  r declare binding source=orders destination=$queue routing_key="order.packaged" arguments="{\"x-match\":\"all\",\"city\":\"$city_queue\"}"
  r declare binding source=orders destination=$queue routing_key="order.cancelled" arguments="{\"x-match\":\"all\",\"city\":\"$city_queue\"}"
  r declare binding source=orders destination=$queue routing_key="delivery.updateInfo" arguments="{\"x-match\":\"all\",\"city\":\"$city_queue\"}"
done

# Для крупных заказов
r declare binding source=orders destination=q_delivery_large routing_key="order.packaged"
r declare binding source=orders destination=q_delivery_large routing_key="delivery.updateInfo"


# Call Center

for city in "${cities[@]}"; do
  r declare binding source=orders destination=q_call_center routing_key="order.status.response" arguments="{\"x-match\":\"all\",\"city\":\"$city\"}"
  for reason in "${cancel_reasons_call_center[@]}"; do
    r declare binding source=orders destination=q_call_center routing_key="order.cancelled" arguments="{\"x-match\":\"all\",\"city\":\"$city\",\"cancel-reason\":\"$reason\"}"
  done
done


# Monitoring

r declare binding source=orders destination=q_monitoring routing_key="order.*"


# Notification

r declare binding source=orders destination=q_notification routing_key="order.placed"
r declare binding source=orders destination=q_notification routing_key="order.payed"
r declare binding source=orders destination=q_notification routing_key="order.packaged"
r declare binding source=orders destination=q_notification routing_key="order.cancelled"
r declare binding source=orders destination=q_notification routing_key="order.delivered"
