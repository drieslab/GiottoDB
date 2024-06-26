Class diagram
================

## Class diagram and inheritance

``` mermaid
classDiagram
class GiottoDB {[VIRTUAL]}
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

GiottoDB --> dbData
GiottoDB --> backendInfo
dbData --> dbDataFrame
dbData --> dbSpatProxyData
dbSpatProxyData --> dbPolygonProxy
dbSpatProxyData --> dbPointsProxy
```
