Задание
Запустить контейнер RabbitMQ в Docker, открыть порты 5672, 15672. Пользователь - admin, пароль - ADMINadmin. Подключиться к админке rabbitmq по адресу %адрес%:15672.

В контейнере создать очереди

q_process_jpg
q_process_pdf
Создать exchange с названием files_exchange. Тип – headers. Привязать очереди к exchange по header File-Type. Routing key = process.file

File-Type == jpg – q_process_jpg
File-Type == jpeg – q_process_jpg
File-Type == pdf – q_process_pdf
Создать exchange с названием message_exchange. Тип – topic.

Очереди:

q_process
q_email
q_backend
Routing keys:

Начинается на process (например, process.file.add_page) - q_process
api стоит на втором месте (например, email.api.success) -> q_backend
email.get_messages и email.send -> q_email


===================================================

docker run --name rabbitmq -e RABBITMQ_DEFAULT_USER=admin -e RABBITMQ_DEFAULT_PASS=ADMINadmin -p 5672:5672 -p 15672:15672 rabbitmq:3.10-management


Запустить внутри контейнера
```
#!/bin/bash
# Настройки доступа

USER=admin
PASS=ADMINadmin
HOST=localhost
PORT=15672

# функция
r() {
  rabbitmqadmin -u $USER -p $PASS -H $HOST -P $PORT "$@"
}

echo ">>> Создаем очереди..."
r declare queue name=q_process_jpg durable=true
r declare queue name=q_process_pdf durable=true
r declare queue name=q_process durable=true
r declare queue name=q_email durable=true
r declare queue name=q_backend durable=true

echo ">>> Создаем exchange files_exchange (headers)..."
r declare exchange name=files_exchange type=headers durable=true

echo ">>> Привязываем очереди к files_exchange..."
r declare binding source=files_exchange destination=q_process_jpg \
  arguments='{"x-match":"any","File-Type":"jpg"}'
r declare binding source=files_exchange destination=q_process_jpg \
  arguments='{"x-match":"any","File-Type":"jpeg"}'
r declare binding source=files_exchange destination=q_process_pdf \
  arguments='{"x-match":"any","File-Type":"pdf"}'

echo ">>> Создаем exchange message_exchange (topic)..."
r declare exchange name=message_exchange type=topic durable=true

echo ">>> Привязываем очереди к message_exchange..."
r declare binding source=message_exchange destination=q_process routing_key="process.#"
r declare binding source=message_exchange destination=q_backend routing_key="*.api.*"
r declare binding source=message_exchange destination=q_email routing_key="email.get_messages"
r declare binding source=message_exchange destination=q_email routing_key="email.send"

echo ">>> Проверка..."
r list exchanges
r list queues
r list bindings

echo ">>> Настройка завершена!"

```

