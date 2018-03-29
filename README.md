# Purpose

The intent is to distribute a base container for developing, building, and regressing RPMs.  Due to lowering security to allow the architecture to work properly, this container is not meant to run as a service container for application deployment.  

# Design Decisions

1. Allow user to mount their workspace - With docker, the ability to pass in -u to specify the user/group works well in most scenerios.  The rpmbuild tool, however, requires the arbitrary UIDs to have a username.  See http://blog.dscpl.com.au/2015/12/random-user-ids-when-running-docker.html for details of this scenerio.  We used NSS Wrapper for this to allow the uid to be assigned the username rpmbuilder at runtime.

1. Allow sudoers access for testing install in container - NSS Wrapper does not play nicely with sudo due to LD_PRELOAD and other environment variables needed by NSS Wrapper to properly work.  The sudoers file was modified to allow LD_PRELOAD and other environmental variables that are important for sudo to work.

# How to use this image

With each of the following sections the layout of your repository must match how a rpmbuild directory would look on a system as described at https://wiki.centos.org/HowTos/SetupRpmBuildEnvironment with at min SOURCES and SPECS folder.  An example git layout is below:

```git
.git
SPECS
  hello.spec
SOURCES
  hello1.patch
  hello.tar.gz
```

## Start an instance

```console
$ docker run -it -u `id -u`:`id -g` -v `pwd`:/rpmbuilder ciscosecuritytrustops/rpmbuilder:<tag> /bin/bash 
```

... where `tag` is the version of the container.  The host volume must be mounted to /rpmbuilder in the container as this is the home directory of the rpmbuilder user.

## Start an instance with signing

```console
$ docker run -i --rm -u `id -u`:`id -g` -e 'GPG_KEY_FILE=/run/GPG-KEY.key' -e 'GPG_KEY_ID=89A86901' -e 'GPG_PASSPHRASE=passphrase' -v `pwd`/mykey.key:/run/GPG-KEY.key -v ${WORKSPACE}:/rpmbuilder ciscosecuritytrustops/rpmbuilder:<tag> /bin/bash 
```

## Using a custom Dockerfile

It may be that a missing package may be needed that is not available in the base image.  An example below shows how you can build a customer Docker image using ciscosecuritytrustops/rpmbuilder as the base image.

```console
FROM ciscosecuritytrustops/rpmbuilder:rpmbuilder:7.4.1708-3

sudo yum install myspecial_package
``` 

## Environment Variables

When you start the image, you can adjust some configuration passing one or more environment variables on the `docker run` command line.

### `GPG_KEY`

(Optional) The GPG key for signing.

### `GPG_ID`

(Optional unless GPG_KEY specified) The GPG key ID.

### `GPG_PASSPHRASE`

(Optional) The passphrase for signing.

## Docker Secrets

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load keys and passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. For example:

```console
$ docker run --name some-mysql -e MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql-root -d %%IMAGE%%:tag
```

Currently, this is only supported for `GPG_KEY`.


# Caveats
