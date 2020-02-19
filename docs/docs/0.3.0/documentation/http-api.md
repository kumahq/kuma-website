# HTTP API

Kuma ships with a RESTful HTTP interface that you can use to retrieve the state of your configuration and policies on every environment, and when running on Universal mode it will also allow to make changes to the state. On Kubernetes, you will use native CRDs to change the state in order to be consistent with Kubernetes best practices.

::: tip
**CI/CD**: The HTTP API can be used for infrastructure automation to either retrieve data, or to make changes when running in Universal mode. The [`kumactl`](../kumactl) CLI is built on top of the HTTP API, which you can also access with any other HTTP client like `curl`.
:::

By default the HTTP API is listening on port `5681`. The endpoints available are:

* `/meshes`
* `/meshes/{name}`
* `/meshes/{name}/dataplanes`
* `/meshes/{name}/dataplanes/{name}`

You can use `GET` requests to retrieve the state of Kuma on both Universal and Kubernetes, and `PUT` and `DELETE` requests on Universal to change the state.

## Meshes

### Get Mesh
Request: `GET /meshes/{name}`

Response: `200 OK` with Mesh entity

Example:
```bash
curl http://localhost:5681/meshes/mesh-1
```
```json
{
  "name": "mesh-1",
  "type": "Mesh",
  "mtls": {
    "ca": {
      "builtin": {}
    },
    "enabled": true
  },
  "tracing": {},
  "logging": {
    "backends": [
      {
        "name": "file-tmp",
        "format": "{ \"destination\": \"%KUMA_DESTINATION_SERVICE%\", \"destinationAddress\": \"%UPSTREAM_LOCAL_ADDRESS%\", \"source\": \"%KUMA_SOURCE_SERVICE%\", \"sourceAddress\": \"%KUMA_SOURCE_ADDRESS%\", \"bytesReceived\": \"%BYTES_RECEIVED%\", \"bytesSent\": \"%BYTES_SENT%\"}",
        "file": {
          "path": "/tmp/access.log"
        }
      },
      {
        "name": "logstash",
        "tcp": {
          "address": "logstash.internal:9000"
        }
      }
    ]
  }
}
```

### Create/Update Mesh
Request: `PUT /meshes/{name}` with Mesh entity in body

Response: `201 Created` when the resource is created and `200 OK` when it is updated

Example:
```bash
curl -XPUT http://localhost:5681/meshes/mesh-1 --data @mesh.json -H'content-type: application/json'
```
```json
{
  "name": "mesh-1",
  "type": "Mesh",
  "mtls": {
    "ca": {
      "builtin": {}
    },
    "enabled": true
  },
  "tracing": {},
  "logging": {
    "backends": [
      {
        "name": "file-tmp",
        "format": "{ \"destination\": \"%KUMA_DESTINATION_SERVICE%\", \"destinationAddress\": \"%UPSTREAM_LOCAL_ADDRESS%\", \"source\": \"%KUMA_SOURCE_SERVICE%\", \"sourceAddress\": \"%KUMA_SOURCE_ADDRESS%\", \"bytesReceived\": \"%BYTES_RECEIVED%\", \"bytesSent\": \"%BYTES_SENT%\"}",
        "file": {
          "path": "/tmp/access.log"
        }
      },
      {
        "name": "logstash",
        "tcp": {
          "address": "logstash.internal:9000"
        }
      }
    ]
  }
}
```

### List Meshes
Request: `GET /meshes`

Response: `200 OK` with body of Mesh entities

Example:
```bash
curl http://localhost:5681/meshes
```
```json
{
  "items": [
    {
      "type": "Mesh",
      "name": "mesh-1",
      "mtls": {
        "ca": {
          "builtin": {}
        },
        "enabled": true
      },
      "tracing": {},
      "logging": {
        "backends": [
          {
            "name": "file-tmp",
            "format": "{ \"destination\": \"%KUMA_DESTINATION_SERVICE%\", \"destinationAddress\": \"%UPSTREAM_LOCAL_ADDRESS%\", \"source\": \"%KUMA_SOURCE_SERVICE%\", \"sourceAddress\": \"%KUMA_SOURCE_ADDRESS%\", \"bytesReceived\": \"%BYTES_RECEIVED%\", \"bytesSent\": \"%BYTES_SENT%\"}",
            "file": {
              "path": "/tmp/access.log"
            }
          },
          {
            "name": "logstash",
            "tcp": {
              "address": "logstash.internal:9000"
            }
          }
        ]
      }
    }
  ]
}
```

### Delete Mesh
Request: `DELETE /meshes/{name}`

Response: `200 OK`

Example:
```bash
curl -XDELETE http://localhost:5681/meshes/mesh-1
```

## Dataplanes

### Get Dataplane
Request: `GET /meshes/{mesh}/dataplanes/{name}`

Response: `200 OK` with Mesh entity

Example:
```bash
curl http://localhost:5681/meshes/mesh-1/dataplanes/backend-1
```
```json
{
  "type": "Dataplane",
  "name": "backend-1",
  "mesh": "mesh-1",
  "networking": {
    "inbound": [
      {
        "interface": "127.0.0.1:11011:11012",
        "tags": {
          "service": "backend",
          "version": "2.0",
          "env": "production"
        }
      }
    ],
    "outbound": [
      {
        "interface": ":33033",
        "service": "database"
      },
      {
        "interface": ":44044",
        "service": "user"
      }
    ]
  }
}
```

### Create/Update Dataplane
Request: `PUT /meshes/{mesh}/dataplanes/{name}` with Dataplane entity in body

Response: `201 Created` when the resource is created and `200 OK` when it is updated

Example:
```bash
curl -XPUT http://localhost:5681/meshes/mesh-1/dataplanes/backend-1 --data @dataplane.json -H'content-type: application/json'
```
```json
{
  "type": "Dataplane",
  "name": "backend-1",
  "mesh": "mesh-1",
  "networking": {
    "inbound": [
      {
        "interface": "127.0.0.1:11011:11012",
        "tags": {
          "service": "backend",
          "version": "2.0",
          "env": "production"
        }
      }
    ],
    "outbound": [
      {
        "interface": ":33033",
        "service": "database"
      },
      {
        "interface": ":44044",
        "service": "user"
      }
    ]
  }
}
```

### List Dataplanes
Request: `GET /meshes/{mesh}/dataplanes`

Response: `200 OK` with body of Dataplane entities

Example:
```bash
curl http://localhost:5681/meshes/mesh-1/dataplanes
```
```json
{
  "items": [
    {
      "type": "Dataplane",
      "name": "backend-1",
      "mesh": "mesh-1",
      "networking": {
        "inbound": [
          {
            "interface": "127.0.0.1:11011:11012",
            "tags": {
              "service": "backend",
              "version": "2.0",
              "env": "production"
            }
          }
        ],
        "outbound": [
          {
            "interface": ":33033",
            "service": "database"
          },
          {
            "interface": ":44044",
            "service": "user"
          }
        ]
      }
    }
  ]
}
```

### Delete Dataplane
Request: `DELETE /meshes/{mesh}/dataplanes/{name}`

Response: `200 OK`

Example:
```bash
curl -XDELETE http://localhost:5681/meshes/mesh-1/dataplanes/backend-1
```

## Dataplane Overviews

### Get Dataplane Overview
Request: `GET /meshes/{mesh}/dataplane+insights/{name}`

Response: `200 OK` with Dataplane entity including insight

Example:
```bash
curl http://localhost:5681/meshes/default/dataplanes+insights/example
```
```json
{
 "type": "DataplaneOverview",
 "mesh": "default",
 "name": "example",
 "dataplane": {
  "networking": {
   "inbound": [
    {
     "interface": "127.0.0.1:11011:11012",
     "tags": {
      "env": "production",
      "service": "backend",
      "version": "2.0"
     }
    }
   ],
   "outbound": [
    {
     "interface": ":33033",
     "service": "database"
    }
   ]
  }
 },
 "dataplaneInsight": {
  "subscriptions": [
   {
    "id": "426fe0d8-f667-11e9-b081-acde48001122",
    "controlPlaneInstanceId": "06070748-f667-11e9-b081-acde48001122",
    "connectTime": "2019-10-24T14:04:56.820350Z",
    "status": {
     "lastUpdateTime": "2019-10-24T14:04:57.832482Z",
     "total": {
      "responsesSent": "3",
      "responsesAcknowledged": "3"
     },
     "cds": {
      "responsesSent": "1",
      "responsesAcknowledged": "1"
     },
     "eds": {
      "responsesSent": "1",
      "responsesAcknowledged": "1"
     },
     "lds": {
      "responsesSent": "1",
      "responsesAcknowledged": "1"
     },
     "rds": {}
    }
   }
  ]
 }
}
```

### List Dataplane Overviews
Request: `GET /meshes/{mesh}/dataplane+insights/`

Response: `200 OK` with Dataplane entities including insight

Example:
```bash
curl http://localhost:5681/meshes/default/dataplanes+insights
```
```json
{
  "items": [
    {
     "type": "DataplaneOverview",
     "mesh": "default",
     "name": "example",
     "dataplane": {
      "networking": {
       "inbound": [
        {
         "interface": "127.0.0.1:11011:11012",
         "tags": {
          "env": "production",
          "service": "backend",
          "version": "2.0"
         }
        }
       ],
       "outbound": [
        {
         "interface": ":33033",
         "service": "database"
        }
       ]
      }
     },
     "dataplaneInsight": {
      "subscriptions": [
       {
        "id": "426fe0d8-f667-11e9-b081-acde48001122",
        "controlPlaneInstanceId": "06070748-f667-11e9-b081-acde48001122",
        "connectTime": "2019-10-24T14:04:56.820350Z",
        "status": {
         "lastUpdateTime": "2019-10-24T14:04:57.832482Z",
         "total": {
          "responsesSent": "3",
          "responsesAcknowledged": "3"
         },
         "cds": {
          "responsesSent": "1",
          "responsesAcknowledged": "1"
         },
         "eds": {
          "responsesSent": "1",
          "responsesAcknowledged": "1"
         },
         "lds": {
          "responsesSent": "1",
          "responsesAcknowledged": "1"
         },
         "rds": {}
        }
       }
      ]
     }
    }
  ]
}
```

## Proxy Template

### Get Proxy Template
Request: `GET /meshes/{mesh}/proxytemplates/{name}`

Response: `200 OK` with Proxy Template entity

Example:
```bash
curl http://localhost:5681/meshes/mesh-1/proxytemplates/pt-1
```
```json
{
 "conf": {
  "imports": [
   "default-proxy"
  ],
  "resources": [
   {
    "name": "raw-name",
    "version": "raw-version",
    "resource": "'@type': type.googleapis.com/envoy.api.v2.Cluster\nconnectTimeout: 5s\nloadAssignment:\n  clusterName: localhost:8443\n  endpoints:\n    - lbEndpoints:\n        - endpoint:\n            address:\n              socketAddress:\n                address: 127.0.0.1\n                portValue: 8443\nname: localhost:8443\ntype: STATIC\n"
   }
  ]
 },
 "mesh": "mesh-1",
 "name": "pt-1",
 "selectors": [
  {
   "match": {
    "service": "backend"
   }
  }
 ],
 "type": "ProxyTemplate"
}
```

### Create/Update Proxy Template
Request: `PUT /meshes/{mesh}/proxytemplates/{name}` with Proxy Template entity in body

Response: `201 Created` when the resource is created and `200 OK` when it is updated

Example:
```bash
curl -XPUT http://localhost:5681/meshes/mesh-1/proxytemplates/pt-1 --data @proxytemplate.json -H'content-type: application/json'
```
```json
{
  "type": "ProxyTemplate",
  "name": "pt-1",
  "mesh": "mesh-1",
  "selectors": [
    {
      "match": {
          "service": "backend"
      }
    }
  ],
  "conf": {
    "imports": [
      "default-proxy"
    ],
    "resources": [
      {
        "name": "raw-name",
        "version": "raw-version",
        "resource": "'@type': type.googleapis.com/envoy.api.v2.Cluster\nconnectTimeout: 5s\nloadAssignment:\n  clusterName: localhost:8443\n  endpoints:\n    - lbEndpoints:\n        - endpoint:\n            address:\n              socketAddress:\n                address: 127.0.0.1\n                portValue: 8443\nname: localhost:8443\ntype: STATIC\n"
      }
    ]
  }
}
```

### List Proxy Templates
Request: `GET /meshes/{mesh}/proxytemplates`

Response: `200 OK` with body of Proxy Template entities

Example:
```bash
curl http://localhost:5681/meshes/mesh-1/proxytemplates
```
```json
{
 "items": [
  {
   "conf": {
    "imports": [
     "default-proxy"
    ],
    "resources": [
     {
      "name": "raw-name",
      "version": "raw-version",
      "resource": "'@type': type.googleapis.com/envoy.api.v2.Cluster\nconnectTimeout: 5s\nloadAssignment:\n  clusterName: localhost:8443\n  endpoints:\n    - lbEndpoints:\n        - endpoint:\n            address:\n              socketAddress:\n                address: 127.0.0.1\n                portValue: 8443\nname: localhost:8443\ntype: STATIC\n"
     }
    ]
   },
   "mesh": "mesh-1",
   "name": "pt-1",
   "selectors": [
    {
     "match": {
      "service": "backend"
     }
    }
   ],
   "type": "ProxyTemplate"
  }
 ]
}
```

### Delete Proxy Template
Request: `DELETE /meshes/{mesh}/proxytemplates/{name}`

Response: `200 OK`

Example:
```bash
curl -XDELETE http://localhost:5681/meshes/mesh-1/proxytemplates/pt-1
```

## Traffic Permission

### Get Traffic Permission
Request: `GET /meshes/{mesh}/traffic-permissions/{name}`

Response: `200 OK` with Traffic Permission entity

Example:
```bash
curl http://localhost:5681/meshes/mesh-1/traffic-permissions/tp-1
```
```json
{
 "destinations": [
  {
   "match": {
    "service": "redis"
   }
  }
 ],
 "mesh": "mesh-1",
 "name": "tp-1",
 "sources": [
  {
   "match": {
    "service": "backend"
   }
  }
 ],
 "type": "TrafficPermission"
}
```

### Create/Update Traffic Permission
Request: `PUT /meshes/{mesh}/trafficpermissions/{name}` with Traffic Permission entity in body

Response: `201 Created` when the resource is created and `200 OK` when it is updated

Example:
```bash
curl -XPUT http://localhost:5681/meshes/mesh-1/traffic-permissions/tp-1 --data @trafficpermission.json -H'content-type: application/json'
```
```json
{
  "type": "TrafficPermission",
  "name": "tp-1",
  "mesh": "mesh-1",
  "sources": [
    {
      "match": {
        "service": "backend"
      }
    }
  ],
  "destinations": [
    {
      "match": {
        "service": "redis"
      }
    }
  ]
}
```

### List Traffic Permissions
Request: `GET /meshes/{mesh}/traffic-permissions`

Response: `200 OK` with body of Traffic Permission entities

Example:
```bash
curl http://localhost:5681/meshes/mesh-1/traffic-permissions
```
```json
{
 "items": [
  {
   "destinations": [
    {
     "match": {
      "service": "redis"
     }
    }
   ],
   "mesh": "mesh-1",
   "name": "tp-1",
   "sources": [
    {
     "match": {
      "service": "backend"
     }
    }
   ],
   "type": "TrafficPermission"
  }
 ]
}
```

### Delete Traffic Permission
Request: `DELETE /meshes/{mesh}/traffic-permissions/{name}`

Response: `200 OK`

Example:
```bash
curl -XDELETE http://localhost:5681/meshes/mesh-1/traffic-permissions/pt-1
```

## Traffic Log

### Get Traffic Log
Request: `GET /meshes/{mesh}/traffic-logs/{name}`

Response: `200 OK` with Traffic Log entity

Example:
```bash
curl http://localhost:5681/meshes/mesh-1/traffic-logs/tl-1
```
```json
{
 "conf": {
  "backend": "file"
 },
 "destinations": [
  {
   "match": {
    "service": "backend"
   }
  }
 ],
 "mesh": "mesh-1",
 "name": "tl-1",
 "sources": [
  {
   "match": {
    "service": "web",
    "version": "1.0"
   }
  }
 ],
 "type": "TrafficLog"
}
```

### Create/Update Traffic Log
Request: `PUT /meshes/{mesh}/traffic-logs/{name}` with Traffic Log entity in body

Response: `201 Created` when the resource is created and `200 OK` when it is updated

Example:
```bash
curl -XPUT http://localhost:5681/meshes/mesh-1/traffic-logs/tl-1 --data @trafficlog.json -H'content-type: application/json'
```
```json
{
  "type": "TrafficLog",
  "mesh": "mesh-1",
  "name": "tl-1",
  "sources": [
    {
      "match": {
        "service": "web",
        "version": "1.0"
      }
    }
  ],
  "destinations": [
    {
      "match": {
        "service": "backend"
      }
    }
  ],
  "conf": {
    "backend": "file"
  }
}
```

### List Traffic Logs
Request: `GET /meshes/{mesh}/traffic-logs`

Response: `200 OK` with body of Traffic Log entities

Example:
```bash
curl http://localhost:5681/meshes/mesh-1/traffic-logs
```
```json
{
 "items": [
  {
   "conf": {
    "backend": "file"
   },
   "destinations": [
    {
     "match": {
      "service": "backend"
     }
    }
   ],
   "mesh": "mesh-1",
   "name": "tl-1",
   "sources": [
    {
     "match": {
      "service": "web",
      "version": "1.0"
     }
    }
   ],
   "type": "TrafficLog"
  }
 ]
}
```

### Delete Traffic Log
Request: `DELETE /meshes/{mesh}/traffic-logs/{name}`

Response: `200 OK`

Example:
```bash
curl -XDELETE http://localhost:5681/meshes/mesh-1/traffic-logs/tl-1
```

## Traffic Route

### Get Traffic Route
Request: `GET /meshes/{mesh}/traffic-routes/{name}`

Response: `200 OK` with Traffic Route entity

Example:
```bash
curl http://localhost:5681/meshes/mesh-1/traffic-routes/web-to-backend
```
```json
{
 "conf": [
  {
   "weight": 90,
   "destination": {
    "region": "us-east-1",
    "service": "backend",
    "version": "v2"
   }
  },
  {
   "weight": 10,
   "destination": {
    "service": "backend",
    "version": "v3"
   }
  }
 ],
 "destinations": [
  {
   "match": {
    "service": "backend"
   }
  }
 ],
 "mesh": "mesh-1",
 "name": "web-to-backend",
 "sources": [
  {
   "match": {
    "region": "us-east-1",
    "service": "web",
    "version": "v10"
   }
  }
 ],
 "type": "TrafficRoute"
}
```

### Create/Update Traffic Route
Request: `PUT /meshes/{mesh}/traffic-routes/{name}` with Traffic Route entity in body

Response: `201 Created` when the resource is created and `200 OK` when it is updated

Example:
```bash
curl -XPUT http://localhost:5681/meshes/mesh-1/traffic-routes/web-to-backend --data @trafficroute.json -H'content-type: application/json'
```
```json
{
 "type": "TrafficRoute",
 "name": "web-to-backend",
 "mesh": "mesh-1",
 "sources": [
  {
   "match": {
    "region": "us-east-1",
    "service": "web",
    "version": "v10"
   }
  }
 ],
 "destinations": [
  {
   "match": {
    "service": "backend"
   }
  }
 ],
 "conf": [
  {
   "weight": 90,
   "destination": {
    "region": "us-east-1",
    "service": "backend",
    "version": "v2"
   }
  },
  {
   "weight": 10,
   "destination": {
    "service": "backend",
    "version": "v3"
   }
  }
 ]
}
```

### List Traffic Routes
Request: `GET /meshes/{mesh}/traffic-routes`

Response: `200 OK` with body of Traffic Route entities

Example:
```bash
curl http://localhost:5681/meshes/mesh-1/traffic-routes
```
```json
{
 "items": [
  {
   "conf": [
    {
     "weight": 90,
     "destination": {
      "region": "us-east-1",
      "service": "backend",
      "version": "v2"
     }
    },
    {
     "weight": 10,
     "destination": {
      "service": "backend",
      "version": "v3"
     }
    }
   ],
   "destinations": [
    {
     "match": {
      "service": "backend"
     }
    }
   ],
   "mesh": "mesh-1",
   "name": "web-to-backend",
   "sources": [
    {
     "match": {
      "region": "us-east-1",
      "service": "web",
      "version": "v10"
     }
    }
   ],
   "type": "TrafficRoute"
  }
 ]
}
```

### Delete Traffic Route
Request: `DELETE /meshes/{mesh}/traffic-routes/{name}`

Response: `200 OK`

Example:
```bash
curl -XDELETE http://localhost:5681/meshes/mesh-1/traffic-routes/web-to-backend
```

::: tip
The [`kumactl`](../kumactl) CLI under the hood makes HTTP requests to this API.
:::