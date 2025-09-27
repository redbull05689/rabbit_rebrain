docker run --name rabbitmq -e RABBITMQ_DEFAULT_USER=guest -e RABBITMQ_DEFAULT_PASS=guest -p 5672:5672 -p 15672:15672 rabbitmq:3.10-management

```
#!/bin/bash
# Настройки доступа
USER=guest
PASS=guest
HOST=84.201.158.217
PORT=15672

# функция для вызова rabbitmqadmin
r() {
  rabbitmqadmin -u $USER -p $PASS -H $HOST -P $PORT "$@"
}

echo ">>> Создаем очереди..."
r declare queue name=q_billing durable=true
r declare queue name=q_packaging_europe durable=true
r declare queue name=q_packaging_asia durable=true
r declare queue name=q_delivery_msk durable=true
r declare queue name=q_delivery_spb durable=true
r declare queue name=q_delivery_ekb durable=true
r declare queue name=q_delivery_nsb durable=true
r declare queue name=q_delivery_large durable=true
r declare queue name=q_call_center durable=true
r declare queue name=q_monitoring durable=true arguments='{"x-queue-type":"stream"}'
r declare queue name=q_notification durable=true arguments='{"x-message-ttl":3600000}'

echo ">>> Создаем основной exchange x_main (topic)..."
r declare exchange name=x_main type=topic durable=true

echo ">>> Привязываем очереди к x_main..."

# billing
r declare binding source=x_main destination=q_billing routing_key="order.placed"

# packaging europe (Москва, СПб)
r declare binding source=x_main destination=q_packaging_europe routing_key="order.payed" arguments='{"x-match":"any","city":"msk"}'
r declare binding source=x_main destination=q_packaging_europe routing_key="order.payed" arguments='{"x-match":"any","city":"spb"}'
r declare binding source=x_main destination=q_packaging_europe routing_key="order.cancelled" arguments='{"x-match":"any","city":"msk"}'
r declare binding source=x_main destination=q_packaging_europe routing_key="order.cancelled" arguments='{"x-match":"any","city":"spb"}'
r declare binding source=x_main destination=q_packaging_europe routing_key="order.cancelled.returned" arguments='{"x-match":"any","city":"msk"}'
r declare binding source=x_main destination=q_packaging_europe routing_key="order.cancelled.returned" arguments='{"x-match":"any","city":"spb"}'

# packaging asia (Екатеринбург, Новосибирск)
r declare binding source=x_main destination=q_packaging_asia routing_key="order.payed" arguments='{"x-match":"any","city":"ekb"}'
r declare binding source=x_main destination=q_packaging_asia routing_key="order.payed" arguments='{"x-match":"any","city":"nsb"}'
r declare binding source=x_main destination=q_packaging_asia routing_key="order.cancelled" arguments='{"x-match":"any","city":"ekb"}'
r declare binding source=x_main destination=q_packaging_asia routing_key="order.cancelled" arguments='{"x-match":"any","city":"nsb"}'
r declare binding source=x_main destination=q_packaging_asia routing_key="order.cancelled.returned" arguments='{"x-match":"any","city":"ekb"}'
r declare binding source=x_main destination=q_packaging_asia routing_key="order.cancelled.returned" arguments='{"x-match":"any","city":"nsb"}'

# delivery msk
r declare binding source=x_main destination=q_delivery_msk routing_key="order.packaged" arguments='{"x-match":"any","city":"msk"}'
r declare binding source=x_main destination=q_delivery_msk routing_key="order.cancelled" arguments='{"x-match":"any","city":"msk"}'
r declare binding source=x_main destination=q_delivery_msk routing_key="delivery.updateInfo" arguments='{"x-match":"any","city":"msk"}'

# delivery spb
r declare binding source=x_main destination=q_delivery_spb routing_key="order.packaged" arguments='{"x-match":"any","city":"spb"}'
r declare binding source=x_main destination=q_delivery_spb routing_key="order.cancelled" arguments='{"x-match":"any","city":"spb"}'
r declare binding source=x_main destination=q_delivery_spb routing_key="delivery.updateInfo" arguments='{"x-match":"any","city":"spb"}'

# delivery ekb
r declare binding source=x_main destination=q_delivery_ekb routing_key="order.packaged" arguments='{"x-match":"any","city":"ekb"}'
r declare binding source=x_main destination=q_delivery_ekb routing_key="order.cancelled" arguments='{"x-match":"any","city":"ekb"}'
r declare binding source=x_main destination=q_delivery_ekb routing_key="delivery.updateInfo" arguments='{"x-match":"any","city":"ekb"}'

# delivery nsb
r declare binding source=x_main destination=q_delivery_nsb routing_key="order.packaged" arguments='{"x-match":"any","city":"nsb"}'
r declare binding source=x_main destination=q_delivery_nsb routing_key="order.cancelled" arguments='{"x-match":"any","city":"nsb"}'
r declare binding source=x_main destination=q_delivery_nsb routing_key="delivery.updateInfo" arguments='{"x-match":"any","city":"nsb"}'

# delivery large (все города, только крупные заказы)
r declare binding source=x_main destination=q_delivery_large routing_key="order.packaged" arguments='{"x-match":"any","order-size":"large"}'
r declare binding source=x_main destination=q_delivery_large routing_key="delivery.updateInfo" arguments='{"x-match":"any","order-size":"large"}'

# call_center
r declare binding source=x_main destination=q_call_center routing_key="order.status.response"
r declare binding source=x_main destination=q_call_center routing_key="order.packaged"
r declare binding source=x_main destination=q_call_center routing_key="order.cancelled"

# monitoring (все сообщения)
r declare binding source=x_main destination=q_monitoring routing_key="#"

# notification
r declare binding source=x_main destination=q_notification routing_key="order.placed"
r declare binding source=x_main destination=q_notification routing_key="order.payed"
r declare binding source=x_main destination=q_notification routing_key="order.packaged"
r declare binding source=x_main destination=q_notification routing_key="order.cancelled"
r declare binding source=x_main destination=q_notification routing_key="order.delivered"

echo ">>> Проверка..."
r list exchanges
r list queues
r list bindings

echo ">>> Настройка завершена!"
```