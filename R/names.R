


# names helper functions ####



# Implementation of base colnames<- functionality via dplyr for use with dbData
# NOTE: numeric names are currently not allowed
# Setting as NULL is also not supported yet
dplyr_set_colnames = function(x, value) {
  stopifnot(inherits(x, 'dbData'))
  stopifnot('Replacement names are not the same length as the number of columns' =
              length(value) == ncol(x[]))

  c_names = colnames(x[])
  for(n_i in seq_along(c_names)) {
    cn = c_names[n_i]
    vn = as.name(value[n_i])
    x[] = x[] %>% dplyr::rename(!!vn := cn)
  }
  x[] = x[] %>% dplyr::collapse()
  x
}






# names ####
# TODO name attributes for dbMatrix

#' @rdname hidden_aliases
#' @export
setMethod('names', signature(x = 'dbDataFrame'), function(x) {
  x = reconnect(x)
  colnames(x)
})
#' @rdname hidden_aliases
#' @export
setMethod('names<-', signature(x = 'dbDataFrame', value = 'gdbIndex'), function(x, value) {
  x = reconnect(x)
  dplyr_set_colnames(x, value = as.character(value))
})

#' @rdname hidden_aliases
#' @export
setMethod('names', signature(x = 'dbSpatProxyData'), function(x) {
  x = reconnect(x)
  names(x@attributes)
})
#' @rdname hidden_aliases
#' @export
setMethod('names<-', signature(x = 'dbSpatProxyData', value = 'gdbIndex'), function(x, value) {
  x = reconnect(x)
  names(x@attributes) = value
  x
})







# TODO ensure these match the row / col operations
# rownames ####
#' @rdname hidden_aliases
#' @export
setMethod('rownames', signature(x = 'dbData'), function(x) {
  x = reconnect(x)
  rownames(x@data)
})
#' @rdname hidden_aliases
#' @export
setMethod('rownames', signature(x = 'dbMatrix'), function(x) {
  x = reconnect(x)
  x@dim_names[[1]]
})
#' @rdname hidden_aliases
#' @export
setMethod('rownames<-', signature(x = 'dbMatrix'), function(x, value) {
  x = reconnect(x)
  if(x@dims[1] != length(value)) stopf('length of rownames to set does not equal number of rows')
  x@dim_names[[1]] = value
  x
})



# colnames ####
#' @rdname hidden_aliases
#' @export
setMethod('colnames', signature(x = 'dbData'), function(x) {
  x = reconnect(x)
  colnames(x@data)
})

#' @rdname hidden_aliases
#' @export
setMethod('colnames', signature(x = 'dbMatrix'), function(x) {
  x = reconnect(x)
  x@dim_names[[2]]
})
#' @rdname hidden_aliases
#' @export
setMethod('colnames<-', signature(x = 'dbMatrix'), function(x, value) {
  x = reconnect(x)
  if(x@dims[2] != length(value)) stopf('length of colnames to set does not equal number of columns')
  x@dim_names[[2]] = value
  x
})

#' @rdname hidden_aliases
#' @export
setMethod('colnames<-', signature(x = 'dbDataFrame', value = 'gdbIndex'), function(x, value) {
  x = reconnect(x)
  dplyr_set_colnames(x = x, value = as.character(value))
})



# dimnames ####
#' @rdname hidden_aliases
#' @export
setMethod('dimnames', signature(x = 'dbMatrix'), function(x) {
  x = reconnect(x)
  x@dim_names
})

#' @rdname hidden_aliases
#' @export
setMethod('dimnames<-', signature(x = 'dbMatrix', value = 'list'), function(x, value) {
  x = reconnect(x)
  x@dim_names = value
  x
})

#' @rdname hidden_aliases
#' @export
setMethod('dimnames', signature(x = 'dbDataFrame'), function(x) {
  x = reconnect(x)
  dimnames(x[])
})
#' @rdname hidden_aliases
#' @export
setMethod('dimnames<-', signature(x = 'dbDataFrame', value = 'list'), function(x, value) {
  x = reconnect(x)
  x = dplyr_set_colnames(x, value = as.character(value[[2]]))
  x
})



