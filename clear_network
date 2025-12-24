# Сброс кэша DNS
ipconfig /flushdns

# Сброс сетевых настроек TCP/IP
netsh int ip reset resetlog.txt
netsh winsock reset

# После этого перезагрузите компьютер

# Проверить видимость в сети
net view

# Проверить сетевое окружение
net config workstation

# Диагностика multicast DNS (для обнаружения)
nslookup -type=PTR _http._tcp.local

# Проверить видимость в сети
net view

# Проверить сетевое окружение
net config workstation

# Диагностика multicast DNS (для обнаружения)
nslookup -type=PTR _http._tcp.local

ipconfig /flushdns
ipconfig /registerdns
nbtstat -R
nbtstat -RR
netsh winsock reset
netsh int ip reset
