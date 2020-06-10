---
title: Digests in Docker
date: 2020-06-10T09:00:00-05:00
tags: [docker]
description: Shedding a bit of light around what the SHA256 sum does and how it is used in Docker.
---

Most Docker images are run as containers by invoking something along the lines of `docker run <image>:<tag>`. However, it's also possible--and often necessary for security purposes--to run by also specifying `@sha256:<digest>`. But what does this actually do, and what security vectors does this actually provide?

## What is a Docker digest?

Starting Docker containers requires an image, which is presented in the format of `[namespace/]<image-name>` followed by a tag `:<tag-name>`. If no tag is specified, `latest` is used. This tag is a pointer to an image--a set of files and metadata that Docker can use to run a container. Some images fall under the root namespace, such as `ubuntu`, which we'll see in the demos below.

Docker digest is provided as a hash of a Docker image supported by the Docker v2 registry format. This hash is generated as `sha256` and is deterministic based on the image build. This means that so long as the Dockerfile and all build components (base image selected in `FROM`, any files downloaded or copied into the image, etc) are unchanged between builds, the built image will always resolve to the same digest. This is important as a change in digest indicates that something changed in the image.

More information about images can be found in [Docker documentation](https://docs.docker.com/engine/reference/commandline/images/)

## Let's see it in action

Digests for pulled images can be listed by running `docker images --digests` (lines wrapped for better viewability):

```no-highlight
$ docker images --digests
REPOSITORY                TAG                 DIGEST
    IMAGE ID            CREATED             SIZE
ubuntu                    16.04               sha256:db6697a61d5679b7ca69dbde3dad6be0d17064d5b6b0e9f7be8d456ebb337209
    005d2078bdfa        6 weeks ago         125MB
ubuntu                    20.04               sha256:8bce67040cd0ae39e0beb55bcb976a824d9966d2ac8d2e4bf6119b45505cee64
    1d622ef86b13        6 weeks ago         73.9MB
```

Here we can see that we've pulled two tags for the Ubuntu image - 2016 and 2020 LTS based containers. Let's take a look at them and see what release they're running.

Note: _`uname -a`, which is commonly used to check a host's running version, won't work inside containers as it reports based on the running kernel, which is shared from the host OS._

20.04:

```no-highlight
$ docker run --rm ubuntu:20.04 /bin/bash -c "cat /etc/lsb-release"
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=20.04
DISTRIB_CODENAME=focal
DISTRIB_DESCRIPTION="Ubuntu 20.04 LTS"
```

16.04:
```no-highlight
$ docker run --rm ubuntu:16.04 /bin/bash -c "cat /etc/lsb-release"
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=16.04
DISTRIB_CODENAME=xenial
DISTRIB_DESCRIPTION="Ubuntu 16.04.6 LTS"
```

All good. We've run the tags we wanted and verified that the container contents are what we'd expect.

Now, let's re-run 20.04 with a checksum (copied from the output of `docker images --digests` above):

```no-highlight
$ docker run --rm ubuntu:20.04@sha256:8bce67040cd0ae39e0beb55bcb976a824d9966d2ac8d2e4bf6119b45505cee64 /bin/bash -c "cat /etc/lsb-release"
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=20.04
DISTRIB_CODENAME=focal
DISTRIB_DESCRIPTION="Ubuntu 20.04 LTS"
```

Also what we'd expect to see. But now, let's instead copy the digest of the 16.04 image:

```no-highlight
$ docker run --rm ubuntu:20.04@sha256:db6697a61d5679b7ca69dbde3dad6be0d17064d5b6b0e9f7be8d456ebb337209 /bin/bash -c "cat /etc/lsb-release"
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=16.04
DISTRIB_CODENAME=xenial
DISTRIB_DESCRIPTION="Ubuntu 16.04.6 LTS"
```

Now, we're showing a tag of `20.04`, but our image is `16.04`. Let's investigate:

I'll kick off an idle process in new container: `docker run --rm -ti ubuntu:20.04@sha256:db6697a61d5679b7ca69dbde3dad6be0d17064d5b6b0e9f7be8d456ebb337209 /bin/bash` using the tag and digest from the last scenario above, then check the `docker ps` output (again wrapped for viewability):

```no-highlight
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED
    STATUS              PORTS                    NAMES
44739fa037d2        ubuntu:20.04        "/bin/bash"              2 seconds ago
    Up 2 seconds                                 xenodochial_maxwell
```

We can now see that `docker ps` output shows the tag that was specified by the `docker run` command.

We can even use tags that don't exist:

```no-highlight
$ docker run --rm ubuntu:tag-does-not-exist@sha256:db6697a61d5679b7ca69dbde3dad6be0d17064d5b6b0e9f7be8d456ebb337209 /bin/bash -c "cat /etc/lsb-release"
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=16.04
DISTRIB_CODENAME=xenial
DISTRIB_DESCRIPTION="Ubuntu 16.04.6 LTS"
```

And even `docker pull` works for that non-existent tag:

```no-highlight
$ docker pull ubuntu:tag-does-not-exist@sha256:db6697a61d5679b7ca69dbde3dad6be0d17064d5b6b0e9f7be8d456ebb337209
sha256:db6697a61d5679b7ca69dbde3dad6be0d17064d5b6b0e9f7be8d456ebb337209: Pulling from library/ubuntu
e92ed755c008: Pull complete
b9fd7cb1ff8f: Pull complete
ee690f2d57a1: Pull complete
53e3366ec435: Pull complete
Digest: sha256:db6697a61d5679b7ca69dbde3dad6be0d17064d5b6b0e9f7be8d456ebb337209
Status: Downloaded newer image for ubuntu@sha256:db6697a61d5679b7ca69dbde3dad6be0d17064d5b6b0e9f7be8d456ebb337209
docker.io/library/ubuntu:tag-does-not-exist@sha256:db6697a61d5679b7ca69dbde3dad6be0d17064d5b6b0e9f7be8d456ebb337209
```

The digest is scoped to the image namespace and name, however, so the following does not work when pulling a non-existent image even though that digest exists on the Docker host:

```no-highlight
$ docker pull not-an-image:tag-does-not-exist@sha256:db6697a61d5679b7ca69dbde3dad6be0d17064d5b6b0e9f7be8d456ebb337209
Error response from daemon: pull access denied for not-an-image, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
```

## So what's actually going on here

The above may seem counter-intuitive. Often sha256 checksums are used to verify a payload, such as when using package managers to install or upgrade applications.

This implementation behaves more like `git`. In git, each commit has a hash - a checksum of the commit contents - that can be used to uniquely identify a change set within a repository. Unlike git, however, which allows brute-forcing an update to a commit that would break the checksum (i.e. new changes on an existing commit), the Docker digest is used both as an identifier (ability to look up) and a verification (ensure that the image pointing to what's intended).

Docker tags behave much like git tags as well. A tag can point to one and only one digest, but while digests are immutable, tags can be updated to move the pointeer to a new digest. That means that running `docker run ubuntu:20.04` may yield a different result between runs. This can present risk in terms of security and operational impact as it allows for changes with no obvious visibility.

The solution to preventing change is pinning a digest to the running container - done by appending `@sha256:<digest>`. This solves the issue of allowing a container to change unexpectly.

That said, given the examples above, we can see that when a digest is specified at container startup, the tag is no longer respected in any way. The Docker registry simply tracks pointers to which digest a tag references at present, so in order to maintain backwards compatibility for previously started images, it does not check the tag against the registry at startup.

Consider this scenario:

You're running a production container, and you want to pin a particular distribution version (let's stick with Ubuntu here), so you pin the image tag to `ubuntu:20.04@sha256:8bce67040cd0ae39e0beb55bcb976a824d9966d2ac8d2e4bf6119b45505cee64`. A week later, that image may receive security patches, and the tag will be updated to a new digest as its contents have changed. If the Docker runtime were to check the registry at startup to ensure that the tag specified maps properly to the digest specified, things get complicated in a hurry. To keep things functional, when this scenario is encountered, Docker prioritizes the digest specified and runs that regardless of whether the tag is or even ever was existent or pointing to the referenced digest.

The behavior also defaults to show the tag being run (i.e. `docker ps` output) as the tag specified at container creation time and does not automatically map a running digest back to a local image tag that maps to the image. This also would be quite complicated as multiple tags can point to the same digest and tags can point to different digests over time.

tl;dr - When running Docker containers, it is a good idea to specify the digest. Specifying a digest takes precedent over the tag, and unless verified at some other stage, the tag may not and my never have correlated with a running container's base image.
