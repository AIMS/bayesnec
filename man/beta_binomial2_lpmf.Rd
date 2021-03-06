% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/beta_binomial2.R
\name{beta_binomial2_lpmf}
\alias{beta_binomial2_lpmf}
\title{beta_binomial2_lpmf}
\usage{
beta_binomial2_lpmf(y, mu, phi, trials)
}
\arguments{
\item{y}{vector of observation successes.}

\item{mu}{posterior mu.}

\item{phi}{posterior phi.}

\item{trials}{vector of observation trials.}
}
\value{
A \code{\link[base]{numeric}} value or vector containing the probability density of the beta binomial distribution
}
\description{
Beta-binomial wrapper LPMF
}
