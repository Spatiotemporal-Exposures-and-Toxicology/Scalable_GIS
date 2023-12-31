# Generated from scomps_rmarkdown_litr.rmd: do not edit by hand  
testthat::test_that("Kernel functions work okay", {
  testthat::expect_error(kernelfunction(10, 100, "hyperbolic"))
  testthat::expect_no_error(kernelfunction(10, 100, "uniform"))
  testthat::expect_no_error(kernelfunction(10, 100, "quartic"))
  testthat::expect_no_error(kernelfunction(10, 100, "triweight"))
  testthat::expect_no_error(kernelfunction(10, 100, "epanechnikov"))
})


testthat::test_that("What package does the input object belong?",
{
  withr::local_package("stars")
  withr::local_package("terra")
  withr::local_options(list(sf_use_s2 = FALSE))
  bcsd_path <- system.file(package = "stars", "nc/bcsd_obs_1999.nc")
  bcsd_stars <- stars::read_stars(bcsd_path)

  packbound_stars <- check_packbound(bcsd_stars)
  sprast_bcsd <- terra::rast(bcsd_path)
  packbound_terra <- check_packbound(sprast_bcsd)

  testthat::expect_equal(packbound_stars, "sf")
  testthat::expect_equal(packbound_terra, "terra")
})


testthat::test_that("What package does the input object belong?",
{
  withr::local_package("stars")
  withr::local_package("terra")
  withr::local_options(list(sf_use_s2 = FALSE))
  bcsd_path <- system.file(package = "stars", "nc/bcsd_obs_1999.nc")
  bcsd_stars <- stars::read_stars(bcsd_path)

  nc <- system.file(package = "sf", "shape/nc.shp")
  nc <- sf::read_sf(nc)

  datatype_stars <- check_datatype(bcsd_stars)
  datatype_sf <- check_datatype(nc)

  testthat::expect_equal(datatype_stars, "raster")
  testthat::expect_equal(datatype_sf, "vector")
})


testthat::test_that("Format is well converted",
{
  withr::local_package("stars")
  withr::local_package("terra")
  withr::local_options(list(sf_use_s2 = FALSE))

  # starts from sf/stars
  bcsd_path <- system.file(package = "stars", "nc/bcsd_obs_1999.nc")
  bcsd_stars <- stars::read_stars(bcsd_path)
  nc <- system.file(package = "sf", "shape/nc.shp")
  nc <- sf::read_sf(nc)

  stars_bcsd_tr <- switch_packbound(bcsd_stars)
  sf_nc_tr <- switch_packbound(nc)

  testthat::expect_equal(check_packbound(stars_bcsd_tr), "terra")
  testthat::expect_equal(check_packbound(sf_nc_tr), "terra")

  stars_bcsd_trb <- switch_packbound(stars_bcsd_tr)
  sf_nc_trb <- switch_packbound(sf_nc_tr)

  testthat::expect_equal(check_packbound(stars_bcsd_trb), "sf")
  testthat::expect_equal(check_packbound(sf_nc_trb), "sf")

})



testthat::test_that("CRS is transformed when it is not standard", {
  withr::local_package("sf")
  withr::local_package("terra")
  withr::local_options(list(sf_use_s2 = FALSE))

  nc <- system.file(package = "sf", "shape/nc.shp")
  nc <- sf::read_sf(nc)
  nc <- sf::st_transform(nc, "EPSG:5070")
  nctr <- terra::vect(nc)
  terra::crs(nctr) <- "EPSG:5070"
  ncna <- nc
  sf::st_crs(ncna) <- NA
  ncnatr <- terra::vect(ncna)

  testthat::expect_error(check_crs_align(nc, 4326))
  testthat::expect_error(check_crs_align(ncna, crs_standard = "EPSG:4326"))
  testthat::expect_error(check_crs_align(ncnatr, "EPSG:4326"))

  testthat::expect_no_error(check_crs_align(nc, crs_standard = "EPSG:4326"))
  testthat::expect_no_error(check_crs_align(nc, crs_standard = "EPSG:5070"))
  testthat::expect_no_error(check_crs_align(nctr, crs_standard = "EPSG:4326"))
  testthat::expect_no_error(check_crs_align(nctr, crs_standard = "EPSG:5070"))

  nctr_align <- check_crs_align(nctr, "EPSG:4326")
  nc_align <- check_crs_align(nc, "EPSG:4326")

  testthat::expect_s3_class(nc_align, "sf")
  testthat::expect_s4_class(nctr_align, "SpatVector")

  nc_align_epsg <- sf::st_crs(nc_align)$epsg 
  nctr_align_epsg <- terra::crs(nctr_align, describe = TRUE)$code

  testthat::expect_equal(nc_align_epsg, 4326)
  testthat::expect_equal(nctr_align_epsg, "4326")

  terra::crs(ncnatr) <- NULL
  # error case
  testthat::expect_error(check_crs_align(ncnatr, "EPSG:4326"))

})


testthat::test_that("vector validity check is cleared", {
  withr::local_package("sf")
  withr::local_package("terra")
  withr::local_options(list(sf_use_s2 = FALSE))

  nc <- system.file(package = "sf", "shape/nc.shp")
  nc <- sf::read_sf(nc)

  testthat::expect_no_error(validate_and_repair_vectors(nc))

  nct <- terra::vect(nc)
  testthat::expect_no_error(validate_and_repair_vectors(nct))
})


testthat::test_that("Clip extent is set properly", {
  withr::local_package("sf")
  withr::local_package("terra")
  withr::local_options(list(sf_use_s2 = FALSE))

  ncpath <- system.file("shape/nc.shp", package = "sf")
  suppressWarnings(
    nc <- sf::read_sf(ncpath) |>
      sf::st_transform("EPSG:5070") |>
      sf::st_centroid())

  radius <- 1e4L

  (nc_ext_sf <- set_clip_extent(nc, radius))

  nct <- terra::vect(nc)
  (nc_ext_terra <- set_clip_extent(nct, radius))

  (proper_xmin <- sf::st_bbox(nc)[1] - (1.1 * radius))

  testthat::expect_s3_class(nc_ext_sf, "sfc")
  testthat::expect_s4_class(nc_ext_terra, "SpatExtent")

  nc_ext_sf_1 <- sf::st_bbox(nc_ext_sf)[1]
  nc_ext_terra_1 <- nc_ext_terra[1]

  testthat::expect_equal(nc_ext_sf_1, proper_xmin)
  testthat::expect_equal(nc_ext_terra_1, proper_xmin)

})


testthat::test_that("Vector inputs are clipped by clip_as_extent", {
  withr::local_package("sf")
  withr::local_package("terra")
  withr::local_options(list(sf_use_s2 = FALSE))

  ncpath <- testthat::test_path("..", "testdata", "nc_hierarchy.gpkg")
  nccnty <- terra::vect(ncpath, layer = "county",
    query = "SELECT * FROM county WHERE GEOID IN (37063, 37183)")
  nctrct <- terra::vect(ncpath, layer = "tracts")

  ncp <- readRDS(testthat::test_path("..", "testdata", "nc_random_point.rds"))
  ncp <- sf::st_transform(ncp, "EPSG:5070")
  ncpt <- terra::vect(ncp)

  ncpt <- ncpt[nccnty, ]

  # terra-terra
  testthat::expect_no_error(
    suppressWarnings(cl_terra <- clip_as_extent(
    pnts = ncpt, buffer_r = 3e4L, target_input = nctrct
  )))
  testthat::expect_s4_class(cl_terra, "SpatVector")
  
  # sf-sf
  ncp <- sf::st_as_sf(ncpt)
  nccntysf <- sf::st_as_sf(nccnty)
  nctrct <- sf::st_as_sf(nctrct)
  testthat::expect_no_error(
    suppressWarnings(cl_sf <- clip_as_extent(
    pnts = ncp, buffer_r = 3e4L, target_input = nctrct
  )))
  testthat::expect_s3_class(cl_sf, "sf")

  # sf-terra
  testthat::expect_no_error(
    suppressWarnings(clip_as_extent(
      pnts = ncpt, buffer_r = 3e4L,
      target_input = sf::st_as_sf(nctrct))
  ))

  testthat::expect_error(
    clip_as_extent(
      pnts = NULL, buffer_r = 3e4L, target_input = nctrct
  ))

})


testthat::test_that("Clip by extent works without errors", {
  withr::local_package("sf")
  withr::local_package("stars")
  withr::local_package("terra")
  withr::local_options(list(sf_use_s2 = FALSE))

  # starts from sf/stars
  ncelev <- terra::unwrap(readRDS("../testdata/nc_srtm15_otm.rds"))
  terra::crs(ncelev) <- "EPSG:5070"
  nc <- system.file(package = "sf", "shape/nc.shp")
  nc <- sf::read_sf(nc)
  ncp <- readRDS("../testdata/nc_random_point.rds")
  ncp_terra <- terra::vect(ncp)

  testthat::expect_no_error(clip_as_extent_ras(ncp, 30000L, ncelev))
  testthat::expect_no_error(clip_as_extent_ras(ncp_terra, 30000L, ncelev))
  testthat::expect_error(clip_as_extent_ras(ncp_terra, NULL, ncelev))
})




testthat::test_that("Raster is read properly with a window.", {
  withr::local_package("stars")
  withr::local_package("terra")
  withr::local_options(list(sf_use_s2 = FALSE))
  bcsd_path <- system.file(package = "stars", "nc/bcsd_obs_1999.nc")

  ext_numeric <- c(-84, -82, 34, 36) # unnamed
  testthat::expect_error(rast_short(bcsd_path, ext_numeric[1:3]))
  testthat::expect_error(rast_short(bcsd_path, ext_numeric))

  names(ext_numeric) <- c("xmin", "xmax", "ymin", "ymax")
  rastshort_num <- rast_short(bcsd_path, ext_numeric)
  testthat::expect_s4_class(rastshort_num, "SpatRaster")

  ext_terra <- terra::ext(ext_numeric)
  rastshort_terra <- rast_short(bcsd_path, ext_terra)
  testthat::expect_s4_class(rastshort_terra, "SpatRaster")

})



testthat::test_that("Grid split is well done.", {
  withr::local_package("sf")
  withr::local_package("stars")
  withr::local_package("terra")
  withr::local_options(list(sf_use_s2 = FALSE))

  # starts from sf/stars
  nc <- system.file(package = "sf", "shape/nc.shp")
  nc <- sf::read_sf(nc)
  nc <- sf::st_transform(nc, "EPSG:5070")

  testthat::expect_no_error(get_computational_regions(nc, mode = "grid", padding = 3e4L))
  ncgrid <- get_computational_regions(nc, mode = "grid", padding = 3e4L)
  testthat::expect_s3_class(ncgrid$original, "sf")

  nctr <- terra::vect(nc)
  testthat::expect_no_error(get_computational_regions(nctr, mode = "grid", padding = 3e4L))
  ncgridtr <- get_computational_regions(nctr, mode = "grid", padding = 3e4L)
  testthat::expect_s4_class(ncgridtr$original, "SpatVector")

})


testthat::test_that("Grid merge is well done.", {
  withr::local_package("sf")
  withr::local_package("terra")
  withr::local_package("igraph")
  withr::local_package("dplyr")
  withr::local_options(list(sf_use_s2 = FALSE))
  withr::local_seed(20231121)

  nc <- system.file("shape/nc.shp", package = "sf")
  nc <- sf::read_sf(nc)
  nc <- sf::st_transform(nc, "EPSG:5070")
  nctr <- terra::vect(nc)
  ncp <- readRDS(testthat::test_path("..", "testdata", "nc_random_point.rds"))
  ncp <- sf::st_transform(ncp, "EPSG:5070")
  ncrp <- sf::st_as_sf(sf::st_sample(nc, 1000L))

  gridded <-
    get_computational_regions(ncrp,
                              mode = "grid",
                              nx = 8L, ny = 5L,
                              padding = 1e4L)
  # suppress warnings for "all sub-geometries for which ..."
  testthat::expect_warning(grid_merge(ncrp, gridded$original, 25L))

  ncptr <- terra::vect(ncrp)
  griddedtr <-
    get_computational_regions(ncptr,
                              mode = "grid",
                              nx = 8L, ny = 5L,
                              padding = 1e4L)
  testthat::expect_warning(grid_merge(ncptr, griddedtr$original, 25L))

})


testthat::test_that("input extent is converted to a polygon", {
  withr::local_package("sf")
  withr::local_package("terra")
  withr::local_options(list(sf_use_s2 = FALSE))

  mainland_vec <- c(xmin = -128, xmax = -62, ymin = 25, ymax = 52)
  mainland_box <- extent_to_polygon(mainland_vec, output_class = "sf")
  mainland_box_t <- extent_to_polygon(mainland_vec, output_class = "terra")
  mainland_vec_un <- unname(mainland_vec)

  testthat::expect_s3_class(mainland_box, "sf")
  # terra Spat* objects are s4 class...
  testthat::expect_s4_class(mainland_box_t, "SpatVector")
  # error cases
  testthat::expect_error(
    extent_to_polygon(mainland_vec_un, output_class = "sf")
  )
  testthat::expect_error(
    extent_to_polygon(mainland_vec_un, output_class = "GeoDataFrames")
  )  
})


testthat::test_that("Check bbox abides.", {
  withr::local_package("sf")
  withr::local_package("stars")
  withr::local_package("terra")
  withr::local_options(list(sf_use_s2 = FALSE))

  # starts from sf/stars
  nc <- system.file(package = "sf", "shape/nc.shp")
  nc <- sf::read_sf(nc)
  nc <- sf::st_transform(nc, "EPSG:5070")
  ncp <- readRDS(testthat::test_path("..", "testdata", "nc_random_point.rds"))
  ncp <- sf::st_transform(ncp, "EPSG:5070")

  testthat::expect_no_error(check_bbox(ncp, nc))
  res <- check_bbox(ncp, nc)
  testthat::expect_equal(res, TRUE)

  # error cases
  testthat::expect_no_error(check_bbox(ncp, sf::st_bbox(nc)))
})


testthat::test_that("extract_with runs well", {
  withr::local_package("sf")
  withr::local_package("stars")
  withr::local_package("terra")
  withr::local_package("dplyr")
  withr::local_package("rlang")
  withr::local_options(list(sf_use_s2 = FALSE))

  # starts from sf/stars
  ncp <- readRDS(testthat::test_path("..", "testdata", "nc_random_point.rds"))
  ncp <- sf::st_transform(ncp, "EPSG:5070")
  ncp <- terra::vect(ncp)
  nccnty <- system.file("shape/nc.shp", package = "sf")
  nccnty <- sf::st_read(nccnty)
  nccnty <- sf::st_transform(nccnty, "EPSG:5070")
  nccntytr <- terra::vect(nccnty)
  ncelev <- readRDS(testthat::test_path("..", "testdata", "nc_srtm15_otm.rds"))
  ncelev <- terra::unwrap(ncelev)

  nccnty4326 <- sf::st_transform(nccnty, "EPSG:4326")
  testthat::expect_no_error(reproject_b2r(nccnty4326, ncelev))

  # test two modes
  testthat::expect_no_error(
    ncexpoly <- extract_with(
                             nccntytr,
                             ncelev,
                             "FIPS",
                             mode = "polygon"))
  testthat::expect_no_error(
    ncexbuff <- extract_with(ncp,
                             ncelev,
                             "pid",
                             mode = "buffer",
                             radius = 1e4L))

  testthat::expect_no_error(
    ncexbuffkern <- extract_with_buffer(ncp,
                             ncelev,
                             "pid",
                             kernel = "epanechnikov",
                             func = stats::weighted.mean,
                             bandwidth = 1.25e4L,
                             radius = 1e4L))

  testthat::expect_no_error(
    ncexbuffkern <- extract_with(ncp,
                             ncelev,
                             "pid",
                             mode = "buffer",
                             kernel = "epanechnikov",
                             func = stats::weighted.mean,
                             bandwidth = 1.25e4L,
                             radius = 1e4L))


  # errors
  testthat::expect_error(
    extract_with(nccntytr,
                 ncelev,
                 "GEOID",
                 mode = "whatnot"))
  testthat::expect_error(
    extract_with(nccntytr,
                 ncelev,
                 "GEOID",
                 mode = "polygon"))
  testthat::expect_error(
    extract_with(nccntytr,
                 ncelev,
                 1,
                 mode = "buffer",
                 radius = 1e4L))

})



testthat::test_that("check_crs is working as expected", {
  withr::local_package("sf")
  withr::local_package("terra")
  withr::local_options(list(sf_use_s2 = FALSE))
  ncpath <- system.file("shape/nc.shp", package = "sf")
  nc <- sf::read_sf(ncpath)
  nct <- terra::vect(nc)
  crs_checked1 <- check_crs(nc)
  dummy <- character(0)
  crs_checked2 <- check_crs(nct)

  testthat::expect_equal(crs_checked1, sf::st_crs(nc))
  testthat::expect_equal(crs_checked2, terra::crs(nct))
  testthat::expect_error(check_crs(dummy))
  ncna <- nc
  sf::st_crs(ncna) <- NA
  testthat::expect_error(check_crs(ncna))
  nctna <- nct
  terra::crs(nctna) <- ""
  testthat::expect_error(check_crs(nctna))

})


testthat::test_that("nc data is within the mainland US", {
  withr::local_package("sf")
  withr::local_package("terra")
  withr::local_options(list(sf_use_s2 = FALSE))
  ncpath <- system.file("shape/nc.shp", package = "sf")
  nc <- sf::read_sf(ncpath)
  nc <- sf::st_transform(nc, "EPSG:4326")
  mainland_vec <- c(xmin = -128, xmax = -62, ymin = 22, ymax = 52)
  mainland_box <- extent_to_polygon(mainland_vec, output_class = "sf")
  within_res <- check_within_reference(nc, mainland_box)
  testthat::expect_equal(within_res, TRUE)

  # error cases
  testthat::expect_error(check_within_reference(list(1), mainland_box))
  testthat::expect_error(check_within_reference(nc, list(1)))

})


testthat::test_that("SEDC are well calculated.", {
  withr::local_package("sf")
  withr::local_package("terra")
  withr::local_package("dplyr")
  withr::local_package("testthat")
  withr::local_options(list(sf_use_s2 = FALSE))

  # read and generate data
  ncpath <- system.file("shape/nc.shp", package = "sf")
  ncpoly <- terra::vect(ncpath) |>
    terra::project("EPSG:5070")
  ncpnts <-
    readRDS(testthat::test_path("..", "testdata", "nc_random_point.rds"))
  ncpnts <- terra::vect(ncpnts)
  ncpnts <- terra::project(ncpnts, "EPSG:5070")
  ncrand <- terra::spatSample(ncpoly, 250L)
  ncrand$pollutant1 <- stats::rgamma(250L, 1, 0.01)
  ncrand$pollutant2 <- stats::rnorm(250L, 30, 4)
  ncrand$pollutant3 <- stats::rbeta(250L, 0.5, 0.5)

  polnames <- paste0("pollutant", 1:3)

  testthat::expect_no_error(
    sedc_calc <-
      calculate_sedc(ncpnts, ncrand, "pid", 3e4L, 5e4L, polnames))
  testthat::expect_s3_class(sedc_calc, "data.frame")
  
  testthat::expect_equal(
    sum(paste0(polnames, "_sedc") %in% names(sedc_calc)),
    length(polnames))
  testthat::expect_true(!is.null(attr(sedc_calc, "sedc_bandwidth")))
  testthat::expect_true(!is.null(attr(sedc_calc, "sedc_threshold")))

  ncpnts <- readRDS(testthat::test_path("..", "testdata", "nc_random_point.rds"))
  ncpnts <- sf::st_transform(ncpnts, "EPSG:5070")
  ncrandsf <- sf::st_as_sf(ncrand)

  testthat::expect_no_error(
    calculate_sedc(ncpnts, ncrandsf, "pid", 3e4L, 5e4L, polnames)
  )
})



testthat::test_that("aw_covariates works as expected.", {
  withr::local_package("sf")
  withr::local_package("terra")
  withr::local_package("units")
  withr::local_package("dplyr")
  withr::local_package("testthat")
  withr::local_options(list(sf_use_s2 = FALSE))

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"))
  nc <- sf::st_transform(nc, 5070)
  pp <- sf::st_sample(nc, size = 300)
  pp <- sf::st_as_sf(pp)
  pp[["id"]] <- seq(1, nrow(pp))
  sf::st_crs(pp) <- "EPSG:5070"
  ppb <- sf::st_buffer(pp, nQuadSegs = 180, dist = units::set_units(20, "km"))

  system.time({ppb_nc_aw <- aw_covariates(ppb, nc, "id")})
  expect_s3_class(ppb_nc_aw, "sf")

  # terra
  ppb_t <- terra::vect(ppb)
  nc_t <- terra::vect(nc)
  system.time({ppb_nc_aw <- aw_covariates(ppb_t, nc_t, "id")})
  expect_s3_class(ppb_nc_aw, "data.frame")

  # auto convert formats
  system.time({ppb_nc_aw <- aw_covariates(ppb_t, nc, "id")})
  expect_s3_class(ppb_nc_aw, "data.frame")

})




testthat::test_that("classes are detected.", {
  withr::local_package("terra")
  random_df <- data.frame(x = runif(10), y = runif(10))
  random_tv <- terra::vect(random_df, geom = c("x", "y"))
  test_args <- list(vector = random_tv,
                    func = mean,
                    pipi = pi,
                    zodiac = "Horse")
  set_detected <- detect_class(test_args, "SpatVector")
  # test partial match
  set_detectedp <- detect_class(test_args, "Spat")

  testthat::expect_true(is.logical(set_detected))
  testthat::expect_true(is.logical(set_detectedp))
  # both are the same
  testthat::expect_true(all.equal(set_detected, set_detectedp))

  vect_pop <- test_args[set_detected][[1]]
  testthat::expect_s4_class(vect_pop, "SpatVector")

  # does it well in a function as designed?
  downy <- function(...) {
    ARGS <- list(...)
    detect_class(ARGS, "SpatVector")}
  bear <- downy(v = random_tv, f = mean, pipi = pi)

  testthat::expect_true(is.logical(bear))
  testthat::expect_true(bear[[1]] == TRUE)

})


testthat::test_that("Processes are properly spawned and compute", {
  withr::local_package("terra")
  withr::local_package("sf")
  withr::local_package("future")
  withr::local_package("future.apply")
  withr::local_package("dplyr")
  withr::local_options(list(sf_use_s2 = FALSE))

  ncpath <- system.file("shape/nc.shp", package = "sf")
  ncpoly <- terra::vect(ncpath) |>
    terra::project("EPSG:5070")
  ncpnts <-
    readRDS(
            testthat::test_path("..", "testdata", "nc_random_point.rds"))
  ncpnts <- terra::vect(ncpnts)
  ncpnts <- terra::project(ncpnts, "EPSG:5070")
  ncelev <-
    terra::unwrap(
      readRDS(testthat::test_path("..", "testdata", "nc_srtm15_otm.rds")))
  terra::crs(ncelev) <- "EPSG:5070"
  names(ncelev) <- c("srtm15")

  ncsamp <- terra::spatSample(terra::ext(ncelev), 1e4L,
    lonlat = FALSE, as.points = TRUE)
  ncsamp$kid <- sprintf("K-%05d", seq(1, nrow(ncsamp)))

  nccompreg <-
    get_computational_regions(
                              input = ncpnts,
                              mode = 'grid',
                              nx = 6L,
                              ny = 4L,
                              padding = 3e4L)
  res <-
    suppressWarnings(
      distribute_process_grid(
                              grids = nccompreg,
                              grid_target_id = NULL,
                              fun_dist = extract_with_buffer,
                              points = ncpnts,
                              surf = ncelev,
                              qsegs = 90L,
                              radius = 5e3L,
                              id = "pid")
    )

  testthat::expect_error(
    suppressWarnings(
      distribute_process_grid(
                              grids = nccompreg,
                              grid_target_id = "1/10",
                              fun_dist = extract_with_buffer,
                              points = ncpnts,
                              surf = ncelev,
                              qsegs = 90L,
                              radius = 5e3L,
                              id = "pid")
    )
  )

  testthat::expect_error(
    suppressWarnings(
      distribute_process_grid(
                              grids = nccompreg,
                              grid_target_id = c(1, 100, 125),
                              fun_dist = extract_with_buffer,
                              points = ncpnts,
                              surf = ncelev,
                              qsegs = 90L,
                              radius = 5e3L,
                              id = "pid")
    )
  )


  testthat::expect_no_error(
    suppressWarnings(
      distribute_process_grid(
                              grids = nccompreg,
                              grid_target_id = "1:10",
                              fun_dist = extract_with_buffer,
                              points = ncpnts,
                              surf = ncelev,
                              qsegs = 90L,
                              radius = 5e3L,
                              id = "pid")
    )
  )


  testthat::expect_no_error(
    suppressWarnings(
      distribute_process_grid(
                              grids = nccompreg,
                              grid_target_id = c(1, 3),
                              fun_dist = extract_with_buffer,
                              points = ncpnts,
                              surf = ncelev,
                              qsegs = 90L,
                              radius = 5e3L,
                              id = "pid")
    )
  )

  testthat::expect_true(is.list(nccompreg))
  testthat::expect_s4_class(nccompreg$original, "SpatVector")
  testthat::expect_s3_class(res, "data.frame")
  testthat::expect_true(!anyNA(unlist(res)))

  testthat::expect_no_error(
    suppressWarnings(
      resnas <-
      distribute_process_grid(
                              grids = nccompreg,
                              grid_target_id = "1:10",
                              fun_dist = extract_with_buffer,
                              points = ncpnts,
                              surf = ncelev,
                              qsegs = 90L,
                              radius = -5e3L,
                              id = "pid")
    )
  )

  testthat::expect_s3_class(resnas, "data.frame")
  testthat::expect_true(anyNA(resnas))

  testthat::expect_no_error(
    suppressWarnings(
      resnas0 <-
      distribute_process_grid(
                              grids = nccompreg,
                              grid_target_id = "1:10",
                              fun_dist = terra::nearest,
                              x = ncpnts,
                              y = ncsamp,
                              id = "pid")
    )
  )

})



testthat::test_that("Processes are properly spawned and compute over hierarchy", {
  withr::local_package("terra")
  withr::local_package("sf")
  withr::local_package("future")
  withr::local_package("future.apply")
  withr::local_package("dplyr")
  withr::local_options(list(sf_use_s2 = FALSE))

  ncpath <- testthat::test_path("..", "testdata", "nc_hierarchy.gpkg")
  nccnty <- terra::vect(ncpath, layer = "county")
  nctrct <- sf::st_read(ncpath, layer = "tracts")
  nctrct <- terra::vect(nctrct)
  ncelev <- terra::unwrap(readRDS(
    testthat::test_path("..", "testdata", "nc_srtm15_otm.rds")))
  terra::crs(ncelev) <- "EPSG:5070"
  names(ncelev) <- c("srtm15")

  ncsamp <- terra::spatSample(terra::ext(ncelev), 1e4L,
    lonlat = FALSE, as.points = TRUE)
  ncsamp$kid <- sprintf("K-%05d", seq(1, nrow(ncsamp)))

  testthat::expect_no_error(
    res <-
      suppressWarnings(
        distribute_process_hierarchy(
                                regions = nccnty,
                                split_level = "GEOID",
                                fun_dist = extract_with_polygons,
                                polys = nctrct,
                                surf = ncelev,
                                id = "GEOID",
                                func = "mean")
      )
  )

  testthat::expect_error(
    suppressWarnings(
      distribute_process_hierarchy(
                              regions = nccnty,
                              split_level = c(1, 2, 3),
                              fun_dist = extract_with_polygons,
                              polys = nctrct,
                              surf = ncelev,
                              id = "GEOID",
                              func = "mean")
    )
  )

  testthat::expect_s3_class(res, "data.frame")
  testthat::expect_equal(!any(is.na(unlist(res))), TRUE)

  testthat::expect_no_error(
    suppressWarnings(
      resnas <-
      distribute_process_hierarchy(
                              regions = nccnty,
                              split_level = "GEOID",
                              fun_dist = terra::nearest,
                              polys = nctrct,
                              surf = ncelev)
    )
  )

  testthat::expect_s3_class(resnas, "data.frame")
  testthat::expect_true(anyNA(resnas))

  testthat::expect_no_error(
    suppressWarnings(
      resnasx <-
      distribute_process_hierarchy(
                              regions = nccnty,
                              debug = TRUE,
                              split_level = "GEOID",
                              fun_dist = extract_with_buffer,
                              points = terra::centroids(nctrct),
                              surf = ncelev,
                              id = "GEOID",
                              radius = -1e3L)
    )
  )

  testthat::expect_no_error(
    suppressWarnings(
      resnasz <-
      distribute_process_hierarchy(
                              regions = nccnty,
                              debug = TRUE,
                              split_level = "GEOID",
                              fun_dist = terra::nearest,
                              x = nctrct,
                              y = ncsamp)
    )
  )
})




testthat::test_that("generic function should be parallelized properly", {
  withr::local_package("terra")
  withr::local_package("sf")
  withr::local_package("future")
  withr::local_package("future.apply")
  withr::local_package("dplyr")
  withr::local_options(list(sf_use_s2 = FALSE))

  # main test
  pnts <- readRDS(testthat::test_path("..", "testdata", "nc_random_point.rds"))
  pnts <- terra::vect(pnts)
  rd1 <-
    terra::vect(testthat::test_path("..", "testdata", "ncroads_first.gpkg"))

  pnts <- terra::project(pnts, "EPSG:5070")
  rd1 <- terra::project(rd1, "EPSG:5070")
  # expect

  nccompreg <-
    get_computational_regions(
                              input = pnts,
                              mode = "grid",
                              nx = 6L,
                              ny = 4L,
                              padding = 3e4L)
  future::plan(future::multicore, workers = 6L)
  testthat::expect_no_error(
    res <-
      suppressWarnings(
        distribute_process_grid(
                                grids = nccompreg,
                                fun_dist = terra::nearest,
                                x = pnts,
                                y = rd1)
      )
  )
  testthat::expect_s3_class(res, "data.frame")
  testthat::expect_equal(nrow(res), nrow(pnts))

})


testthat::test_that("Processes are properly spawned and compute over multirasters", {
  withr::local_package("terra")
  withr::local_package("sf")
  withr::local_package("future")
  withr::local_package("future.apply")
  withr::local_package("dplyr")
  withr::local_options(list(sf_use_s2 = FALSE))

  ncpath <- testthat::test_path("..", "testdata", "nc_hierarchy.gpkg")
  nccnty <- terra::vect(ncpath, layer = "county")
  ncelev <- terra::unwrap(readRDS(
    testthat::test_path("..", "testdata", "nc_srtm15_otm.rds")))
  terra::crs(ncelev) <- "EPSG:5070"
  names(ncelev) <- c("srtm15")
  tdir <- tempdir()
  terra::writeRaster(ncelev, file.path(tdir, "test1.tif"), overwrite = TRUE)
  terra::writeRaster(ncelev, file.path(tdir, "test2.tif"), overwrite = TRUE)
  terra::writeRaster(ncelev, file.path(tdir, "test3.tif"), overwrite = TRUE)
  terra::writeRaster(ncelev, file.path(tdir, "test4.tif"), overwrite = TRUE)
  terra::writeRaster(ncelev, file.path(tdir, "test5.tif"), overwrite = TRUE)
  
  testfiles <- list.files(tdir, pattern = "*.tif$", full.names = TRUE)
  testthat::expect_no_error(
    res <- distribute_process_multirasters(
      filenames = testfiles,
      fun_dist = extract_with_polygons,
      polys = nccnty,
      surf = ncelev,
      id = "GEOID",
      func = "mean"
    )
  )
  testthat::expect_s3_class(res, "data.frame")
  testthat::expect_true(!anyNA(res))

  testfiles_corrupted <- c(testfiles, "/home/runner/fallin.tif")
  testthat::expect_warning(
    res <- distribute_process_multirasters(
      filenames = testfiles_corrupted,
      fun_dist = extract_with_polygons,
      polys = nccnty,
      surf = ncelev,
      id = "GEOID",
      func = "mean"
    )
  )
  testthat::expect_no_error(
    suppressWarnings(resnas <- distribute_process_multirasters(
      filenames = testfiles_corrupted,
      fun_dist = extract_with_polygons,
      polys = nccnty,
      surf = ncelev,
      id = "GEOID",
      func = "mean"
    ))
  )
  testthat::expect_s3_class(resnas, "data.frame")
  testthat::expect_true(anyNA(resnas))

  testthat::expect_no_error(
    suppressWarnings(resnasx <- distribute_process_multirasters(
      filenames = testfiles_corrupted,
      debug = TRUE,
      fun_dist = extract_with_polygons,
      polys = nccnty,
      surf = ncelev,
      id = "GEOID",
      func = "mean"
    ))
  )


})


