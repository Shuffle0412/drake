#' @title Return the [sessionInfo()]
#'   of the last call to [make()].
#' @description By default, session info is saved
#' during [make()] to ensure reproducibility.
#' Your loaded packages and their versions are recorded, for example.
#' @seealso [diagnose()], [cached()],
#'   [readd()], [drake_plan()], [make()]
#' @export
#' @return [sessionInfo()] of the last
#'   call to [make()]
#' @inheritParams cached
#' @examples
#' \dontrun{
#' test_with_dir("Quarantine side effects.", {
#' if (suppressWarnings(require("knitr"))) {
#' load_mtcars_example() # Get the code with drake_example("mtcars").
#' make(my_plan) # Run the project, build the targets.
#' drake_get_session_info() # Get the cached sessionInfo() of the last make().
#' }
#' })
#' }
drake_get_session_info <- function(
  path = getwd(),
  search = TRUE,
  cache = drake::get_cache(path = path, search = search, verbose = verbose),
  verbose = 1L
) {
  if (is.null(cache)) {
    stop("No drake::make() session detected.")
  }
  return(cache$get("sessionInfo", namespace = "session"))
}

drake_set_session_info <- function(
  path = getwd(),
  search = TRUE,
  cache = drake::get_cache(path = path, search = search, verbose = verbose),
  verbose = 1L,
  full = TRUE
) {
  if (is.null(cache)) {
    stop("No drake::make() session detected.")
  }
  if (full) {
    cache$set(
      key = "sessionInfo",
      value = utils::sessionInfo(),
      namespace = "session"
    )
  }
  cache$set(
    key = "drake_version",
    value = as.character(utils::packageVersion("drake")),
    namespace = "session"
  )
  invisible()
}

initialize_session <- function(config) {
  runtime_checks(config = config)
  config$cache$set(key = "seed", value = config$seed, namespace = "session")
  init_common_values(config$cache)
  config$eval[[drake_plan_marker]] <- config$plan
  if (config$log_progress) {
    clear_tmp_namespace(
      cache = config$cache,
      jobs = config$jobs_preprocess,
      namespace = "progress"
    )
  }
  drake_set_session_info(cache = config$cache, full = config$session_info)
  do_prework(config = config, verbose_packages = config$verbose)
  invisible()
}

conclude_session <- function(config) {
  drake_cache_log_file(
    file = config$cache_log_file,
    cache = config$cache,
    jobs = config$jobs
  )
  remove(list = names(config$eval), envir = config$eval)
  console_final_notes(config)
  invisible()
}
