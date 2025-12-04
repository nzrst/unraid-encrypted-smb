#!/bin/bash
# Auto-mount LUKS container at /mnt/secure after array start

CONTAINER="/mnt/cache/secure/container1.img"
KEYFILE="/mnt/cache/secure/container1.key"
MAPPER_NAME="securecontainer1"
MOUNTPOINT="/mnt/secure"

echo "=== Starting LUKS automount script ==="

# Wait for cache to be available
while [ ! -d /mnt/cache ]; do
  echo "Waiting for /mnt/cache to be available..."
  sleep 2
done

# Wait for the container file to exist
while [ ! -f "$CONTAINER" ]; do
  echo "Waiting for container file: $CONTAINER"
  sleep 2
done

# Open the LUKS container if not already open
if ! cryptsetup status "$MAPPER_NAME" >/dev/null 2>&1; then
  echo "Opening LUKS container..."
  cryptsetup open "$CONTAINER" "$MAPPER_NAME" --key-file "$KEYFILE"
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to open LUKS container."
    exit 1
  fi
else
  echo "LUKS container already open as /dev/mapper/$MAPPER_NAME"
fi

# Ensure mountpoint exists
if [ ! -d "$MOUNTPOINT" ]; then
  echo "Creating mountpoint: $MOUNTPOINT"
  mkdir -p "$MOUNTPOINT"
  chown nobody:users "$MOUNTPOINT"
  chown 777 "$MOUNTPOINT"
fi

# Mount if not already mounted
if ! mountpoint -q "$MOUNTPOINT"; then
  echo "Mounting /dev/mapper/$MAPPER_NAME at $MOUNTPOINT..."
  mount /dev/mapper/"$MAPPER_NAME" "$MOUNTPOINT"
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to mount /dev/mapper/$MAPPER_NAME on $MOUNTPOINT."
    exit 1
  fi
else
  echo "$MOUNTPOINT is already mounted."
fi

echo "=== LUKS container mounted successfully at $MOUNTPOINT ==="

if [ -x /etc/rc.d/rc.samba ]; then
  echo "Restarting Samba..."
  /etc/rc.d/rc.samba restart
fi
