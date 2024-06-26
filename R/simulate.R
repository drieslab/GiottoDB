

#' @name simulate_objects
#' @title Simulate GiottoDB Objects
#' @description
#' Create simulated GiottoDB objects in memory from pre-prepared data. Useful
#' for testing purposes and examples.
#' @param data data to use (optional)
#' @param name remote name of simulated remote table (optional)
#' @param p pool object (optional)
NULL



#' @describeIn simulate_objects Simulate a duckdb connection dplyr tbl_Pool in memory
#' @keywords internal
sim_duckdb = function(data = datasets::iris, name = 'test', p = NULL) {
  # setup in-memory db if no pool connection provided
  if(is.null(p)) {
    drv = duckdb::duckdb(dbdir = ':memory:')
    p = pool::dbPool(drv)
  }
  conn = pool::poolCheckout(p)
  duckdb::duckdb_register(conn, df = data, name = name)
  pool::poolReturn(conn)
  dplyr::tbl(p, name)
}



#' @describeIn simulate_objects Simulate a dbDataFrame in memory
#' @param key character. Column to use as key when indexing.
#' @export
sim_dbDataFrame = function(data = NULL, name = 'df_test', key = NA_character_) {
  if(is.null(data)) {
    data = sim_duckdb(name = name)
  }
  if(!inherits(data, 'tbl_sql')) {
    checkmate::assert_class(data, 'data.frame')
    data = sim_duckdb(data = data, name = name)
  }
  dbDataFrame(data = data, remote_name = name, hash = 'ID_dummy',
              init = TRUE, key = key)
}



#' @describeIn simulate_objects Simulate a dbPointsProxy in memory
#' @export
sim_dbPointsProxy = function(data = NULL) {
  if(is.null(data)) {
    gpoint = GiottoData::loadSubObjectMini('giottoPoints')
    sv_dt = svpoint_to_dt(gpoint[], include_values = TRUE)
    data = sim_duckdb(data = sv_dt, name = 'pnt_test')
  }
  dbPointsProxy(data = data, remote_name = 'pnt_test', hash = 'ID_dummy',
                n_point = nrow(sv_dt), init = TRUE, extent = terra::ext(gpoint[]))
}


#' @describeIn simulate_objects Simulate a dbPolygonProxy in memory
#' @export
sim_dbPolygonProxy = function(data = NULL) {
  if(is.null(data)) {
    gpoly = GiottoData::loadSubObjectMini('giottoPolygon')
    sv_geom = data.table::setDT(terra::geom(gpoly[], df = TRUE))
    sv_atts = data.table::setDT(terra::values(gpoly[]))
    sv_atts[, geom := seq(.N)]
    data.table::setcolorder(sv_atts, neworder = c('geom', 'poly_ID'))

    data = sim_duckdb(data = sv_geom, name = 'poly_test')
    data_atts = sim_dbDataFrame(
      sim_duckdb(sv_atts, p = cPool(data), name = 'poly_test_attr'),
      key = 'geom',
      name = 'poly_test_attr'
    )
  }
  dbPolygonProxy(data = data, remote_name = 'poly_test', hash = 'ID_dummy',
                 n_poly = nrow(sv_atts), init = TRUE, extent = terra::ext(gpoly[]),
                 attributes = data_atts)
}







