% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/nsec.R
\name{nsec.bayesnecfit}
\alias{nsec.bayesnecfit}
\title{nsec.bayesnecfit}
\usage{
\method{nsec}{bayesnecfit}(object, ...)
}
\arguments{
\item{object}{An object of class \code{\link{bayesnecfit}}
returned by \code{\link{bnec}}.}

\item{...}{Additional arguments to \code{\link{nsec}}}
}
\value{
A vector containing the estimated nsec value, including upper and
lower 95\% credible interval bounds.
}
\description{
Extracts the predicted nsec value as desired from an object of class
\code{\link{bayesnecfit}}.
}
\details{
For \code{hormesis_def}, if "max", then nsec values are calculated
as a decline from the maximum estimates (i.e. the peak at nec);
if "control", then ECx values are calculated relative to the control, which
is assumed to be the lowest observed concentration.
}
\examples{
\donttest{
library(bayesnec)

data(manec_example)
nsec(manec_example)
}

}
\seealso{
\code{\link{bnec}}
}
