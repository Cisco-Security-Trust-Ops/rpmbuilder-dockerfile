#!/bin/bash

#Exit immediately if a command returns a non-zero status
set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

#If defined GPG_ID, then they want to sign RPMS
#You can pass in a file as GPG_KEY_FILE as it read a file from the container env
file_env 'GPG_KEY'
if [ -z "${GPG_KEY}" ]; then
  echo "GPG_KEY not defined; not setting state for signing RPMS" 1>&2
  envsubst < /tmp/rpmmacros_nosign.template > ${HOME}/.rpmmacros  
else
  if [ -z "${GPG_KEY_ID}" ]; then
    echo "GPG_KEY defined, but missing the GPG_KEY_ID required to set up the environment"
    exit 1
  fi
  #If using a development environment, it may be that we already have existing key.  Do
  #let's delete it from the key ring and add in the update
  set +e
  if [[ $(gpg --list-keys | grep -w ${GPG_KEY_ID}) ]]; then
    set -e
    fingerprint=`gpg --list-secret-keys --with-colons --fingerprint | grep ${GPG_KEY_ID} | sed -n 's/^fpr:::::::::\([[:alnum:]]\+\):/\1/p'`
    echo "Delete old key ${GPG_KEY_ID} with fingerprint ${fingerprint}"
    gpg --delete-secret-keys --batch ${fingerprint}
  fi
  set -e
  echo "${GPG_KEY}" > /tmp/gpg.key
  echo "Importing gpg key"
  gpg --allow-secret-key-import --import /tmp/gpg.key 2>&1
  echo "Envsubst, porting template over to rpmmacros"
  envsubst < /tmp/rpmmacros_sign.template > ${HOME}/.rpmmacros
  unset GPG_KEY
  rm /tmp/gpg.key
fi

CUR_UID=`id -u rpmbuilder`
CUR_GID=`id -g rpmbuilder`

CONTAINER_UID=`id -u`
CONTAINER_GID=`id -g`

echo "Container cur_uid:=${CUR_UID} container_uid=${CONTAINER_UID}"
echo "Container cur_gid:=${CUR_GID} container_gid=${CONTAINER_GID}"

if [ `id -u` -gt 0 ]; then

  export USER_ID=`id -u`
  export GROUP_ID=`id -g`
  envsubst < /tmp/passwd.template > ${NSS_WRAPPER_PASSWD}
  envsubst < /tmp/group.template > ${NSS_WRAPPER_GROUP}
  export LD_PRELOAD=libnss_wrapper.so
fi

if [ "$CUR_UID" != "$CONTAINER_UID" ]; then
  echo "CUR_UID not equal to CONTAINER_UID"
fi

if [ "$CUR_GID" != "$CONTAINER_GID" ]; then
  echo "CUR_GID not equal to CONTAINER_GID"
fi

exec "$@"
