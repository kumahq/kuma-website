# Timeout

The main purpose of this guide is to get you familiar with the concept of [`Timeout`](../policies/timeout.md) in Kuma and how to manipulate configuration if the service starts to respond slower.

## Before you start

* Install Kuma following the [Standalone deployment instruction](../deployments/stand-alone.md/). Ensure to enable `ZoneEgress`.
* Get familiar with concept of [`Timeout`](../policies/external-services.md)

## Timeout configuration for communication between services

1. Install [demo application](https://github.com/kumahq/kuma-demo/tree/master/kubernetes)

```sh
kubectl apply -f https://bit.ly/demokuma
```
2. Expose GUI
 
```
kubectl port-forward service/frontend -n kuma-demo 8080
```
 
3. Enter the GUI through your browser `http://localhost:8080` c
 
4. Let's introduce some delay between `frontend` and `backend`
```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: FaultInjection
mesh: default
metadata:
 name: fi1
spec:
 sources:
   - match:
       kuma.io/service: frontend_kuma-demo_svc_8080
       version: "v8"
 destinations:
   - match:
       kuma.io/service: backend_kuma-demo_svc_3001
       kuma.io/protocol: http
       version: "v0"
 conf:       
   delay:
     percentage: 100
     value: 5s' | kubectl apply -f -
```
 
The above change is going to introduce 5 second delay for responses from backend to frontend.
5. Refresh the website, you should notice that it takes much longer to load to the main page.
6. Let's now define request timeout to backend service to be lower than the delay that we introduced.
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: Timeout
mesh: default
metadata:
 name: timeouts-backend
spec:
 sources:
   - match:
       kuma.io/service: '*'
 destinations:
   - match:
       kuma.io/service: 'backend_kuma-demo_svc_3001'
 conf:
   http:
     requestTimeout: 4s" | kubectl apply -f -
```
7. Refresh the website, you should notice that it doesn’t load anymore.
8. We can now increase request timeout to a value bigger than delay.
 
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: Timeout
mesh: default
metadata:
 name: timeouts-backend
spec:
 sources:
   - match:
       kuma.io/service: '*'
 destinations:
   - match:
       kuma.io/service: 'backend_kuma-demo_svc_3001'
 conf:
   http:
     requestTimeout: 6s" | kubectl apply -f -
```
 
9. Refresh the website, and you should notice that website now can load!

## What's happened?
In the beginning, we had a working service without any delays. After introducing a delay in communication of the frontend application with the backend we could observe that the page still works but it takes more time to load. The introduction of `request timeout` caused the response from the backend to be dropped because it took longer than the defined limit. After we increased the timeout it starts to work again!
