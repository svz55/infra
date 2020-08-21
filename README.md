# svz55_infra [svz55 Infra repository](https://github.com/svz55/infra)

##   Travis 
```
travis whoami -t 727Sg38Qxk3vbIvssrEZ3g
travis login --github-token  727Sg38Qxk3vbIvssrEZ3g
travis encrypt "svz55:hkwrYXJ6HDqWdaWUSthX8fzT#travis_ci"  --add notifications.slack.rooms --org
```

## Google cloud ssh-keygen name file appuser
```
ssh -i ~/.ssh/appuser appuser@35.208.19.130
```

## HW 5 (VPN)

### Подключение к someinternalhost одной командой:
Вариант №1: Можно указывать все необходимые параметры при каждом подключении:
```
ssh -i ~/.ssh/appuser <internal-host> -o "ProxyCommand ssh appuser@<bastion> -W %h:%p"
```
e.g.
```
ssh -i ~/.ssh/appuser 10.132.0.3 -o "ProxyCommand ssh appuser@35.210.37.87 -W %h:%p"
```
-W Requests that standard input and output on the client be forwarded to host on port over the secure channel.
-o Can be used to give options in the format used in the configuration file.
-i Selects a file from which the identity (private key) for public key authentication is read.

Вариант №2: Добавить информацию о бастионе и внутреннем узле в ~/.ssh/config:
```
Host 35.210.37.87
    User appuser
    IdentityFile ~/.ssh/appuser

Host 10.132.*
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyCommand ssh appuser@35.210.37.87 -W %h:%p
```
- В данном примере подключение к любому узлу из 10.132.0.0/16 (Host 10.132.*) перенаправляется через 35.210.37.87.

### Подключение по алиасу
В дополнение к предыдущей конфигурации, можно назначить алиас конкретному узлу:
```
Host someinternalhost
    Hostname 10.132.0.3
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyCommand ssh appuser@35.210.37.87 -W %h:%p
```

### Ещё одна вариация ~/.ssh/config
Как вариант, можно определить алиас для bastion и ссылаться на него при описании внутренних узлов - в таком случае не нужно постоянно ссылаться на identity bastion'а:
```
Host bastion
    Hostname 35.210.37.87
    User appuser
    IdentityFile ~/.ssh/appuser

Host 10.132.*
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyCommand ssh bastion -W %h:%p

Host someinternalhost
    Hostname 10.132.0.3
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyCommand ssh bastion -W %h:%p
```

### Информация о подключении к VPN
```
bastion_IP = 35.210.37.87
someinternalhost_IP = 10.132.0.3
```

## HW 6 (GCP, cloud-testapp)

Проверить установку и настройку gcloud можно, используя
команду gcloud info или gcloud auth list

### Создаем новый инстанс

[Ссылка на gist с командой](https://gist.githubusercontent.com/Nklya/5bc429c6ca9adce1f7898e7228788fe5/raw/01f9e4a1bf00b4c8a37ca6046e3e4d4721a3316a/gcloud)
   
```
    $ gcloud compute instances create reddit-app \
    --boot-disk-size=10GB \
    --image-family ubuntu-1604-lts \
    --image-project=ubuntu-os-cloud \
    --machine-type=g1-small \
    --tags puma-server \
    --restart-on-failure
```

#### инстанс с уже запущенным приложением
#### startup скрипт необходимо как дополнительная  опция уcloud. 
```
gcloud compute instances create reddit-app 
    --boot-disk-size=10GB --image-family ubuntu-1604-lts 
    --image-project=ubuntu-os-cloud --machine-type=g1-small 
    --tags puma-server 
    --restart-on-failure 
    --metadata-from-file startup-script=install_all.sh
```

### Скрипты для настройки системы и деплоя приложения
Здесь, в общем-то, ничего не обычного - просто список команд в .sh файлах 
packer/scripts 
(install_ruby.sh, install_mongodb.sh, deploy.sh)

### Дополнительное задание: startup-script
Ключевые моменты:
- startup-скрипты запускаются от root'а (https://cloud.google.com/compute/docs/startupscript#startup_script_execution), соответственно нужно держать в голове, что и от чьего имени мы хотим исполнить. Для исполнения команд от имени другого пользователя подойдет runuser или su (https://www.cyberciti.biz/open-source/command-line-hacks/linux-run-command-as-different-user/). Пример:
```
runuser -l appuser -c 'git clone -b monolith https://github.com/express42/reddit.git'
runuser -l appuser -c 'cd reddit && bundle install'
runuser -l appuser -c 'cd reddit && puma -d'
```
```
appuser@reddit-app:~$ ps aux | grep 9292
appuser   9434  1.0  1.5 513788 26876 ?        Sl   21:53   0:00 puma 3.10.0 (tcp://0.0.0.0:9292) [reddit]
appuser   9459  0.0  0.0  12916  1088 pts/0    S+   21:54   0:00 grep --color=auto 9292
```
- обработчик startup-скриптов не поддерживает не-ascii символы - в /var/log/syslog сыпалось множество ошибок, когда я в скрипте оставил комментарии на русском;
- отслеживать выполнение startup-скрипта можно в /var/log/syslog
```
tail -f /var/log/syslog
Mar 27 21:53:34 reddit-app systemd[1]: Started Session c3 of user appuser.
Mar 27 21:53:34 reddit-app startup-script: INFO startup-script:   Puma starting in single mode...
Mar 27 21:53:34 reddit-app startup-script: INFO startup-script: * Version 3.10.0 (ruby 2.3.1-p112), codename: Russell's Teapot
Mar 27 21:53:34 reddit-app startup-script: INFO startup-script: * Min threads: 0, max threads: 16
Mar 27 21:53:34 reddit-app startup-script: INFO startup-script: * Environment: development
Mar 27 21:53:34 reddit-app startup-script: INFO startup-script: * Daemonizing...
Mar 27 21:53:34 reddit-app startup-script: INFO startup-script: Return code 0.
Mar 27 21:53:34 reddit-app startup-script: INFO Finished running startup scripts.
Mar 27 21:53:34 reddit-app systemd[1]: Started Google Compute Engine Startup Scripts.
Mar 27 21:53:34 reddit-app systemd[1]: Startup finished in 2.857s (kernel) + 1min 31.747s (userspace) = 1min 34.605s.
```
- скрипт может храниться локально на машине с gcloud-клиентом (startup-script=), в bucket на Google Cloud Storage (startup-script-url=), в метаданных instance, а также может быть передан в виде текста. В качестве дополнительного параметра к gcloud также необходимо указать "--metadata-from-file".
```
gcloud compute instances create reddit-app --boot-disk-size=10GB --image-family ubuntu-1604-lts --image-project=ubuntu-os-cloud --machine-type=g1-small --tags puma-server --restart-on-failure --metadata-from-file startup-script=install_all.sh
```

### Дополнительное задание: создание firewall rule через gcloud
```
gcloud compute firewall-rules create default-puma-server --action=allow --rules tcp:9292 --direction=ingress --target-tags=puma-server
```
Source-сеть нет необходимости указывать явно - 0.0.0.0/0 - значение по умолчанию.

### Информация о подключении к testapp
```
testapp_IP = 35.241.192.113
testapp_port = 9292
```

## HW 7 (Packer)

### Основное задание
После установки Packer (https://www.packer.io/downloads.html) было необходимо настроить Application Default Credentials (ADC), чтобы Packer мог обращаться к GCP через API:
```
$ gcloud auth application-default login
```

В файле ubuntu16.json были описаны инструкции для packer builder для подготовки образа Ubuntu с предустановленными Ruby и MongoDB. Сама установка выполняется при помощи т.н. provisioners, в данном случае имеющих воплощение в виде скриптов:
```
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
```

Проверка .json-файла на ошибки:
```
$ packer validate ./ubuntu16.json```
```
Запуск создания образа:
```
$ packer build ubuntu16.json
```
Деплой приложения:
```
$ git clone -b monolith https://github.com/express42/reddit.git
$ cd reddit && bundle install
$ puma -d
```

Важный момент: в секции builders можно задать network tags (tags), но они будут применяться только для instance, в котором подготавливается образ.
Для всех машин, которые позднее будут использовать этот образ, тэги нужно задавать отдельно при создании этих машин.

### Самостоятельные задания
Параметризация шаблона с использованием пользовательских переменных (в т.ч. для описание образа, размера диска, названия сети, тэгов):
```
{
    "variables": {
        "project_id": null,
        "source_image_family": null,
        "machine_type": "f1-micro",
        "image_description": "no description",
        "disk_size": "10",
        "network": "default",
        "tags": "puma-server"
    },
    "builders": [
        {
            "type": "googlecompute",
            "project_id": "{{ user `project_id` }}",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "source_image_family": "{{ user `source_image_family` }}",
            "zone": "europe-west1-b",
            "ssh_username": "appuser",
            "machine_type": "{{ user `machine_type` }}",
            "image_description": "{{ user `image_description` }}",
            "disk_size": "{{ user `disk_size` }}",
            "network": "{{ user `network` }}",
            "tags": "{{ user `tags` }}"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```
Сами переменные заданы в variables.json:
```
{
  "project_id": "infra-12345",
  "source_image_family": "ubuntu-1604-lts",
  "machine_type": "f1-micro",
  "image_description": "base image for reddit",
  "disk_size": "10",
  "network": "default",
  "tags": "puma-server"
}
```
Проверить корректность можно следующим образом:
```
$ packer inspect -var-file=variables.json.example ubuntu16.json
```

### Задание со * №1
Подготовка baked-образа, который включает установленное приложение + systemd unit для puma.
Этот шаблон описан в двух файлах: immutable.json и variables_full.json.
Основные отличия по сравнению с предыдущим образом (reddit-base):
В builders изменилось image_name и image_family, чтобы мы могли отличить reddit-base от reddit-full:
```
    "builders": [
        {
            "image_name": "reddit-full-{{timestamp}}",
            "image_family": "reddit-full",
        }
    ],
```
Поскольку мы будем создавать шаблон поверх reddit-base, старые скрипты из секции provisioners дублировать не нужно.
На их смену пришли:
* деплой файла с описанием systemd unit (на основе: https://github.com/puma/puma/blob/master/docs/systemd.md). Packer рекомендует осуществлять последующую настройку привелегий и перенос файла при помощи скриптов;
* скрипт, который скачивает приложение в домашнюю директорию appuser;
* скрипт, который переносит puma.service в нужную директорию, меняет привилегии, активирует автозапуск демона.
```
    "provisioners": [
        {
            "type": "file",
            "source": "files/puma.service",
            "destination": "/home/appuser/puma.service"
        },
        {
            "type": "shell",
            "script": "scripts/deploy_app.sh"
        },
        {
            "type": "shell",
            "script": "scripts/install_puma_service.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
```
variables_full.json (см. source_image_family):
```
    {
      "project_id": "infra-12345",
      "source_image_family": "reddit-base",
      "machine_type": "f1-micro",
      "image_description": "baked image for reddit",
      "disk_size": "10",
      "network": "default",
      "tags": "puma-server"
    }
```

Создание образа:
```
$ packer build -var-file=variables_full.json immutable.json
```

### Задание со * №2
Скрипт create-reddit-vm.sh для создания VM с приложением при помощи gcloud.
Чтобы имя instance было уникальным, к reddit-app- добавляется текущая дата, время и случайное число:
```
#!/bin/bash
set -e

# generating random id
id=$(date +'%Y%m%d%H%M%S')$RANDOM
gcloud compute instances create reddit-app-$id --image-family=reddit-full --machine-type=f1-micro --tags=puma-server
```

## HW 8 (IaC - terraform-1)
В данной работе мы настроили деплой нашего приложения посредством terraform.
Структура конфигурации:
- main.tf - виртуальная машина, правило firewall, provisioners, ssh-ключи;
- variables.tf - переменные, используемые в main.tf;
- terraform.tfvars - значения, подставляемые в переменные;
- outputs.tf - переменные, значение у которых появляется уже после запуска машин (e.g. IP-адрес)

### Самостоятельные задания
Определите input переменную для приватного ключа, использующегося в определении подключения для провижинеров (connection);
```
variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}
```

Определите input переменную для задания зоны в ресурсе "google_compute_instance" "app". У нее * должно быть значение по умолчанию*
```
variable "zone" {
  description = "Zone"
  default = "europe-west1-b"
}
```

### Задание со * (стр. 51)
Задание:
Опишите в коде терраформа добавление ssh ключа пользователя appuser1 в метаданные проекта.

Решение:
main.tf:
```
resource "google_compute_project_metadata_item" "default" {
  key   = "ssh-keys"
  value = "${chomp(file(var.public_key_path))}"
}
```

variables.tf:
```
variable "public_key_path" {
  description = "Path to the public key used for ssh access"

}
```

terraform.tfvars:
```
public_key_path = "~/.ssh/appuser.pub"
```

Важный момент: лучше использовать chomp при импорте содержимого файла, иначе в веб-интерфейсе GCP мы увидим два ключа: один нормальный, другой - пустой.

Задание:
Опишите в коде терраформа добавление ssh ключей нескольких пользователей в метаданные проекта (можно просто один и тот же публичный ключ, но с разными именами пользователей, например appuser1, appuser2 и т.д.).

Решение:
main.tf
```
resource "google_compute_project_metadata_item" "default" {
  key   = "ssh-keys"
  value = "${chomp(file(var.public_key_path))}\n${chomp(file(var.public_key_path2))}\n${chomp(file(var.public_key_path3))}"
}
```

variables.tf:
```
variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable "public_key_path2" {
  description = "Path to the public key used for ssh access"
}

variable "public_key_path3" {
  description = "Path to the public key used for ssh access"
}
```

terraform.tfvars:
```
public_key_path = "~/.ssh/appuser.pub"

public_key_path2 = "~/.ssh/temp_keys/appuser2.pub"

public_key_path3 = "~/.ssh/temp_keys/appuser3.pub"
```

### Задание со * (стр. 52)
Задание:
Добавьте в веб интерфейсе ssh ключ пользователю appuser_web в метаданные проекта. Выполните terraform apply и проверьте результат. Какие проблемы вы обнаружили?

Решение:
Поскольку все ssh-ключи хранятся в одном элементе метаданных проекта, то при попытке внести изменения через Terraform, предыдущие данные удаляются. Соответственно, мы должны использовать только один способ добавления ключей - либо через terraform, либо вручную.

### Задание с ** (стр. 53)
Задание:
Создайте файл lb.tf и опишите в нем в коде terraform создание HTTP балансировщика, направляющего трафик на наше развернутое приложение на инстансе reddit-app.

Решение:
lb.tf
```
resource "google_compute_instance_group" "ig-reddit-app" {
  name        = "ig-reddit-app"
  description = "Reddit app instance group"

  instances = [
    //    "${google_compute_instance.app.self_link}",
    "${google_compute_instance.app.*.self_link}",
  ]

  named_port {
    name = "http"
    port = "9292"
  }

  zone = "${var.zone}"
}

resource "google_compute_http_health_check" "reddit-http-basic-check" {
  name         = "reddit-http-basic-check"
  request_path = "/"
  port         = 9292
}

resource "google_compute_backend_service" "bs-reddit-app" {
  name        = "bs-reddit-app"
  description = "Backend service for reddit-app"
  port_name   = "http"
  protocol    = "HTTP"
  enable_cdn  = false

  backend {
    group           = "${google_compute_instance_group.ig-reddit-app.self_link}"
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
  }

  health_checks = ["${google_compute_http_health_check.reddit-http-basic-check.self_link}"]
}

resource "google_compute_url_map" "urlmap-reddit-app" {
  name        = "urlmap-reddit-app"
  description = "URL-map to redirect traffic to the backend service"

  default_service = "${google_compute_backend_service.bs-reddit-app.self_link}"
}

resource "google_compute_target_http_proxy" "http-lb-proxy-reddit-app" {
  name        = "http-lb-proxy-reddit-app"
  description = "Target HTTP proxy"
  url_map     = "${google_compute_url_map.urlmap-reddit-app.self_link}"
}

resource "google_compute_global_forwarding_rule" "fr-reddit-app" {
  name        = "website-forwarding-rule"
  description = "Forwarding rule"
  target      = "${google_compute_target_http_proxy.http-lb-proxy-reddit-app.self_link}"
  port_range  = "80"
}
```
Это решение было основано на примере: https://cloud.google.com/load-balancing/docs/https/content-based-example (вариант с target-pools не рассматривался, т.к. он менее сложен и интересен. Сравнение: https://stackoverflow.com/questions/48895008/target-pools-vs-backend-services-vs-regional-backend-service-difference)
В последовательности для gcloud, оно будет выглядеть следующим образом:
1. Создаем Instance-group.
2. Добавляем Instance в Instance-group
3. Создаём named-порт, по которому балансировщик будет дальше обращаться к instance. При обращении по HTTP, лучше порт назвать http.
4. Создаём HTTP health-check.
5. Создаём backend service. Его функция состоит в том, чтобы измерять производительность и доступность (как самой машины, так и ресурсов) у всех instance в instance group. При необходимости, трафик перенаправляется на другую машину.
Важно:
Если мы выберем протокол HTTP и при этом забудем указать port-name, то backend всё равно автоматически привяжется к порту с именем http, даже если он не существует.
$ gcloud compute backend-services create video-service --protocol HTTP --health-checks reddit-http-basic-check --global --port-name http
6. Добавляем instance group как backend в backend-сервис, при этом указываем режим балансировки и триггер по нагрузке, который в потенциале может использоваться для autoscale.
7. Задаем URL-map для перенаправления входящих запросов к соответствующему backend-сервису. Есть возможность задавать path-rules. В нашем случае, весь трафик, не попавший под остальные url-maps будет уходить к video-service.
8. Создаем target HTTP proxy для перенаправления запросов, соответствующих URL map
9. Создаем правило для перенаправления входящего трафика к нашему прокси. При необходимости, можно в будущем добавить отдельное правило под IPv6 внутри GСP трафик уже в виде IPv4 будет маршрутизироваться).


Задание:
Добавьте в output переменные адрес балансировщика.

Решение:
outputs.tf
```
output "Global Forwarding Rule IP" {
  value = "${google_compute_global_forwarding_rule.fr-reddit-app.ip_address}"
}
```

### Задание с ** (стр. 54)
Задание:
Добавьте в код еще один terraform ресурс для нового инстанса приложения, например reddit-app2, добавьте его в балансировщик и проверьте, что при остановке на одном из инстансов приложения (например systemctl stop puma), приложение продолжает быть доступным по адресу балансировщика; Добавьте в output переменные адрес второго инстанса; Какие проблемы вы видите в такой конфигурации приложения?

Решение:
Основное неудобство состоит в том, что каждый раз приходится копировать большой объем кода (instance, output-переменные)

### Задание с ** (стр. 55)
Задание:
Как мы видим, подход с созданием доп. инстанса копированием кода выглядит нерационально, т.к. копируется много кода. Удалите описание reddit-app2 и попробуйте подход с заданием количества инстансов через параметр ресурса count. Переменная count должна задаваться в параметрах и по умолчанию равна 1.

Решение:
main.tf
```
resource "google_compute_instance" "app" {
  count        = "${var.number_of_instances}"
  name         = "reddit-app-${count.index}"
  [...]
}
```
=> Здесь основное отличие будет состоять в том, что мы будет к имени автоматически добавлять номер instance через ${count.index}

variables.tf
```
variable "number_of_instances" {
  description = "Number of reddit-app instances (count)"
}
```

terraform.tfvars
```
number_of_instances = 1
```

outputs.tf
```
output "app_external_ip2" {
  value = "${google_compute_instance.app.*.network_interface.0.access_config.0.nat_ip}"
}
```
=> Чтобы output-переменные генерировались для каждого созданного instance, после указания имени ресурса terraform, необходимо добавить .*. (google_compute_instance.app.*.).


## HW 9 (terraform-2 - IaC in a team)

### Импорт ресурсов из GCP
Создаём копию уже определённого в GCP правила, разрешающего подключение по ssh:
```
resource "google_compute_firewall" "firewall_ssh" {
  name        = "default-allow-ssh"
  description = "Allow SSH from anywhere"
  network     = "default"
  priority    = 65534

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}
```
Т.к. в terraform state отсутствует информация о том, что правило уже применено, terraform apply завершится с ошибкой. Соответственно, нам необходимо вручную импортировать состояние:
$ terraform import google_compute_firewall.firewall_ssh default-allow-ssh

### Пример ссылки на атрибуты другого ресурса
```
resource "google_compute_address" "app_ip" {
  name   = "reddit-app-ip"
  region = "${var.region}"
}
```

```
  network_interface {
    //[...]
    access_config {
      nat_ip = "${google_compute_address.app_ip.address}"
    }
  }
```

### Разбиение конфигурации по файлам / на модули
```
$ tree modules/app/
modules/app/
├── files
│   ├── deploy.sh
│   ├── puma.service
│   └── set_env.sh
├── main.tf
├── outputs.tf
└── variables.tf
```

```
$ tree modules/db
modules/db
├── main.tf
├── outputs.tf
└── variables.tf
```

Интересные особенности:
1. В модуль можно передавать значения для переменных;
```
module "db" {
  source          = "../modules/db"
  public_key_path = "${var.public_key_path}"
  zone            = "${var.zone}"
  db_disk_image   = "${var.db_disk_image}"
}
```

2. Модуль может возвращать значения переменных:
```
variable "database_url" {
  description = "database_url for reddit app"
  default     = "127.0.0.1:27017"
}
```
Соответственно, к ним можно обращаться извне:
```
database_url        = "${module.db.db_internal_ip}:27017"
```

После добавления конфигурации модуля, необходимо выполнить $ terraform get

### Самостоятельное задание (стр. 24)
Необходимо создать модуль vpc (+ параметризация).
```
resource "google_compute_firewall" "firewall_ssh" {
  name        = "default-allow-ssh"
  description = "Allow SSH from anywhere"
  network     = "default"
  priority    = 65534

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  //  source_ranges = ["0.0.0.0/0"]
  source_ranges = "${var.source_ranges}"
}

resource "google_compute_project_metadata_item" "default" {
  key = "ssh-keys"

  value = "appuser:${chomp(file(var.public_key_path))}"
}
```

### Самостоятельное задание (стр. 32)
Проверьте работу параметризованного в прошлом слайде модуля vpc.
1. Введите в source_ranges не ваш IP адрес, примените правило и проверьте отсутствие соединения к обоим хостам по ssh. Проконтролируйте, как изменилось правило файрвола в веб консоли.
2. Введите в source_ranges ваш IP адрес, примените правило и проверьте наличие соединения к обоим хостам по ssh.
3. Верните 0.0.0.0/0 в source_ranges.
=> Всё отработало корректно.

### Разбиение конфигурации на stage и prod
```
$ tree stage
stage
├── backend.tf
├── main.tf
├── outputs.tf
├── terraform.tfstate
├── terraform.tfstate.backup
├── terraform.tfvars
├── terraform.tfvars.example
└── variables.tf
```
$ tree prod
prod
├── backend.tf
├── main.tf
├── outputs.tf
├── terraform.tfstate
├── terraform.tfstate.backup
├── terraform.tfvars
├── terraform.tfvars.example
└── variables.tf
```

### Самостоятельное задание (стр. 36)
1. Удалите из папки terraform файлы main.tf, outputs.tf, terraform.tfvars, variables.tf, так как они теперь перенесены в stage и prod
2. Параметризируйте конфигурацию модулей насколько считаете нужным
3. Отформатируйте конфигурационные файлы, используя команду terraform fmt
=> Сделано

### Работа с реестром модулей
https://registry.terraform.io/modules/SweetOps/storage-bucket/google
```
provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
}

module "storage-bucket" {
  source  = "SweetOps/storage-bucket/google"
  version = "0.1.1"
  name    = ["terraform-prod-state-bucket", "terraform-stage-state-bucket"]
}

output storage-bucket_url {
  value = "${module.storage-bucket.url}"
}
```

### Задание со * (Стр. 42)
1. Настройте хранение стейт файла в удаленном бекенде (remote backends) для окружений stage и prod, используя Google Cloud Storage в качестве бекенда. Описание бекенда нужно вынести вотдельный файл backend.tf
=> Поскольку для переноса state-файлов в bucket последний сперва должен быть создан:
```
	ibeliako@dev:~/devops/git/weisdd_infra/terraform/prod$ terraform init
	Initializing modules...
	- module.app
	- module.db
	- module.vpc

	Initializing the backend...
	Error inspecting states in the "gcs" backend:
		querying Cloud Storage failed: storage: bucket doesn't exist
```
конфигурацию необходимо применять по частям:
```
resource "google_storage_bucket" "terraform_state_prod" {
  name     = "terraform-state-prod-31337"
  location = "${var.location}"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  force_destroy = false
}
```
После выполнения terraform apply можно добавить оставшуюся часть:
```
terraform {
  backend "gcs" {
    bucket  = "terraform-state-prod-31337"
    prefix  = "terraform/state/prod"
  }
}
```

```
$ terraform init
	Initializing modules...
	- module.app
	- module.db
	- module.vpc

Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "gcs" backend. An existing non-empty state already exists in
  the new backend. The two states have been saved to temporary files that will be
  removed after responding to this query.
  
  Previous (type "local"): /tmp/terraform066626646/1-local.tfstate
  New      (type "gcs"): /tmp/terraform066626646/2-gcs.tfstate
  
  Do you want to overwrite the state in the new backend with the previous state?
  Enter "yes" to copy and "no" to start with the existing state in the newly
  configured "gcs" backend.

  Enter a value: yes


Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...

Terraform has been successfully initialized!

[...]
```

2. Перенесите конфигурационные файлы Terraform в другую директорию (вне репозитория). Проверьте, что state-файл (terraform.tfstate) отсутствует. Запустите Terraform в обеих директориях и проконтролируйте, что он "видит" текущее состояние независимо от директории, в которой запускается
=>
```
:~/devops/git/weisdd_infra/terraform/prod-temp$ terraform refresh
google_compute_address.app_ip: Refreshing state... (ID: infra-235421/europe-west1/reddit-app-ip)
google_compute_firewall.firewall_puma: Refreshing state... (ID: allow-puma-default)
google_storage_bucket.terraform_state_prod: Refreshing state... (ID: terraform-state-prod-31337)
google_compute_instance.db: Refreshing state... (ID: reddit-db)
google_compute_firewall.firewall_mongo: Refreshing state... (ID: allow-mongo-default)
google_compute_project_metadata_item.default: Refreshing state... (ID: ssh-keys)
google_compute_firewall.firewall_ssh: Refreshing state... (ID: default-allow-ssh)
google_compute_instance.app: Refreshing state... (ID: reddit-app-0)

Outputs:

app_external_ip2 = [
    104.199.11.89
]
db_external_ip2 = [
    35.233.2.133
]
:~/devops/git/weisdd_infra/terraform/prod-temp$ ls
backend.tf  main.tf  outputs.tf  terraform.tfvars  terraform.tfvars.example  variables.tf
```
Всё отработало корректно.

3. Попробуйте запустить применение конфигурации одновременно, чтобы проверить работу блокировок
=> gcs backend поддерживает блокировку (terraform выполняет её автоматически), поэтому никаких коллизий не возникает:
```
:~/devops/git/weisdd_infra/terraform/prod-temp$ terraform apply

Error: Error locking state: Error acquiring the state lock: writing "gs://terraform-state-prod-31337/terraform/state/prod/default.tflock" failed: googleapi: Error 412: Precondition Failed, conditionNotMet
Lock Info:
  ID:        1555360328288495
  Path:      gs://terraform-state-prod-31337/terraform/state/prod/default.tflock
  Operation: OperationTypeApply
  Who:       ibeliako@dev
  Version:   0.11.13
  Created:   2019-04-15 20:32:08.080356139 +0000 UTC
  Info:      


Terraform acquires a state lock to protect the state from being written
by multiple users at the same time. Please resolve the issue above and try
again. For most commands, you can disable locking with the "-lock=false"
flag, but this is not recommended.
```

P.S. Если provisioning для bucket'а выполняется в том же наборе конфигурационных файлов, что и остальная инфраструктура, для удаления ресурсов потребуется:
* Закомментировать секцию gcs и после выполнить terraform init
=> Будет предложено выполнить миграцию state-файлов из gcs в локальное хранилище
* Изменить параметры lifecycle и force_destroy
```
  lifecycle {
    prevent_destroy = false
  }

  force_destroy = true
```
* В terraform.tfstate вручную подправить force_destroy с false на true, затем выполнить terraform destroy.
При отдельном provisioning для gcs, полагаю, таких сложностей возникать не будет, но не тестировал.

### Задание с **
В процессе перехода от конфигурации, созданной в предыдущем ДЗ к модулям мы перестали использовать provisioner для деплоя приложения. Соответственно, инстансы поднимаются без приложения.
Добавьте необходимые provisioner в модули для деплоя и работы приложения. Файлы, используемые в provisioner, должны находится в директории модуля.
=>

1. По умолчанию, MongoDB слушает порт 27017 только на 127.0.0.1. Соответственно, нам потребуется пересобрать reddit-db-base в Packer'е, при этом положив измененный mongod.conf в /etc.

1.1. Подготавливаем файл с конфигурацией MongoDB - packer/files/mongod.conf:
```
# mongod.conf
[...]
net:
  port: 27017
#  bindIp: 127.0.0.1
  bindIp: 0.0.0.0
```

1.2. Вносим соответствующие изменения в секцию provisioners в packer/db.json, в конечном итоге получаем:
```
    "provisioners": [
        {
            "type": "file",
            "source": "files/mongod.conf",
            "destination": "/tmp/mongod.conf"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
```

1.3. В скрипт packer/scripts/install_mongodb.sh необходимо добавить команды, подменяющие файл mongodb в /etc, не забываем выполнить chown:
```
#!/bin/bash
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
sudo apt update
sudo apt install -y mongodb-org
sudo rm /etc/mongod.conf
sudo mv /tmp/mongod.conf /etc/
sudo chown root:root /etc/mongod.conf
sudo systemctl daemon-reload
sudo systemctl start mongod
sudo systemctl enable mongod
```

1.4. Пересобираем образ:
```
$ packer build -var-file=variables.json db.json
```

2. Дополняем конфигурацию terraform
2.1. Поскольку мы заранее не знаем, каким будет внутренний IP-адрес db instance, создаёт output-переменную в modules/db/outputs.tf:
```
output "db_internal_ip" {
  value = "${google_compute_instance.db.network_interface.0.network_ip}"
}
```

2.2. Приложение в процессе работы использует БД, указанную в переменной окружения DATABASE_URL. Добавляем поддержку EnvironmentFile в секции Service в modules/app/files/puma.service:
```
[...]
[Service]
EnvironmentFile=/home/appuser/reddit_app_service.conf
[...]
```

2.3. Создаём дополнительный скрипт, который будет динамически записывать IP-адрес db instnance в /home/appuser/reddit_app_service.conf. modules/app/files/set_env.sh
```bash
#!/bin/bash
set -e

DATABASE_URL="${1:-127.0.0.1:27017}"
echo $DATABASE_URL
# Supplies reddit app with a link to database, it's useful when a db server is
# installed on another host
bash -c "echo 'DATABASE_URL=${DATABASE_URL}' > ~/reddit_app_service.conf"
```

2.4. В modules/app/variables.tf добавляем поддержку переменной database_url, которую мы и будем передавать в скрипт set_env.sh:
```
variable "database_url" {
  description = "database_url for reddit app"
  default     = "127.0.0.1:27017"
}
```

2.5. В modules/app/main.tf добавляем provisioner для скрипта:
```
[...]
  provisioner "file" {
    source      = "${path.module}/files/set_env.sh"
    destination = "/tmp/set_env.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/chmod +x /tmp/set_env.sh",
      "/tmp/set_env.sh ${var.database_url}",
    ]
  }
[...]
```
Здесь следует отдельно отметить, что т.к. terraform использует относительные пути к файлам, в модулях необходимо использовать ${path.module},  иначе файлы не будут найдены:
```
source      = "${path.module}/files/set_env.sh"
```

## HW 10 (ansible-1)
Примеры протестированных команд:
```
$ ansible app -m command -a 'ruby -v'
$ ansible app -m command -a 'ruby -v; bundler -v'
$ ansible db -m command -a 'systemctl status mongod'
$ ansible db -m systemd -a name=mongod
$ ansible db -m service -a name=mongod
$ ansible app -m git -a 'repo=https://github.com/express42/reddit.git dest=/home/appuser/reddit'
```
### Вопрос на стр. 32
Теперь выполните:
	ansible app -m command -a 'rm -rf ~/reddit'
и проверьте еще раз выполнение плейбука. Что изменилось и почему?
Папка была удалена, поэтому повторное выполнение ansible-playbook clone.yml приводит к скачиванию репозитория.

### Задание со * (стр. 33-35)
1. Создайте файл inventory.json в формате, описанном в п.1 для нашей GCP-инфраструктуры и скрипт для работы с ним.
=> Чтобы не формировать файл каждый раз вручную, был написан скрипт dynamic_inventory.py, который, пользуясь реквизитами доступа и дефолтным конфигом gcloud, опрашивает GCP и возвращает inventory либо в динамическом формате json, либо в статическом формате (в зависимости от переданных ключей). При наличии у instance метки ansible_group, узел автоматически помещается в соответствующую группу (для тестов, данные о метках внесены в модули Terraform).
```bash
$ ansible-inventory all -i dynamic_inventory.py --graph
@all:
  |--@app:
  |  |--34.76.162.247
  |--@db:
  |  |--104.199.2.82
  |--@ungrouped:
  |  |--10.132.15.225
```
Динамический формат:
```bash
./dynamic_inventory.py --list > inventory.json
```
Статический:
```bash
./dynamic_inventory.py --list --static-mode > inventory_static.json
```

2. Добейтесь успешного выполнения команды ansible all -m ping и опишите шаги в README.
=> По сути, можно использовать dynamic_inventory.py напрямую, но раз уж в задании явно оговаривается необходимость применения inventory.json, то нам потребуется простой скрипт, который будет считывать содержимое файла и выводить его в stdout.
print_dynamic_inventory.py:
```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-


def main():
    with open('inventory.json') as f:
        print(f.read())


if __name__ == '__main__':
    main()
```

```bash
$ ansible-inventory -i print_dynamic_inventory.py --graph
@all:
  |--@app:
  |  |--34.76.47.104
  |--@db:
  |  |--104.199.2.82
  |--@ungrouped:
```

```bash
$ ansible all -i print_dynamic_inventory.py -m ping
34.76.47.104 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
104.199.2.82 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

3. Добавьте параметры в файл ansible.cfg для работы с инвентори в формате JSON.
=>
```bash
$ cat ansible.cfg 
[defaults]
;inventory = ./inventory
inventory = ./print_dynamic_inventory.py
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
```

4. Если вы разобрались с отличиями схем JSON для динамического и статического инвентори, также добавьте описание в README
=> Статический формат:
```
{
  "app": {
    "hosts": {
      "reddit-app-0": {
        "ansible_host": "34.76.162.247"
      }
    }
  },
  "db": {
    "hosts": {
      "reddit-db": {
        "ansible_host": "104.199.2.82"
      }
    }
  },
  "ungrouped": {
    "hosts": {
      "instance-1": {
        "ansible_host": "10.132.15.225"
      }
    }
  },
  "vars": {}
}
```
Динамический формат:
```
{
  "_meta": {
    "hostvars": {}
  },
  "app": {
    "hosts": [
      "34.76.162.247"
    ],
    "vars": {}
  },
  "db": {
    "hosts": [
      "104.199.2.82"
    ],
    "vars": {}
  },
  "ungrouped": {
    "hosts": [
      "10.132.15.225"
    ],
    "vars": {}
  }
}
```

## HW 11 (ansible-2)
В данной работе мы опробовали:
* применение jinja2 templates;
* пробный прогон через опцию --check;
* ограничение группы хостов, к которым применяется плейбук, через --limit <hosts> и --tags <tags>;
* разбиение одного плейбука на несколько с последующим их объединением в один плейбук через import;
* механизм notify /handlers;
* установка софта и деплой приложения через Ansible (на смену bash-скриптам), в т.ч. в Packer.

### Задание со * (стр. 69)
Условия:
Исследуйте возможности использования dynamic inventory для GCP (для этого есть не только gce.py ?).
Использование динамического инвентори означает, что это должно быть отражено в ansible.cfg и плейбуках (т.е. они должны использовать выбранное решение)

Решение:
В целом, можно было использовать скрипт, разработанный для прошлого задания, dynamic_inventory.py, или gcp.py, но актуальная документация по Ansible рекомендует применение inventory plugin "gcp compute". Его гибкости вполне достаточно для текущих задач.

Итак, настройка плагина (inventory_gcp.yml):
```yaml
plugin: gcp_compute
zones:
  - europe-west1-b
projects:
  - infra-235421
scopes:
  - https://www.googleapis.com/auth/compute
service_account_file: ~/devops/service_account.json
auth_kind: serviceaccount
filters:
keyed_groups:
  # <prefix><separator><key>
  - prefix: ""
    separator: ""
    key: labels.ansible_group
hostnames:
  # List hosts by name instead of the default public ip
  - name
compose:
  # Set an inventory parameter to use the Public IP address to connect to the host
  # For Private ip use "networkInterfaces[0].networkIP"
  ansible_host: networkInterfaces[0].accessConfigs[0].natIP
```
В целом, конфиг основан на:
http://docs.testing.ansible.com/ansible/latest/plugins/inventory/gcp_compute.html
с некоторыми дополнениями.

Ключевые моменты:
* Имя файла с конфигурацией должна заканчиваться на gcp_compute.(yml|yaml) или gcp.(yml|yaml), иначе возникнет ошибка;
* Поскольку Ansible запускаем не из GCP, в секции compose собираем внешние IP-адреса;
* Есть разные способы выстраивания inventory-файла, но наиболее подходящий нам - keyed_groups. Формат по умолчанию: <prefix><separator><key>
  - prefix и separator приравниваем к "" (стандартное значение для separator - "_");
  - в предыдущей домашней работе в качестве индикатора принадлежности к конкретной Ansible-группе я выбрал label "ansible_group", соответственно и в качестве параметра key теперь указываем "labels.ansible_group";
* Для авторизации на GCP используется service account file в формате json (параметр service_account_file).

Изменения в ansible.cfg
```ini
[defaults]
inventory = ./inventory_gcp.yml
[inventory]
enable_plugins = gcp_compute, host_list, script, yaml, ini, auto
```

### Самостоятельное задание (стр. 72)
Задание:
Опишите с помощью модулей Ansible в плейбуках ansible/packer_app.yml и ansible/packer_db.yml действия, аналогичные bash-скриптам, которые сейчас используются в нашей конфигурации Packer.

Решение:
packer_app.yml
```yaml
---
- name: Install Ruby, Bundler, build-essential
  hosts: all
  become: true
  tasks:
    - name: Install Ruby and all dependencies
      apt:
        name: "{{ packages }}"
      vars:
        packages:
          - ruby-full
          - ruby-bundler
          - build-essential
```

packer_db.yml
```yaml
---
- name: Install MongoDB
  hosts: all
  become: true
  tasks:
    - name: Add MongoDB key
      apt_key:
        keyserver: keyserver.ubuntu.com
        id: EA312927

    - name: Add MongoDB repository
      apt_repository:
        repo: deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse
        filename: mongodb-org-3.2.list

    - name: Install MongoDB
      apt:
        name: mongodb-org

    - name: Enable MongoDB service
      systemd:
        name: mongod
        enabled: yes
```
Интересная особенность плейбука в том, что hosts нужно выставить равным all.

Интеграция в Packer:
app.json
```json
    "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "ansible/packer_app.yml"
        }
    ]
```

db.json
```json
    "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "ansible/packer_db.yml"
        }
    ]
```
Важно:
Для того, чтобы build корректно выполнился, теперь packer нужно запускать из корневой директории репозитория:
```
weisdd_infra$ packer validate -var-file=packer/variables.json packer/db.json
weisdd_infra$ packer validate -var-file=packer/variables.json packer/app.json
```

### Extra work
Поскольку у меня нет никакого желания каждый раз при деплое приложения вручную указывать IP-адрес instance с MongoDB, я подправил app.yml:
```yaml
- name: Gather facts from reddit-db
  hosts: db
  tasks: []

- name: Configure App
  hosts: app
  become: true
  vars:
    db_host: "{{ hostvars['reddit-db']['ansible_default_ipv4']['address'] }}"
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/appuser/db_config

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
  - name: reload puma
    service: name=puma state=restarted
    tags: app-tag
```
Поскольку мы заранее не знаем, каким будет IP-адрес instance с MongoDB, нам необходимо опираться на ansible facts, которые собираются в процессе выполнения плейбука. При этом, в одном из предыдущих заданий мы разбили один плейбук на множество, ограничив описание деплоя приложения группой хостов app, соответственно, на момент выполнения app.yaml в Ansible отсутствуют факты о db. В соответствии с рекомендацией, найденной на https://serverfault.com/questions/638507/how-to-access-host-variable-of-a-different-host-with-ansible, необходимо добавить пустое задание для db, чтобы форсировать сбор фактов:
```yaml
- name: Gather facts from reddit-db
  hosts: db
  tasks: []
```
После этого можем использовать:
```yaml
- name: Configure App
  hosts: app
  become: true
  vars:
    db_host: "{{ hostvars['reddit-db']['ansible_default_ipv4']['address'] }}"
```

## HW#12 (ansible-3: Работа с ролями и окружениями)
В данной работе мы сделали:
* разбили ранее созданные плейбуки на роли (app, db);
* разделили окружения на prod и env;
* установили комьюнити-роль nginx;
* опробовали применения Ansible Vault;
* добавили поддержку окружения в dynamic inventory;
* задали дополнительные тесты в TravisCI.

### Самостоятельное задание (стр. 48)
Задание:
* Добавьте в конфигурацию Terraform открытие 80 порта для инстанса приложения
* Добавьте вызов роли jdauphant.nginx в плейбук app.yml
* Примените плейбук site.yml для окружения stage и проверьте, что приложение теперь доступно на 80 порту

Решение:
* Добавьте в конфигурацию Terraform открытие 80 порта для инстанса приложения
В GCP, по умолчанию, существует правило, разрешающее доступ по http для instance с network tag "http-server". Соответственно, мы можем обойтись минимумом изменений в конфигурации terraform:
modules/app/main.tf:
```
resource "google_compute_instance" "app" {
  [...]
  tags = ["reddit-app", "http-server"]
  [...]
}
```
* Добавьте вызов роли jdauphant.nginx в плейбук app.yml
```yaml
---
#https://serverfault.com/questions/638507/how-to-access-host-variable-of-a-different-host-with-ansible
- name: Gather facts from reddit-db
  hosts: db
  tasks: []

- name: Configure App
  hosts: app
  become: true

  roles:
    - app
    - jdauphant.nginx
```

* Примените плейбук site.yml для окружения stage и проверьте, что приложение теперь доступно на 80 порту
+

### Задание со * (стр. 55) - Работа с динамическим инвентори
Задание:
Настройте использование динамического инвентори для окружений stage и prod.

Решение:
Тут всё довольно просто. Первым делом, нам нужно определить некий признак, по которому instance будет считаться частью соответствующего окружения (prod или stage). Им станет метка 'env', зададим её в конфигурации terraform:
terraform/modules/app/variables.tf
```json
variable "label_env" {
  description = "GCP label 'env' associating an instance with an environment in which it's being run (e.g. stage, prod)"
  default     = "stage"
}
```
terraform/modules/app/main.tf
```json
resource "google_compute_instance" "app" {
  [...]

  labels {
    ansible_group = "app"
    env           = "${var.label_env}"
  }
  [...]
}
```
terraform/modules/db/variables.tf
```json
variable "label_env" {
  description = "GCP label 'env' associating an instance with an environment in which it's being run (e.g. stage, prod)"
  default     = "stage"
}
```
terraform/modules/db/main.tf
```json
resource "google_compute_instance" "db" {
  [...]

  labels {
    ansible_group = "db"
    env           = "${var.label_env}"
  }
  [...]
}
```
terraform/prod/variables.tf
```json
variable "label_env" {
  description = "GCP label 'env' associating an instance with an environment in which it's being run (e.g. stage, prod)"
  default     = "prod"
}
```
terraform/prod/terraform.tfvars
```json
label_env = "prod"
```
terraform/prod/main.tf
```json
module "app" {
  [...]
  label_env           = "${var.label_env}"
}

module "db" {
  [...]
  label_env       = "${var.label_env}"
}

```
terraform/stage/variables.tf
```json
variable "label_env" {
  description = "GCP label 'env' associating an instance with an environment in which it's being run (e.g. stage, prod)"
  default     = "stage"
}
```
terraform/stage/terraform.tfvars
```json
label_env = "stage"
```
terraform/stage/main.tf
```json
module "app" {
  [...]
  label_env           = "${var.label_env}"
}

module "db" {
  [...]
  label_env       = "${var.label_env}"
}

```

Теперь остаётся только добавить поддержку метки в конфигурацию inventory plugin в Ansible:
ansible/environments/prod/inventory_gcp.yml
```yaml
filters:
  - labels.env = prod
``` 
ansible/environments/stage/inventory_gcp.yml
```yaml
filters:
  - labels.env = stage
``` 

Проверяем (для тестов я специально app поместил в stage, а db - в prod):
```bash
ibeliako@dev:~/devops/git/weisdd_infra/ansible$ gcloud compute instances describe reddit-app-0 | grep labels -A 2
labels:
  ansible_group: app
  env: stage

ibeliako@dev:~/devops/git/weisdd_infra/ansible$ ansible-inventory --graph
@all:
  |--@app:
  |  |--reddit-app-0
  |--@ungrouped:

ibeliako@dev:~/devops/git/weisdd_infra/ansible$ gcloud compute instances describe reddit-db | grep labels -A 2
labels:
  ansible_group: db
  env: prod
  
ibeliako@dev:~/devops/git/weisdd_infra/ansible$ ansible-inventory -i environments/prod/inventory_gcp.yml --graph
@all:
  |--@db:
  |  |--reddit-db
  |--@ungrouped:
```

### Задание с ** (стр. 56-57)
Задание:
В предыдущих ДЗ вы уже использовали TravisCI. Теперь настройте его для контроля состояния вашего инфраструктурного
репозитория.
Необходимо, чтобы для коммитов в master и PR выполнялись как минимум эти действия:
* packer validate для всех шаблонов
* terraform validate и tflint для окружений stage и prod
* ansible-lint для плейбуков Ansible
* в README.md добавлен бейдж с статусом билда
Из секции before_install нельзя удалять секцию наших тестов otus-homeworks.

Решение:
Поскольку otus использует inspec для проверки ДЗ, я решил его тоже опробовать.
Итак, в репозитории weisdd_infra был создан каталог travisci: 
```bash
ibeliako@dev:~/devops/git/weisdd_infra$ tree travisci/
travisci/
├── run_tests_in_docker.sh
└── tests
    ├── controls
    │   ├── ansible.rb
    │   ├── packer.rb
    │   └── terraform.rb
    ├── inspec.yml
    └── run_tests.sh
```
Здесь:
* travisci/run_tests_in_docker.sh - основной скрипт для TravisCI - будет передавать команды в контейнер с тестами;
* travisci/tests/controls/*.rb - тесты для соответствующих приложения
  - ansible.rb
  - packer.rb
  - terraform.rb
* travisci/tests/inspec.yml - конфигурационный файл для inspec - в данном случае, бесполезен;
* travisci/tests/run_tests.sh - скрипт, непосредственно запускающий inspec.

Поскольку скрипт от otus для проверки ДЗ (https://raw.githubusercontent.com/express42/otus-homeworks/2019-02/run.sh) создаёт контейнер с нужным софтом и клонирует мой репозиторий, никаких особенных шаманств в travisci/run_tests_in_docker.sh описывать не нужно - достаточно лишь запустить исполнение travisci/tests/run_tests.sh:
travisci/run_tests_in_docker.sh
```bash
#!/usr/bin/env bash
HOMEWORK_RUN=./travisci/tests/run_tests.sh

if [ -f $HOMEWORK_RUN ]; then
  echo "Run tests (linters, validators)"
  docker exec -e USER=appuser hw-test $HOMEWORK_RUN
else
  echo "We don't have any tests"
  exit 0
fi
```
От travisci/tests/run_tests.sh требуется следующее:
* создание иллюзии присутствия публичного ключа ssh, наличие которого будет проверять terraform;
* установка ролей из ansible-galaxy (на случай, если из основного скрипта otus эта команда исчезнет);
* запуск inspec.
travisci/tests/run_tests.sh
```bash
#!/usr/bin/env bash
set -e

# Creating dummy keys for terraform linter
touch ~/.ssh/appuser.pub ~/.ssh/appuser

# Install requirements
cd ansible && ansible-galaxy install -r environments/stage/requirements.yml && cd ..

inspec exec travisci/tests/
```
В тесте для ansible мы будем проверять все плейбуки при помощи ansible-lint. Каталоги с ролями не проверяются как и указано в задании (btw, на данный момент они не соответствуют best practice, линтер негодует).
travisci/tests/controls/ansible.rb
```ruby
# encoding: utf-8
title 'Ansible playbooks validation'

control 'ansible' do
  impact 1
  title 'Run ansible-lint'

  files = command('find ansible/playbooks ! -name "inventory*.yml" -name "*.yml" -type f').stdout.split("\n")
    files.each do |fname|
      describe command("ansible-lint #{fname} --exclude=ansible/roles/jdauphant.nginx") do
        its('stdout') { should eq '' }
        its('stderr') { should eq '' }
        its('exit_status') { should eq 0 }
      end
    end
end
```
В тесте для packer проверяются json-файлы только в основном каталоге. При этом variables*.json исключаются.
travisci/tests/controls/packer.rb
```ruby
# encoding: utf-8
title 'Packer templates validation'

control 'packer' do
  impact 1
  title 'Run packer validate'

  files = command('find packer -maxdepth 1 ! -name "variables*.json" -name "*.json" -type f').stdout.split("\n")
    files.each do |fname|
      describe command("packer validate -var-file=packer/variables.json.example #{fname}") do
        its('stdout') { should eq "Template validated successfully.\n" }
        its('exit_status') { should eq 0 }
      end
    end
end
```
В тесте для Terraform validate выполняется только для окружений prod и stage, modules покрыты только линтером (т.к. иначе бы потребовался terraform init и прочие сложности).
travisci/tests/controls/terraform.rb
```ruby
# encoding: utf-8
title 'Terraform validation'

control 'terraform' do
  impact 1
  title 'Run packer validate'

  modules = command('cd terraform/ && find modules/ -mindepth 1 -maxdepth 1 -type d').stdout.split("\n")
  environments = ['stage/', 'prod/']
    all_folders = modules + environments
    all_folders.each do |fname|
      unless modules.include?(fname)  # We don't expect to see terraform.tfvars.example in folders with modules, thus skip validation
        describe command("cd terraform/#{fname} && terraform init -backend=false && terraform validate -var-file=terraform.tfvars.example") do
          its('stdout') { should match "Terraform has been successfully initialized!" }
            its('stderr') { should eq "" }
            its('exit_status') { should eq 0 }
        end
      end
      describe command("cd terraform/#{fname} && tflint --var-file=terraform.tfvars.example --deep -q") do
        its('stdout') { should eq "" }
        its('stderr') { should eq "" }
        its('exit_status') { should eq 0 }
      end
    end
end
```

Осталось только задать конфигурацию TravisCI в файле .travis.yml в корне репозитория.
Как уже упоминалось выше, скрипт от otus создаёт контейнер и устанавливает нужный нам софт. Поэтому мы можем спокойно дождаться завершения его исполнения и уже после запустить наши тесты.

Workflow TravisCI разбит на множество этапов (подробнее: https://docs.travis-ci.com/user/job-lifecycle/#breaking-the-build), мы воспользуемся "before_script":
.travis.yml
```yaml
[...]
before_install:
- curl https://raw.githubusercontent.com/express42/otus-homeworks/2019-02/run.sh | bash
before_script:
- curl https://raw.githubusercontent.com/otus-devops-2019-02/weisdd_infra/ansible-3/travisci/run_tests_in_docker.sh | bash
[...]
```

Последний штрих: добавляем inspec.lock (временный файл, который создает inspec) в .gitignore:
```
inspec.lock
```

Статус билда:
[![Build Status](https://travis-ci.com/otus-devops-2019-02/weisdd_infra.svg?branch=ansible-3)](https://travis-ci.com/otus-devops-2019-02/weisdd_infra/branches)

## HW#13 (ansible-4)
В данной работе мы опробовали:
* применение модуля raw для установки Python;
* использование Vagrant с provisioning через Ansible;
* тестирование ролей Ansible при помощи molecule и testinfra;
* использование ролей Ansible в Packer.

### Vagrant
Интересная особенность:
inventory генерируется автоматически в процессе провижионинга конкретной виртуальной машины (.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory). При этом, если список хостов последовательно наполняется, то описание их принадлежности к конкретной группе появляется лишь на время работы с конкретным узлом. Поэтому когда мы применяем site.yml для второй машины, этапы, специфичные для первой, пропускаются.
Пример:
```ruby
  ansible.groups = {
    "db" => ["dbserver"]
  }
```
```bash
[...]
TASK [Gathering Facts] *********************************************************
ok: [dbserver]
 [WARNING]: Could not match supplied host pattern, ignoring: app

$ cat .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory 
# Generated by Vagrant

dbserver ansible_host=127.0.0.1 ansible_port=2222 ansible_user='vagrant' ansible_ssh_private_key_file='/home/ibeliako/devops/git/weisdd_infra/ansible/.vagrant/machines/dbserver/virtualbox/private_key'

[db]
dbserver

[db:vars]
mongo_bind_ip=0.0.0.0

[...]

$ cat .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory 
# Generated by Vagrant

appserver ansible_host=127.0.0.1 ansible_port=2200 ansible_user='vagrant' ansible_ssh_private_key_file='/home/ibeliako/devops/git/weisdd_infra/ansible/.vagrant/machines/appserver/virtualbox/private_key'
dbserver ansible_host=127.0.0.1 ansible_port=2222 ansible_user='vagrant' ansible_ssh_private_key_file='/home/ibeliako/devops/git/weisdd_infra/ansible/.vagrant/machines/dbserver/virtualbox/private_key'

[app]
appserver

[app:vars]
db_host=10.10.10.10
```

При работе с Ansible мы можем переопределить переменные роли при помощи параметра extra_vars (имеет самый высокий приоритет).
Пример:
```ruby
  config.vm.define "dbserver" do |db|
    db.vm.box = "ubuntu/xenial64"
    db.vm.hostname = "dbserver"
    db.vm.network :private_network, ip: "10.10.10.10"

    db.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
        "db" => ["dbserver"],
        "db:vars" => {"mongo_bind_ip" => "0.0.0.0"}
      }
    end
  end
```
В параметре vm.box мы указываем образ системы, который будет использоваться. В случае, если его локальная копия отсуствует, по умолчанию, vagrant попытается её скачать с https://vagrantcloud.com

Команды, которые могут пригодиться:
$ vagrant box list
$ vagrant up
$ vagrant status
$ vagrant provision <name> //для уже поднятой виртуалки
$ vagrant ssh <name>
$ vagrant destroy -f

### Задание со * (стр. 49)
Задание:
Как мы видим из лога, nginx у нас также настраивается для appserver в процессе провижининга. Но если мы попробуем открыть адрес 10.10.10.20, то приложения там не будет.
Дополните конфигурацию Vagrant для корректной работы проксирования приложения с помощью nginx.

Решение:
Ранее мы указывали конфигурацию nginx в environments/<prod|stage>/group_vars/app:
```yaml
nginx_sites:
  default:
    - listen 80
    - server_name "reddit"
    - location / {
        proxy_pass http://127.0.0.1:9292;
      }
```
Соответственно, нам необходимо лишь привести синтаксис к совместимому с Vagrant виду:
```ruby
  config.vm.define "appserver" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "appserver"
    app.vm.network :private_network, ip: "10.10.10.20"

    app.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
        "app" => ["appserver"],
        "app:vars" => {"db_host" => "10.10.10.10"}
      }
      ansible.extra_vars = {
        "deploy_user" => "vagrant",
        "nginx_sites" => {
          "default" => [
            "listen 80",
            "server_name \"reddit\"",
            "location / { proxy_pass http://127.0.0.1:9292;}"
          ]
        }
      }
    end
  end
```

### molecule & testinfra
molecule позволяет автоматизировать тестирование ролей Ansible, выполняя при этом автоматический provisioning виртуальной машины и запуск линтеров. 
После установки зависимостей (molecule, testinfra, python-vagrant) нам необходимо проинициализировать заготовки тестов в каталоге с ролью:
```bash
ansible/roles/db$ molecule init scenario --scenario-name default -r db -d vagrant
```
Здесь:
-r <role>
-d <driver>
В результате получаем каталог molecule/default с соответствующими файлами:
```bash
weisdd_infra/ansible/roles/db$ tree molecule/
molecule/
└── default
    ├── INSTALL.rst
    ├── molecule.yml
    ├── playbook.yml
    ├── prepare.yml
    └── tests
        ├── __pycache__
        │   ├── test_default.cpython-36.pyc
        │   └── test_default.cpython-36-PYTEST.pyc
        └── test_default.py

```
db/molecule/default/molecule.yml - описание создаваемой в процессе тестирования виртуальной машины и применяемых линтеров:
```yaml
---
dependency:
  name: galaxy
driver:
  name: vagrant
  provider:
    name: virtualbox
lint:
  name: yamllint
platforms:
  - name: instance
    box: ubuntu/xenial64
provisioner:
  name: ansible
  lint:
    name: ansible-lint
verifier:
  name: testinfra
  lint:
    name: flake8
```

molecule/default/playook.yml
```yaml
---
- name: Converge
  hosts: all
  vars:
    mongo_bind_ip: 0.0.0.0
  become: true
  roles:
    - role: db
```
Здесь мы задаём переменные и указываем роль, используемую в тестировании. При необходимости, указываем become. - В общем, вполне себе обычный плейбук.


Создание машины:
```bash
$ molecule create
```
Вывод списка поднятых машин:
```bash
$ molecule list
```
Подключение к VM:
```bash
$ molecule login -h <host>
$ molecule login -h instance
```
Note: instance - дефолтное имя в конфигурации molecule (db/molecule/default/molecule.yml).

Применение плейбука:
```bash
$ molecule converge
```

Запуск тестов:
```bash
$ molecule verify
```
Note:
  test         Test (lint, destroy, dependency, syntax,...)
  verify       Run automated tests against instances.


### Самостоятельное задание (стр. 62)
Задание:
Напишите тест к роли db для проверки того, что БД слушает по нужному порту (27017). Используйте для этого один из модулей Testinfra

Решение:
ansible/roles/db/molecule/default/tests/test_default.py
```python
def test_mongo_port_is_open(host):
    port = host.socket("tcp://0.0.0.0:27017")
    assert port.is_listening
```

Задание:
Используйте роли db и app в плейбуках packer_db.yml и packer_app.yml и убедитесь, что все работает как прежде (используйте теги для запуска только нужных тасков, теги указываются в шаблоне пакера).

Решение:
Из соответствующих плейбуков нужно удалить поэтапные инструкции по установке нужного софта и добавить подключение роли: 
ansible/playbooks/packer_db.yml
```yaml
---
- name: Install MongoDB
  hosts: all
  become: true
  roles:
    - db
```
ansible/playbooks/packer_app.yml
```yaml
---
- name: Install Ruby, Bundler, build-essential
  hosts: all
  become: true
  roles:
    - app

```

Далее меняем описание provisioners в файлах с шаблонами packer:
packer/db.json
```json
    "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "ansible/playbooks/packer_db.yml",
            "ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"]
        }
    ]
```
packer/app.json
```json
    "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "ansible/playbooks/packer_app.yml",
            "ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"],
            "extra_arguments": ["--tags", "ruby"]
        }
    ]
```
Здесь следует обратить внимание на две вещи:
1. packer не в курсе, где лежит папка с ролями, поэтому нам необходимо явно задать путь через соответствующую переменную окружения:
  "ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"]
2. поскольку из всех задач, описанных в роли app, в контексте packer'а нас интересует только установка компонентов ruby, то необходимо воспользоваться тэгом "ruby". Его можно передать через параметр "extra_argunents":
  "extra_arguments": ["--tags", "ruby"]
