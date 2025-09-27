#!/bin/bash
# Настройки доступа
USER=guest
PASS=guest
HOST=89.169.159.219
PORT=15672

# функция для вызова rabbitmqadmin
r() {
  rabbitmqadmin -u $USER -p $PASS -H $HOST -P $PORT "$@"
}

r declare exchange name=orders type=topic durable=true

r declare queue name=ordering durable=true
r declare queue name=billing durable=true
r declare queue name=packaging durable=true
r declare queue name=delivery durable=true
r declare queue name=call_center durable=true
r declare queue name=monitoring durable=true
r declare queue name=notification durable=true


r declare binding source=orders destination=billing routing_key="order.created"
r declare binding source=orders destination=monitoring routing_key="order.*"
r declare binding source=orders destination=notification routing_key="order.*"


r declare binding source=orders destination=packaging routing_key="order.paid"
r declare binding source=orders destination=monitoring routing_key="order.*"
r declare binding source=orders destination=notification routing_key="order.*"


r declare binding source=orders destination=call_center routing_key="order.packed"
r declare binding source=orders destination=monitoring routing_key="order.*"
r declare binding source=orders destination=notification routing_key="order.*"

r declare binding source=orders destination=delivery routing_key="order.confirmed"

r declare binding source=orders destination=delivery routing_key="order.updated"
r declare binding source=orders destination=monitoring routing_key="order.*"
r declare binding source=orders destination=notification routing_key="order.*"

r declare binding source=orders destination=delivery routing_key="order.confirmed"

r declare binding source=orders destination=monitoring routing_key="order.delivered"
r declare binding source=orders destination=notification routing_key="order.delivered"

r declare binding source=orders destination=packaging routing_key="order.returned"
r declare binding source=orders destination=monitoring routing_key="order.returned"
r declare binding source=orders destination=notification routing_key="order.returned"

r declare binding source=orders destination=monitoring routing_key="order.*"

r declare binding source=orders destination=notification routing_key="order.*"

for q in billing packaging delivery call_center monitoring notification; do
  r declare binding source=orders destination=$q routing_key="order.canceled"
done

echo "Инфраструктура RabbitMQ для бизнес-процесса заказов настроена!"
