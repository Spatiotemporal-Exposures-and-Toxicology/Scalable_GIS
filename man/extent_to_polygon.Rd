% Generated by roxygen2: do not edit by hand
% Please edit documentation in scomps_rmarkdown_litr.rmd.
\name{extent_to_polygon}
\alias{extent_to_polygon}
\title{Generate a rectangular polygon from extent}
\usage{
extent_to_polygon(extent, output_class = "terra", crs = "EPSG:4326")
}
\arguments{
\item{extent}{input extent.
A numeric vector with xmin/xmax/ymin/ymax,
sf::st_bbox() or terra::ext() outputs.}

\item{output_class}{character(1).
Class of the output polygon. One of "sf" or "terra"}

\item{crs}{character(1). Coordinate reference system definition.}
}
\description{
Generate a rectangular polygon from extent
}
\author{
Insang Song
}