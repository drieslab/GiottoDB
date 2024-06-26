

# SpatExtent generics ####
#' @rdname hidden_aliases
#' @export
setMethod('ext', signature(x = 'dbSpatProxyData'), function(x, ...) {
  x@extent
})
#' @rdname hidden_aliases
#' @export
setMethod('ext<-', signature(x = 'dbSpatProxyData', value = 'SpatExtent'), function(x, value) {
  x@extent = value
  x
})




#' @name chunkSpatApply
#' @title Apply a function in a spatially chunked manner
#' @description
#' Split a function operation into multiple spatial chunks. Results are appended
#' back into the database as a new table. This is not parallelized as some databases
#' do not work with parallel writes, but are more performant with large single
#' chunks of data. The functions that are provided, however, can be parallelized
#' in their processing after the chunk has been pulled into memory and only needs
#' to be combined into one before being written.
#' @param x dbPolygonProxy or dbPointsProxy
#' @param y dbPolygonProxy or dbPointsProxy (missing/NULL if not needed)
#' @param chunk_y (default = TRUE) whether y also needs to be spatially chunked
#' if it is provided.
#' @param fun function to apply. The only param(s) that 'fun' should
#' have are x and (optionally) y, based on the inputs to `chunkSpatApply.`
#' @param extent (optional) spatial extent to chunk across. Takes the extent of
#' \code{x} by default
#' @param n_per_chunk (default is 1e5) desired max number of records to process
#' per chunk. This value can be set using setting \code{options(gdb.nperchunk = ?)}
#' @param remote_name name to assign the result in the database. Defaults to a
#' @param progress whether to plot the progress
#' generic incrementing 'gdb_nnn' if not given
#' @param ... additional params to pass to [dbvect]
#' @return dbPolygonProxy or dbPointsProxy
#' @export
chunkSpatApply <- function(x,
                           y = NULL,
                           chunk_y = TRUE,
                           fun,
                           extent = NULL,
                           n_per_chunk = getOption('gdb.nperchunk', 1e5),
                           remote_name = result_count(),
                           progress = TRUE,
                           ...) {

  checkmate::assert_class(x, 'dbSpatProxyData')
  if(!is.null(y)) checkmate::assert_class(y, 'dbSpatProxyData')
  checkmate::assert_function(fun)
  if(is.null(extent)) extent = terra::ext(x)
  checkmate::assert_class(extent, 'SpatExtent')
  checkmate::assert_numeric(n_per_chunk)
  checkmate::assert_character(remote_name)
  p = cPool(x)

  # determine chunking #
  # ------------------ #
  n_rec = nrow(x) # number of records
  min_chunks = n_rec / n_per_chunk
  # chunk_plan slightly expands bounds, allowing for use of 'soft' selections
  # with extent_filter() on two out of four sides during the chunk processing
  ext_list = chunk_plan(extent = extent, min_chunks = min_chunks)


  # chunk data #
  # ---------- #
  # Calculations with y are expected to be performed relative to x. Spatial
  # chunk subsetting of y is performed based on the updated extent of the x
  # chunks after their chunk subset.

  # filter data to chunk ROI
  chunk_x_list = lapply(
    ext_list,
    function(e) {
      # 'soft' selections on top and right
      extent_filter(x = x, extent = e, include = c(TRUE, TRUE, FALSE, FALSE),
                    method = 'mean')
    }
  )
  # filter out empty chunks
  chunk_x_list_len = lapply(chunk_x_list, nrow)
  not_empty = chunk_x_list_len > 0L
  chunk_x_list = chunk_x_list[not_empty]
  chunk_x_list_len = chunk_x_list_len[not_empty]

  # init progress
  if(progress) preview_chunk_plan(ext_list[not_empty], mode = 'bound')

  # filter any y input (if needed) based on x
  chunk_y_input = NULL
  if(!is.null(y)) {
    if(isTRUE(chunk_y)) {
      ext_x_list = lapply(chunk_x_list, extent_calculate)
      # hard selections on all sides.
      chunk_y_input = lapply(
        ext_x_list,
        function(e) {
          extent_filter(x = y, extent = e, include = rep(TRUE, 4L))
        }
      )
    } else {
      chunk_y_input = y
    }
  }


  # 1. Setup lapply
  # 2. Run provided function
  # 3. write or return values
  n_chunks = length(chunk_x_list)
  progressr::with_progress({
    pb = progressr::progressor(steps = n_chunks)

    for (chunk_i in seq(n_chunks)) {

      # convert x (and y if given) to terra
      # run function on x, and conditionally, y
      chunk_x = as.spatvector(chunk_x_list[[chunk_i]])
      if (nrow(chunk_x) == 0L) next # skip chunk if x input is length 0
      chunk_output = if(is.null(chunk_y_input)) {
        # x only
        fun(x = chunk_x)
      } else {
        # x and y
        if(!inherits(chunk_y_input, 'list')) {
          # single y
          fun(x = chunk_x, y = chunk_y_input)
        } else {
          # chunked y values
          chunk_y <- as.spatvector(chunk_y_input[[chunk_i]])
          if (nrow(chunk_y) == 0L) next # skip chunk if y input is length 0
          fun(x = chunk_x, y = chunk_y)
        }
      }

      # write/append values #

      # don't make an object until final chunk
      return_object <- chunk_i == n_chunks
      # include expected geom values for polygons
      dbvect_output <- dbvect(
        x = chunk_output,
        db = p,
        remote_name = remote_name,
        overwrite = 'append',
        return_object = return_object,
        ...
      )
      # dbvect_output expected to be all NULL except for the final object
      # generated during the last chunk

      # update progress and return
      # if (isTRUE(progress)) {
      #   print(terra::plot( # spatplot progress
      #     ext_list[not_empty][[chunk_i]],
      #     add = TRUE,
      #     col = 'lightgreen'
      #   ))
      # }
      pb()
    }

  }) # progressr end


  # return object #
  # --------------- #

  return(dbvect_output)
}











# helper functions ####

#' @name get_dim_n_chunks
#' @title Get rows and cols needed to create at least n chunks from given extent
#' @description Algorithm to determine how to divide up a provided extent into
#' at least \code{n} different chunks. The chunks are arranged so as to prefer
#' being as square as posssible with the provided dimensions and minimum n chunks.
#' @param n minimum n chunks
#' @param e selection extent
#' @examples
#' \dontrun{
#' e <- terra::ext(0, 100, 0, 100)
#' get_dim_n_chunk(n = 5, e = e)
#' }
#' @seealso \code{\link{chunk_plan}}
#' @return numeric vector of x and y stops needed
get_dim_n_chunks = function(n, e) {
  # find x to y ratio as 'r'
  e = e[]
  r = (e[['xmax']] - e[['xmin']]) / (e[['ymax']] - e[['ymin']])

  # x * y = n = ... ry^2 = n
  y = ceiling(sqrt(n/r))
  x = ceiling(n/y)

  return(c(y,x))
}


#' @name chunk_plan
#' @title Plan spatial chunking extents
#' @description
#' Generate the individual extents that will be used to spatially chunk a set of
#' data for piecewise and potentially parallelized processing. Chunks will be
#' generated first by row, then by column. The chunks try to be as square as
#' possible since downstream functions may require slight expansions of the
#' extents to capture all parts of selected polygons. Minimizing the perimeter
#' relative to area decreases waste.
#' @param extent terra SpatExtent that covers the region to spatially chunk
#' @param nrows,ncols numeric. nrow/ncol must be provided as a pair. Determines how many
#' rows and cols respectively will be used in spatial chunking. If NULL, min_chunks
#' will be used as an automated method of planning the spatial chunking
#' @param min_chunks numeric. minimum number of chunks to use.
#' @seealso \code{\link{get_dim_n_chunks}}
#' @examples
#' \dontrun{
#'  e <- terra::ext(0, 100, 0, 100)
#'
#' e_chunk1 <- chunk_plan(e, min_chunks = 9)
#' e_poly1 <- sapply(e_chunk1, terra::as.polygons)
#' e_poly1 <- do.call(rbind, e_poly1)
#' plot(e_poly1)
#'
#' e_chunk2 <- chunk_plan(e, nrows = 3, ncols = 5)
#' e_poly2 <- sapply(e_chunk2, terra::as.polygons)
#' e_poly2 <- do.call(rbind, e_poly2)
#' plot(e_poly2)
#' }
#' @keywords internal
#' @return vector of chunked SpatExtents
chunk_plan = function(extent, min_chunks = NULL, nrows = NULL, ncols = NULL) {
  checkmate::assert_class(extent, 'SpatExtent')
  if(!is.null(nrows)) checkmate::assert_true(length(c(nrows, ncols)) == 2L)
  else {
    checkmate::assert_numeric(min_chunks)
    res = get_dim_n_chunks(n = min_chunks, e = extent)
    nrows = res[1L]
    ncols = res[2L]
  }

  # slightly expand bounds to account for values that may otherwise be missed
  e = extent[] + c(-1, 1, -1, 1)
  x_stops = seq(from = e[['xmin']], to = e[['xmax']], length.out = ncols + 1L)
  y_stops = seq(from = e[['ymin']], to = e[['ymax']], length.out = nrows + 1L)

  ext_list = c()
  for(i in seq(nrows)) {
    for(j in seq(ncols)) {
      ext_list =
        c(ext_list,
          terra::ext(x_stops[j], x_stops[j + 1L], y_stops[i], y_stops[i + 1L]))
    }
  }
  return(ext_list)
}




#' @name preview_chunk_plan
#' @title Plot a preview of the chunk plan
#' @description
#' Plots the output from \code{\link{chunk_plan}} as a set of polygons to preview.
#' Can be useful for debugging. Invisibly returns the planned chunks as a SpatVector
#' of polygons
#' @param extent_list list of extents from \code{chunk_plan}
#' @keywords internal
preview_chunk_plan = function(extent_list, mode = c('poly', 'bound')) {
  checkmate::assert_list(extent_list, types = 'SpatExtent')
  mode = match.arg(mode, choices = c('poly', 'bound'))

  switch(mode,
         'poly' = {
           poly_list = sapply(extent_list, terra::as.polygons)
           poly_bind = do.call(rbind, poly_list)
           terra::plot(poly_bind, values = as.factor(seq_along(poly_list)))
           return(invisible(poly_bind))
         },
         'bound' = {
           xlim = c(extent_list[[1]]$xmin, extent_list[[length(extent_list)]]$xmax)
           ylim = c(extent_list[[1]]$ymin, extent_list[[length(extent_list)]]$ymax)
           # initiate plot
           plot(x = NULL, y = NULL, asp = 1L, xlim = xlim, ylim = ylim)
           # plot extent bounds
           for(e in extent_list) {
             rect(e$xmin, e$ymin, e$xmax, e$ymax)
           }
           return(invisible())
         })
}






