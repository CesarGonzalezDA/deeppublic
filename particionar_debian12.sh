#!/bin/bash

# Disco objetivo (modificar según sea necesario)
DISCO="/dev/sda"

# Mostrar particiones actuales
echo "=== Particiones actuales en $DISCO ==="
lsblk -f $DISCO
echo "======================================"
sleep 2

# Crear tabla de particiones GPT
echo "Creando tabla de particiones GPT en $DISCO..."
parted $DISCO mklabel gpt

# Crear partición /boot
echo "Creando partición /boot..."
parted -a optimal $DISCO mkpart primary ext4 1MiB 513MiB

# Crear partición swap
echo "Creando partición swap..."
parted -a optimal $DISCO mkpart primary linux-swap 513MiB 4609MiB

# Crear partición raíz /
echo "Creando partición raíz / ..."
parted -a optimal $DISCO mkpart primary ext4 4609MiB 25609MiB

# Crear partición /home o /data
echo "Creando partición /home..."
parted -a optimal $DISCO mkpart primary ext4 25609MiB 100%

# Esperar a que el sistema reconozca las nuevas particiones
sleep 2

# Formatear particiones
echo "Formateando particiones..."
mkfs.ext4 ${DISCO}1
mkswap ${DISCO}2
mkfs.ext4 ${DISCO}3
mkfs.ext4 ${DISCO}4

# Activar swap
swapon ${DISCO}2

# Montar particiones
echo "Montando particiones en /mnt..."
mount ${DISCO}3 /mnt
mkdir /mnt/boot /mnt/home
mount ${DISCO}1 /mnt/boot
mount ${DISCO}4 /mnt/home

# Mostrar particiones finales
echo "=== Particiones después del particionado ==="
lsblk -f $DISCO
echo "============================================"
