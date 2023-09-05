Class diagram
================

## Class diagram and inheritance

``` mermaid
classDiagram
class Duckling {[VIRTUAL]}
class backendInfo {
  +driver_call: character
  +db_path: character
  +hash: character
  -reconnectBackend()
}
class dbData {
  [VIRTUAL]
  +data: tbl_Pool
  +hash: character
  +remote_name: character
  +init: logical
  -reconnect()
}
class dbMatrix {
  +dim_names: list
  +dims: integer
  -Arith()
  -Ops()
  -Math()
  -col*()
  -row*()
  -t()
}
class dbDataFrame {
  +key
}
class dbSpatProxyData {
  [VIRTUAL]
  +extent: SpatExtent
  -spatialquery()
}
class dbPolygonProxy {
  +attribute: dbDataFrame
  +n_poly: integer
}
class dbPointsProxy {
  +n_point: integer
}

Duckling --> dbData
Duckling --> backendInfo
dbData --> dbDataFrame
dbData --> dbMatrix
dbData --> dbSpatProxyData
dbSpatProxyData --> dbPolygonProxy
dbSpatProxyData --> dbPointsProxy
```
