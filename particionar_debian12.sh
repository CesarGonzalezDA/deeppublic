#!/bin/bash

DISCO="/dev/sda"

echo "🔍 Verificando disco $DISCO..."

# Verificar si el disco existe
if [ ! -b "$DISCO" ]; then
    echo "❌ Error: El disco $DISCO no existe."
    exit 1
fi

# Desactivar swap si está activo
swapoff -a

# Desmontar particiones si están montadas
for i in 1 2 3 4; do
    if mount | grep "${DISCO}${i}" > /dev/null; then
        echo "🔄 Desmontando ${DISCO}${i}..."
        umount "${DISCO}${i}" || echo "⚠️ No se pudo desmontar ${DISCO}${i}"
    fi
done

# Verificar si el disco está en uso por algún proceso
if lsof | grep "$DISCO"; then
    echo "⚠️ El disco está en uso por algún proceso. No se puede continuar."
    exit 1
fi

# Crear tabla de particiones GPT
echo "🧱 Creando tabla de particiones GPT..."
parted -s $DISCO mklabel gpt

# Crear particiones
echo "📦 Creando particiones..."
parted -s -a optimal $DISCO mkpart primary ext4 1MiB 513MiB       # /boot
parted -s -a optimal $DISCO mkpart primary linux-swap 513MiB 4609MiB  # swap
parted -s -a optimal $DISCO mkpart primary ext4 4609MiB 25609MiB  # /
parted -s -a optimal $DISCO mkpart primary ext4 25609MiB 100%     # /home

# Notificar al kernel
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
echo "🧼 Formateando particiones..."
mkfs.ext4 ${DISCO}1
mkswap ${DISCO}2
mkfs.ext4 ${DISCO}3
mkfs.ext4 ${DISCO}4

# Activar swap
swapon ${DISCO}2

# Montar particiones
echo "📂 Montando particiones en /mnt..."
mount ${DISCO}3 /mnt
mkdir -p /mnt/boot /mnt/home
mount ${DISCO}1 /mnt/boot
mount ${DISCO}4 /mnt/home

# Mostrar resultado final
echo "✅ Particionado completo. Estado final:"
lsblk -f $DISCO
