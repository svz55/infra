#!/bin/bash
set -e

cd /home/appuser
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install

#Запускаем сервер приложения в папке проект:
#$ puma -d
#Проверьте что сервер запустился и на каком порту он слушает:
#$ ps aux | grep puma
