---
title: "Networking Between Kubernetes Components"
date: 2018-03-01T17:00:00-05:00
tags: [infrastructure, kubernetes, security]
description: "Explore the network connectivity between core Kubernetes components."
---

In this post, we'll take a deeper dive into the network connectivity between core Kubernetes components: apiserver, controller manager, and scheduler on the servers; kubelet and kube proxy on the nodes; and etcd infrastructure.

### Defining components ###

__Server__: Each server referenced here is effectively a logical collection of processes.  These could be combined onto the same physical or virtual hardware (i.e. run the Kubernetes server services along with the etcd services on the same hosts).

__Service__: Process running on the server.

__Endpoint__: Endpoints are network endpoints exposed from the respective service.  Each endpoint has the following defined:

* Network Protocol (i.e. TCP) and Communication Protocol (i.e. HTTPS)
* Listen IP: Flag used to specify listen IP
* Port: Flag used to set listen port
* Certificate: Flag used to set the service's public certificate file path
* Key: Flag used to set the service's private key file path
* Client Trust: Flag used to set the service's CA file path for client authentication

__Connection__: Represents the network connection from a process to a network endpoint on another process.

__Connection Properties__: Shows the flags used to configure a connection:

* Target: Flag used to specify endpoint connection info (i.e. hostname & IP)
* Certificate: Flag used to set the client's public certificate file path
* Key: Flag used to set the client's private key file path
* Trust: Flag used to set the CA file path to verify server authenticity

The diagram below illustrates the core Kubernetes components, their connections and exposed endpoints, and the flags representing each of their connection properties.

![Kubernetes Network Connectivity](/img/posts/2018/kubernetes-networking/connection-diagram.svg)

### What the diagram isn't ###

Fist, let's go over what the diagram isn't intended to be.  The diagram above is not a full network diagram.  It is intended only to show connectivity that is established between components during cluster operation.  It does not include client connectivity or runtime connectivity, such as the process of invoking `kubectl exec`.  _(Though that process is not explicitly shown, the basis of the process is the kube-apiserver process initiates via connection to the kubelet running the target container, which is shown.)_

The diagram omits the load balancer tier that sits between the nodes and the apiserver pool.  This load balancer tier would be run in a [layer 4 mode](https://www.nginx.com/resources/glossary/layer-4-load-balancing/) to allow for client-cert authentication to the apiservers.  This means that the load balancer will simply pass the packets from the source node to one of the apiservers without doing anything with TLS or HTTP manipulation, thus being effectively transparent at this logical level.

### Services ###

#### API Servers ####

A HTTP based API service is provided by the kube-apiserver process.  This is the point of interaction for all Kubernetes components.  The apiserver interacts with etcd for persistent storage and communicates with the kubelet process on nodes when invoking commands against pods via `kubectl exec`.  These will typically be load balanced to provide high availability.

#### Controller Manager & Scheduler ####

The kube-controller-manager and kube-scheduler processes communicate with the API locally over HTTP (see details in the security section below).  These will only communicate with the local apiserver service and won't go through a load balancer like all other processes.

#### Kubelet & Kube Proxy ####

The kubelet and kube-proxy proceses provide all connection properties via a `kubeconfig` file whose path is passed in via a single flag.

### Additional Notes on Security ###

The certificates used here are to guarantee authenticity--both from the client's perspective and the server's.  This means that the server presents a certificate for the exposed service that must be verified by the client to begin encrypted transmission, and the client presents a certificate to the server to verify client authenticity.  With this in place, traffic between components is encrypted.  This, however, does not in and of itself guarantee the security of the cluster.

That said, when using RBAC with Kubernetes, the Organization field of client certificates can be used to assign roles to authenticating clients, so there is definitely overlap between authentication and authorization to some extent.  An example of this can be seen when generating a client certificate to be used by a cluster administration process.  By assigning an organization of `system:masters`, which puts authenticates the user as a member of the `system:masters` group, the user is granted `cluster-admin` rights.  This is because the `cluster-admin` cluster role is bound to `system:masters` group via a cluster role binding created by the cluster at startup.  To learn more about RBAC, see [the official Kubernetes documentation](https://kubernetes.io/docs/admin/authorization/rbac/).

For those looking carefully, there's one service in the diagram that isn't using HTTPS on the apiserver.  This is set up to communicate from the controller manager and scheduler to the apiserver.  This is locked down to listen only on 127.0.0.1 by default and should not be exposed outside of the server.  When exposing the `--insecure-bind-address` to additional IP ranges, nothing is authenticated.  No client certificates are used, no tokens are passed, and RBAC is not applied--exposing huge security risk.  __Leave this as at default values.__
