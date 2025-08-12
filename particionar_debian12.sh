#!/bin/bash

DISCO="/dev/sda"

# Verificar si el disco existe
if [ ! -b "$DISCO" ]; then
    echo "❌ Error: El disco $DISCO no existe."
    exit 1
fi

# Mostrar particiones actuales
echo "=== Particiones actuales en $DISCO ==="
lsblk -f $DISCO
echo "======================================"
sleep 2

# Desmontar particiones si están montadas
for i in 1 2 3 4 5; do
    if mount | grep "${DISCO}${i}" > /dev/null; then
        echo "Desmontando ${DISCO}${i}..."
        umount "${DISCO}${i}" || echo "⚠️ No se pudo desmontar ${DISCO}${i}"
    fi
done

# Crear tabla de particiones GPT
echo "Creando tabla de particiones GPT en $DISCO..."
if ! parted $DISCO mklabel gpt; then
    echo "❌ Error al crear la tabla de particiones GPT."
    exit 1
fi

# Crear particiones
echo "Creando partición /boot..."
parted -a optimal $DISCO mkpart primary ext4 1MiB 513MiB

echo "Creando partición swap..."
parted -a optimal $DISCO mkpart primary linux-swap 513MiB 4609MiB

echo "Creando partición raíz / ..."
parted -a optimal $DISCO mkpart primary ext4 4609MiB 25609MiB

echo "Creando partición /home..."
parted -a optimal $DISCO mkpart primary ext4 25609MiB 100%

# Notificar al kernel
echo "Actualizando tabla de particiones en el kernel..."
partprobe $DISCO
sleep 2

# Verificar que las particiones se hayan creado
for i in 1 2 3 4; do
    if [ ! -b "${DISCO}${i}" ]; then
        echo "❌ Error: La partición ${DISCO}${i} no se creó correctamente."
        exit 1
    fi
done

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
mkdir -p /mnt/boot /mnt/home
mount ${DISCO}1 /mnt/boot
mount ${DISCO}4 /mnt/home

# Mostrar particiones finales
echo "=== Particiones después del particionado ==="
lsblk -f $DISCO
echo "============================================"
