#' @rdname duckdb_result-class
#' @inheritParams DBI::dbFetch
#' @importFrom utils head
#' @usage NULL
dbFetch__duckdb_result <- function(res, n = -1, ...) {
  if (!res@env$open) {
    stop("result set was closed")
  }
  if (is.null(res@env$resultset)) {
    stop("Need to call `dbBind()` before `dbFetch()`")
  }

  if (length(n) != 1) {
    stop("need exactly one value in n")
  }
  if (is.infinite(n)) {
    n <- -1
  }
  if (n < -1) {
    stop("cannot fetch negative n other than -1")
  }
  if (!is_wholenumber(n)) {
    stop("n needs to be not a whole number")
  }
  if (res@stmt_lst$type != "SELECT") {
    warning("Should not call dbFetch() on results that do not come from SELECT")
    return(data.frame())
  }

  if (res@arrow) {
    stop("Cannot dbFetch() an Arrow result")
  }

  timezone_out <- res@connection@timezone_out
  tz_out_convert <- res@connection@tz_out_convert

  # FIXME this is ugly
  if (n == 0) {
    return(utils::head(res@env$resultset, 0))
  }
  if (res@env$rows_fetched < 0) {
    res@env$rows_fetched <- 0
  }
  if (res@env$rows_fetched >= nrow(res@env$resultset)) {
    df <- fix_rownames(res@env$resultset[F, , drop = F])
    df <- set_output_tz(df, timezone_out, tz_out_convert)
    return(df)
  }
  # special case, return everything
  if (n == -1 && res@env$rows_fetched == 0) {
    res@env$rows_fetched <- nrow(res@env$resultset)
    df <- res@env$resultset
    df <- set_output_tz(df, timezone_out, tz_out_convert)
    return(df)
  }
  if (n > -1) {
    n <- min(n, nrow(res@env$resultset) - res@env$rows_fetched)
    res@env$rows_fetched <- res@env$rows_fetched + n
    df <- res@env$resultset[(res@env$rows_fetched - n + 1):(res@env$rows_fetched), , drop = F]
    df <- set_output_tz(df, timezone_out, tz_out_convert)
    return(fix_rownames(df))
  }
  start <- res@env$rows_fetched + 1
  res@env$rows_fetched <- nrow(res@env$resultset)
  df <- res@env$resultset[nrow(res@env$resultset), , drop = F]

  df <- set_output_tz(df, timezone_out, tz_out_convert)
  return(fix_rownames(df))
}

#' @rdname duckdb_result-class
#' @export
setMethod("dbFetch", "duckdb_result", dbFetch__duckdb_result)
