---
title: "Building a Secure Public Key Infrastructure for Kubernetes"
date: 2018-02-28T10:00:00-05:00
tags: [infrastructure, kubernetes, security]
description: "Explore the CFSSL tool and use it to create a PKI that is secure, manageable, and maintainable for Kubernetes infrastructure."
---

The target for this implementation is primarily to support Kubernetes infrastructure.  Before getting into the specifics of the infrastructure setup and server configurations, I'll go over project goals for this implementation along with known limitations and how [CFSSL](https://github.com/cloudflare/cfssl)--a tool created by CloudFlare for generating and signing certificates--is designed.

## Goals ##

### Secure ###

First and foremost - this is a [PKI](https://en.wikipedia.org/wiki/Public_key_infrastructure).  We need it to be secure.  If the PKI itself can't be trusted, then nothing depending on the PKI can be trusted.  There are a few specific goals here:

#### Keys must never leave their hosts ####

When generating certificate pairs, the private keys are never transferred across the network.  This behaves much like public CAs: a private key and certificate signing request (CSR) are generated, the CSR is transferred to the certificate authority (CA), and the signed public certificate is returned to the requesting server.

#### All signing requests must be authenticated ####

When making requests, the requesting server must authenticate to the CA.  Unauthorized servers must not be allowed to request certificates from the CA.

#### All signing requests must be encrypted ####

Because credentials are being passed via the signing process, we need to make sure that all network transmission is encrypted.  This will be done using TLS.

### Manageable ###

I don't want babysitting a PKI to be a full time job.  I want to ensure that it's properly configured and secured, then let it work without needing to do anything manually.  The infrastructure will be distributed and configured via configuration management.

### Known Omissions ###

Because of the scope of distribution (each CA will service a single Kubernetes cluster), we can establish a few facts about the infrastucture:

* All endpoints that trust the CA are known
* The entirety of the CA can be blown away and recreated trivially

This will sign a root CA and use that to directly sign any certificates for the cluster.  In a less controlled environment (i.e. distributing to clients), creating an offline root CA with an online trusted intermediate CA allows for much easier management--a root CA can authorize multiple intermediate CAs, and if security issues are found with an intermediate CA, its trust can be revoked without needing to alter any clients.

Because the CA can be easily blown away and recreated, the CA isn't implementing revocation lists.

The CA server also isn't set up to provide OCSP (Online Certificate Status Protocol) to verify certificate status real-time.

_Both CRL and OCSP can be implemented using the tools below, but I'm not going to cover it in this post._

## CFSSL ##

To build out the PKI, we'll use [CFSSL](https://github.com/cloudflare/cfssl), an open source golang project developed by CloudFlare.  It supports the goals explained above, and it's both easily compiled and fully contained.  That makes the infrastructure much more manageable.

### Multiple Binaries ###

The CFSSL project is comprised of multiple binaries all built using the same base packages.  The ones we'll deal with are:

#### CFSSL ####

`cfssl` is a binary that takes the form of `cfssl <command> [args]` (similar to tools like `docker`, `git`, and `kubectl`).  It can be used locally (by providing a keypair that will be used to sign certificates) or remotely (request certificates from an instance running a CFSSL server).

#### CFSSLJSON ####

`cfssljson` is used to unmarshal JSON responses from the CFSSL server (whether local or remote) for easy command line manipulation.  It can be used to save certificates off to files or expose them via stdout.  Unlike `cfssl`, `cfssljson` does not use subcommands.

#### MultirootCA ####

`multirootca` is designed as a CFSSL server that exposes few endpoints but is capable of signing certificates using multiple certificate authorities, each having its own policies and authentication scheme.  Like `cfssljson`, `multirootca` does not use subcommands.  Its API behavior is very similar to `cfssl serve`, but it only exposes the sign, authsign and info endpoints.

## Signing Certificates ##

### Local Signing CA ###

As mentioned above, the `cfssl` binary can be used to sign certificates locally.  This is a simple process and just needs arguments for `-ca` and `-ca-key`, pointing to files that contain the signing CA public certificate and private key respectively.

However, this requires that any node that is going to sign a certificate needs to have both the CA public key and the CA private key.  In the case of the Kubernetes cluster, that means that all api servers, nodes, etc each need copies of the CA private key.  This means that they key is transferred across the network and that copies of the CA keys are stored on many servers.  This is really bad from a security perspective, as it is much easier to restrict and audit access to a single server than to a farm of servers.

### Remote Signing CA ###

To get around the problem of CA private key distribution mentioned above, we could use the `cfssl` tool locally on each machine to generate the private key and signing request on the target node, transfer the CSR file to a CA server, invoke `cfssl` locally on the CA server to locally sign the certificate, and transfer the signed certificate back to the requester.  Lucky for us, CFSSL already includes a web API with bundled server that handles this process.

By using the `cfssl serve` subcommand, we can run a web server that runs on the CA server and can sign requests without having to distribute the CA private key anywhere--it remains on the signing server.  It supports TLS, so communication between the requester and the signing authority is encrypted.  It also supports authentication tokens for client authentication when signing requests, preventing unauthorized and anonymous requests from being serviced if desired--which covers our security goals above--or at least it should.  __Do not use `cfssl serve` to set up a secure remote signing endpoint.__

Despite having authentication tokens, current CFSSL builds (as of the time of this writing) don't enforce authentication on all endpoints.  When signing an existing CSR, the authentication process is properly followed, and the client must authenticate prior to receiving a signed certificate from the CA.  `cfssl serve` also exposes the following endpoint: `/api/v1/cfssl/newcert`, which generates and transfers the public certificate and private key then transfers them back to the requester.  This has two major issues:

1. The requesting client never authenticates during this process--meaning anyone with access to the endpoint can get a valid, signed certificate anonymously or with an incorrect token
2. The private key leaves the system and is transferred across the network

So what can we do about this?  CFSSL includes another tool that solves these issues--`multirootca`.  While `multirootca` is capable of signing for multiple CAs, it can also be used to sign for just a single CA, and that CA can be specified at runtime to be the default signing authority, making the behavior very similar to `cfssl serve` with a more restricted set of exposed endpoints.  This means that unlike `cfssl serve`, when using `multirootca` it is not possible to get around authentication when signing.

## Infrastructure ##

The CA used by this PKI is set up to be a remote signing authority over TLS.  This means that the network port the system needs to expose to the certificate requesters is the server port specified when running `multirootca`.  The service can be stopped when not needed if desired for additional security.  Because this server contains the CA's private key, access should be restricted and audited.

## Configuration ##

Now that we know what CFSSL and its components do, let's start configuring it.

### Build ###

Building CFSSL is simple.  It requires a system set up with golang version 1.6 or higher to do the builds.

```bash
# Main CFSSL Binary
go get -u github.com/cloudflare/cfssl/cmd/cfssl

# JSON Response Decode Tool
go get -u github.com/cloudflare/cfssl/cmd/cfssljson

# MutlirootCA Server
go get -u github.com/cloudflare/cfssl/cmd/multirootca
```

The builds are supported by the `golang` official Docker containers, and cross-compiling is simple by using the `GOOS` environment variable at build time.

For more details, check out the [CFSSL Readme](https://github.com/cloudflare/cfssl/blob/master/README.md).

Once that the binaries are built, we can distribute and use them to establish a CA and start using it to sign certs.

### Initialize the CA ###

The goal of CA initialization is to get a CA online that enforces authorization, secures its network transfer with TLS, and doesn't require user intervention to do so.

The CA will need `cfssl` and `cfssljson` available on the system.  After binary distribution, the first thing we need to do to establish the CA is to generate a key pair that will be used to sign certificates.  CFSSL uses JSON for most of its configurations, so we'll generate a CSR payload in JSON.  This will have the same fields as a typical certificate request, but the JSON structure makes management and templating super easy:


```json
{
  "CN": "<ca_common_name>",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
     {
       "C": "<country>",
       "L": "<city>",
       "O": "<organization>",
       "OU": "<organization-unit>",
       "ST": "<state>"
     }
  ]
}

```

Now that a CSR profile has been created, we can initialize the signing CA:


```bash
cfssl gencert -initca <path-to-csr>.json | cfssljson -bare ca
```

This will generate the `ca.pem` and `ca-key.pem` files that we will reference throughout the process in the current working directory. __Be very careful with permissions on these files.__  The certificate and key names are defined by the `ca` argument passed in to `cfssljson`; if you want the pair to have a different name, just change `ca` to `<foo>`, and `<foo>.pem` and `<foo>-key.pem` will be generated instead.

Now we've got a CA established!

_Once again: if you're planning on using this in a less controlled environment (i.e. distributing the CA as a trusted authority for users), use this key pair to sign an intermediate, and use that to sign all of the certificates below for improved security and manageability._

### Configure Remote Signing ###

Before starting up a signing server, we'll need a certificate pair to secure TLS communication from clients.  In addition to the `cfssl` and `cfssljson` binaries, we'll need `multirootca` on the signing server to handle remote requests.

To do that, we'll use the CA we just created.  We can also reuse the CSR generated above.

We'll need to specify some configuration data, which will be reffered to below as `config.json`:

```json
{
  "signing": {
    "default": {
      "auth_key": "default",
      "expiry": "43800h",
      "usages": [
         "signing",
         "key encipherment",
         "client auth",
         "server auth"
       ]
     }
  },
  "auth_keys": {
    "default": {
      "key": "<signing-auth-key>",
      "type": "standard"
    }
  }
}
```

Once the signing config is created, we can generate the desired key pair:

```bash
cfssl gencert -ca=<ca>.pem -ca-key=<ca-key>.pem -config=<config.json> -hostname=<hostname> -profile=default <csr.json> | cfssljson -bare server
```

This will generate `server.pem` and `server-key.pem` in the working directory.

Next, we need to specify the CAs that can be used to sign remote requests.  This is done in an ini file (referred to as `multiroot-profile.ini` below):

```ini
[default]
private = file://<ca-key>.pem
certificate = <ca>.pem
config = <config.json>
```

__Note__: _All configuration paths in multiroot-profile.ini need to be relative paths; absolute paths are not supported at this time._

With the server profile created, we can invoke the server:

```bash
/usr/local/bin/multirootca \
            -a <ip>:<port> \
            -l default \
            -roots <multiroot-profile.ini> \
            -tls-cert <server.pem> \
            -tls-key <server-key.pem>
```

Using an IP address of `0.0.0.0` will listen on all IPv4.  `-l` default uses the `default` signing profile defined in `multiroot-profile.ini` for requests that have no signing profile assigned to them.

If you're running this in a server running systemd, the following can be used as the service file:

```systemd
[Unit]
Description=CFSSL PKI Certificate Authority
After=network.target

[Service]
User=ca
ExecStart=/usr/local/bin/multirootca \
            -a <ip>:<port> \
            -l default \
            -roots <multiroot-profile.ini> \
            -tls-cert <server.pem> \
            -tls-key <server-key.pem>
Restart=on-failure
Type=simple
WorkingDirectory=<cfssl-path>

[Install]
WantedBy=multi-user.target
```

With the process running, we can now securely sign requests remotely.

### Set Up Request Process ###

Each server that will request certificates needs to have `cfssl` and `cfssljson` tools available.  Once those tools are available, signing is pretty straightforward.  Each server will also need the CA's _public certificate_ on the filesystem.  It does not need to be in the system trust.

First, we'll need to create a signing request (referred to as `csr.json`):

```json
{
  "CN": "<hostname>",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
     {
       "C": "<country>",
       "L": "<city>",
       "O": "<organization>",
       "OU": "<organization-unit>",
       "ST": "<state>"
     }
  ]
}

```

Next, a request profile needs to be created (referred to as `request-profile.json`):

```json
{
  "signing": {
    "default": {
      "auth_remote": {
        "remote": "ca_server",
        "auth_key": "default"
      }
    }
  },
  "auth_keys": {
    "default": {
      "key": "<signing-auth-key>",
      "type": "standard"
    }
  },
  "remotes": {
    "ca_server": "<signing_server:port>"
  }
}
```

__Note:__ _The signing auth key here must match the signing auth key above._

Once those are created, we can request the certificate:

```bash
cfssl gencert -config=<request-profile.json> -hostname=<san-entries> -tls-remote-ca <ca.pem> -profile=default <csr.json> | cfssljson -bare <cert-name>
```

`san-entries` are a comma separated list of either DNS or IP SAN entries, and both prefixes should be omitted; CFSSL automatically adds the appropriate prefix.  Example: `-hostname=my-server.fqdn,127.0.0.1`.

`tls-remote-ca` can be omitted if the CA is trusted by the system trust.

After running the command, you will have a certificate and key pair signed by the established CA.  After signing, the `request-profile.json` file can be removed so no secrets are stored on the requesting machine.
