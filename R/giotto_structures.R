
#' @name calculateOverlap
#' @title Calculate polygon overlapped features
#' @export
setMethod(
  'calculateOverlap', signature(x = 'dbSpatProxyData', y = 'dbSpatProxyData'),
  function(
    x, y,
    n_per_chunk = 1e5,
    remote_name = result_count(),
    poly_subset_ids = NULL,
    feat_subset_column = NULL,
    feat_subset_ids = NULL,
    count_info_column = NULL,
    ...
  )
  {
    x <- reconnect(x)
    y <- reconnect(y)

    # 1. perform poly and feat subsets if necessary #
    # --------------------------------------------- #

    if (!is.null(poly_subset_ids)) {
      # polys subset
      x@attributes[] <- x@attributes[] %>%
        dplyr::filter(poly_ID %in% poly_subset_ids)
      x[] <- x[] %>%
        dplyr::inner_join(dplyr::select(x@attributes[], 'geom'), by = 'geom')

    }
    if (!is.null(feat_subset_ids)) {
      if (is.null(feat_subset_column)) stop(
        GiottoUtils::wrap_txt('feat_subset_column must be provided if feat_subset_ids is given')
      )
      # points subset
      y[] <- y[] %>%
        dplyr::filter(dplyr::across(feat_subset_column) %in% feat_subset_ids)
    }


    # 2. setup chunking function #
    # -------------------------- #

    chunk_fun = function(x, y) {
      GiottoClass::calculateOverlap(
        x, y, verbose = FALSE, ...
      )
    }


    # 3. spatial chunking
    res <- chunkSpatApply(
      x = x,
      y = y,
      remote_name = remote_name,
      chunk_y = TRUE,
      n_per_chunk = n_per_chunk,
      fun = chunk_fun
    )


    # 4. output cleanup #
    # ----------------- #

    # 4.1 dbvect write in any missing features
    missing_pts <- which(!y$feat_ID_uniq %in% res$feat_ID_uniq)
    if (length(missing_pts > 0L)) {
      missing_sv <- as.points(y[missing_pts,])
      missing_sv <- missing_sv[, c('feat_ID', 'feat_ID_uniq')]
      dbvect(
        x = missing_sv,
        db = cPool(x),
        remote_name = remoteName(res),
        overwrite = 'append',
        return_object = FALSE
      )
    }

    # 4.2 cleanup doublecounts
    # strategy:
    #   flag dups as:           -1
    #   flag first in group as:  1
    #   flag overlapped pts as: 10 (highly preferred)
    # Find sum of flags, then pick the max value
    res[] <- res[] %>%
      dplyr::group_by(feat_ID_uniq) %>%
      dplyr::mutate(flag_dup = as.numeric(dplyr::n() > 1) * -1) %>%
      dplyr::mutate(flag_first = as.numeric(.uID == min(.uID, na.rm = TRUE))) %>%
      dplyr::mutate(flag_overlap = as.numeric(!is.na(poly_ID)) * 10L) %>%
      dplyr::mutate(flag_sum = flag_dup + flag_first + flag_overlap) %>%
      dplyr::filter(flag_sum == max(flag_sum, na.rm = TRUE)) %>%
      dplyr::select(-flag_dup, -flag_overlap, -flag_first, -flag_sum) %>%
      dplyr::ungroup() %>%
      dplyr::mutate(.uID = dplyr::row_number()) %>%
      dplyr::collapse()

    return(res)
  }
)


# ------------------------------------------------------- #
# aggregation of counts features (by summing with groups) *
# will not work in the database for some reason 11/16/2023
# dplyr:  1.1.3
# dbplyr: 2.4.0
# duckdb: 0.9.1
# It may initially work then repeat calls to the query result
# will hang and freeze the session. Happens for the following also if
# use "counts" as a column directly instead of count_info_column
#
# overlaps_tbl <- x[]
# overlaps_tbl <- overlaps_tbl %>%
#   sql_query(paste0(
#     "SELECT poly_ID, feat_ID, SUM(", count_info_column,") AS N
#     FROM (:data:) :qname:
#     GROUP BY poly_ID, feat_ID"
#   )) %>%
#   dplyr::collapse()
# ------------------------------------------------------- #

#' @name overlapToMatrix
#' @title Create counts matrix from overlaps information
#' @param x object containing overlaps information
#' @param remote_name character. name to be applied to on-disk representation of
#' the results (if applicable)
#' @param gdb_name alias for remote_name param. For disambiguation in external
#' code referencing this method.
#' @param col_names,row_names expected col and row names,
#' @param count_info_column character. column containing counts expected for
#' each overlap found. Assumed to be 1 for all, if not provided.
#' @param write_step if output is HDF5Array, the dimensions of the chunks
#' that are written iteratively to disk. Default is c(1000,1000). Note that
#' actual write step used will respect the expected dimensions.
#' @param filepath character. Save directory for the on-disk representation of
#' the results (if applicable)
#' @param \dots additional params to pass
#' @export
setMethod(
  'overlapToMatrix', signature('dbPointsProxy'),
  function(
    x,
    remote_name = paste0(remoteName(x), '_raw'),
    gdb_name = NULL,
    col_names = NULL,
    row_names = NULL,
    count_info_column = NULL,
    output = c('HDF5Array'),
    write_step = c(1000, 1000),
    filepath = NULL,
    ...
  )
  {
    x <- reconnect(x)
    output = match.arg(toupper(output), choices = c('HDF5ARRAY'))
    if (!is.null(gdb_name)) remote_name <- gdb_name

    # remove points that have no overlap with any polygons (NAs in poly_ID)
    x[] <- x[] %>%
      dplyr::filter(!is.na(poly_ID))

    # organize tbl and define counts column
    if (!is.null(count_info_column)) { # if there is a counts col expected
      if (!count_info_column %in% colnames(x[])) {
        stop('count_info_column ', count_info_column, ' does not exist')
      }
      x <- castNumeric(x, col = count_info_column)
      overlaps_tbl <- x[] %>%
        dplyr::select(poly_ID, feat_ID, counts = !!count_info_column)

    } else {
      overlaps_tbl <- x[] %>%
        dplyr::select(poly_ID, feat_ID) %>%
        dplyr::mutate(counts = 1L)
    }

    # 2. Perform counts aggregation

    # This does not work. see above docs
    # Also means that returning as tbl is not possible.
    #
    # overlaps_tbl <- overlaps_tbl %>%
    #   dplyr::group_by(poly_ID, feat_ID) %>%
    #   dplyr::summarise(sum(counts, na.rm = TRUE)) %>%
    #   dplyr::ungroup()

    # 3. returns

    res <- switch(
      output,
      "HDF5ARRAY" = {

        # performs:
        #   counts aggregation,
        #   missing IDs repair,
        #   chunkwise writing to HDF5
        h5_array_write(
          x = overlaps_tbl,
          name = remote_name,
          filepath = filepath,
          backend_type = "HDF5Array",
          row_names = row_names,
          col_names = col_names,
          as.sparse = TRUE,
          write_step = write_step,
          ...
        )

      }
    )

    return(res)
  }
)


# NOTE: parallelized writes are not supported
#' @name h5_array_write
#' @title Iteratively write chunked overlaps results to HDF5Matrix
#' @param x poly_ID/feat_ID/counts DB tbl to write
#' @param backend_type character. Type of DelayedArray backend to use.
#' Default is "HDF5Array"
#' @param row_names expected row names
#' @param col_names expected column names
#' @param as.sparse Whether the data should be written as sparse or not to the
#' RealizationSink derivative to create. Not all realization backends support
#' this.
#' @param \dots additional params to pass
#' @keywords internal
h5_array_write <- function(
    x,
    name = NULL,
    backend_type = "HDF5Array",
    filepath = NULL,
    row_names,
    col_names,
    as.sparse = TRUE,
    write_step = c(1e3,1e3),
    overwrite = FALSE,
    ...
  ) {
  package_check("HDF5Array", repository = "Bioc")
  package_check("IRanges", repository = "Bioc")
  package_check("DelayedArray", repository = "Bioc")

  # setup sink

  # Cannot set filepath using DelayedArray API
  # DelayedArray::setAutoRealizationBackend("HDF5Array")
  # on.exit(DelayedArray::setAutoRealizationBackend(), add = TRUE)

  # filepath cleanup
  if (!is.null(filepath)) {
    if (length(GiottoUtils::file_extension(filepath)) == 0) {
      filepath <- paste0(filepath, '/', name, '_matrix.h5')
    }
    if (file.exists(filepath) && isTRUE(overwrite)) {
      unlink(filepath)
    } else {
      stop(wrap_txt(
        "HDF5Matrix already exists here.
        Set overwrite = TRUE or choose other filepath."
      ))
    }
  }

  sink <- HDF5Array::HDF5RealizationSink(
    dim = c(length(row_names), length(col_names)),
    dimnames = list(row_names, col_names),
    type = "integer",
    as.sparse = as.sparse, # is sparse supported for HDF5Array?
    filepath = filepath,
    name = name,
    ...
  )
  on.exit(try(DelayedArray::close(sink), silent = TRUE),
          add = TRUE, after = FALSE)


  # NOTE: sink dims do not need to be divisible by spacings
  write_step = c(
    min(write_step[1L], length(row_names)),
    min(write_step[2L], length(col_names))
  )
  sink_grid <- DelayedArray::RegularArrayGrid(
    refdim = dim(sink),
    spacings = write_step
  )

  ## Walk on the grid, and, for each viewport, write data to it.
  for (bid in seq_along(sink_grid)) {

    # determine data to write
    viewport <- sink_grid[[bid]]
    idx_start <- viewport %>%
      IRanges::ranges() %>%
      IRanges::start()
    idx_end <- viewport %>%
      IRanges::ranges() %>%
      IRanges::end()

    block_rown <- row_names[idx_start[1L]:idx_end[1L]]
    block_coln <- col_names[idx_start[2L]:idx_end[2L]]

    block_dt <- x %>%
      dplyr::filter(poly_ID %in% block_coln && feat_ID %in% block_rown) %>%
      data.table::as.data.table()
    block_dt <- block_dt[, sum(counts), by = c('poly_ID', 'feat_ID')]
    data.table::setnames(block_dt, 'V1', 'N')


    # missing IDs repair ---------------------------------------------------- #

    # get all feature and cell information
    missing_feats = block_rown[!block_rown %in% unique(block_dt$feat_ID)]
    missing_ids = block_coln[!block_coln %in% unique(block_dt$poly_ID)]

    # create missing cell values, only if there are missing cell IDs!
    if(!length(missing_ids) == 0) {
      first_feature = block_dt[['feat_ID']][[1L]]
      missing_dt = data.table::data.table(poly_ID = missing_ids, feat_ID = first_feature, N = 0)
      block_dt = rbind(block_dt, missing_dt)
    }

    if(!length(missing_feats) == 0) {
      first_cell = block_dt[['poly_ID']][[1L]]
      missing_dt = data.table::data.table(poly_ID = first_cell, feat_ID = missing_feats, N = 0)
      block_dt = rbind(block_dt, missing_dt)
    }

    # TODO: creating missing feature values
    # ----------------------------------------------------------------------- #

    # create block SparseArraySeed
    block_dgc <- data.table::dcast(
      data = block_dt,
      formula = feat_ID ~ poly_ID,
      value.var = "N",
      fill = 0
    ) %>%
      GiottoUtils::dt_to_matrix()

    # match row/col order with that expected
    block_dgc <- block_dgc[
      match(block_rown, rownames(block_dgc)),
      match(block_coln, colnames(block_dgc))
    ]

    # convert to SparseArraySeed
    block_sas <- as(block_dgc, "SparseArraySeed")

    # write values
    sink <- DelayedArray::write_block(sink, viewport, block_sas)
  }

  # finalize and return
  DelayedArray::close(sink)
  M <- as(sink, "DelayedArray")
  return(M)
}










