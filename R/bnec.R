#' bnec
#'
#' Fits a variety of NEC models using Bayesian analysis and provides a model averaged predictions based on WAIC model weights
#'
#' @param data A \code{\link[base]{data.frame}} containing the data to use for the model.
#' @param x_var A \code{\link[base]{character}} indicating the column heading containing the concentration (x) variable.
#' @param y_var A \code{\link[base]{character}} indicating the column heading containing the response (y) variable.
#' @param model A \code{\link[base]{character}} vector indicating the model(s) to fit. See Details for more information.
#' @param trials_var The column heading indicating the column for the number of "trials" for binomial response data. 
#' If not supplied, the model may run but will not be the model you intended!
#' @param family Either a \code{\link[base]{character}} string, a function, or an object of class \code{\link[stats]{family}} defining the statistical distribution (family) to use for the y (response) data. See details.
#' @param priors An object of class \code{\link[brms]{brmsprior}} which specifies user-desired prior distributions of model parameters.
#' If missing, \code{\link{bnec}} will figure out a baseline prior for each parameter.
#' @param x_range A range of x values over which to consider extracting ECx.
#' @param precision The length of the x vector used for posterior predictions, and over which to extract ECx values. Large values will be slower but more precise.
#' @param sig_val Probability value to use as the lower quantile to test significance of the predictor posterior values 
#' against the lowest observed concentration (assumed to be the control), to estimate NEC as an interpolated NOEC value from smooth ECx curves.
#' @param iter The number of iterations to be passed to \code{\link[brms]{brm}}. Defaults to 2e3 to be consistent with brms defaults.
#' @param warmup A positive integer specifying number of warmup (a.k.a. burnin) iterations. This also specifies the number 
#' of iterations used for stepsize adaptation, so warmup samples should not be used for inference. The number of warmup 
#' should not be larger than "iter" and the default is "floor(iter / 5) * 4".
#' @param ... Further arguments to \code{\link[brms]{brm}} via \code{\link{fit_bayesnec}}.
#' 
#' @details As some concentration-response data will use zero concentration which can cause numerical estimation issues, a
#' small offset is added (1 / 10th of the next lowest value) to zero values of concentration where \code{x_var} are distributed
#' on a continuous scale from 0 to infinity, or are bounded to 0, or 1.
#' 
#' The argument \code{family} indicates the family to use for the response variable in the \code{\link[brms]{brm}} call,
#' and may currently be "Beta" / Beta / Beta(), "binomial" / binomial / binomial(), "Gamma" / Gamma / Gamma(), "gaussian" / gaussian / gaussian(),
#' "negbinomial" / negbinomial / negbinomial(), or "poisson" / poisson / poisson(). Notice that families Beta and negbinomial are exported objects
#' of package \pkg{brms}, so the user needs to load \pkg{brms} before calling these families.
#' Other families can be added as required, please raise an \href{https://github.com/AIMS/bayesnec/issues}{issue} on the GitHub development site if your 
#' required family is not currently available. 
#' If not supplied, the appropriate distribution will be guessed based on the characteristics of the input data through \code{\link{check_data}}. Guesses
#' include all of the above families but negbinomial because this latter requires knowledge on whether the data is over-dispersed. As explained below in the 
#' Return section, the user can extract the dispersion parameter from a bnec call, and if they so wish, can refit the model using the negbinomial family.
#' 
#' The argument \code{model} may be one of "nec3param", "nec4param", "necsigm", "nechorme", "ecx4param", "ecxwb1", "ecxwb2", 
#' "ecxexp", "ecxlin", or "excsigm", in which case a single model of the specified type it fit, and \code{\link{bnec}} returns a model 
#' object of class "bayesnecfit".
#' 
#' If a vector of two or more of the available models is supplied, \code{\link{bnec}} returns a model object of class "bayesmanecfit" 
#' containing model averaged predictions for the supplied models, providing they were successfully fitted.
#' 
#' Model averaging is achieved through a weighted sample of each fitted models posterior predictions, with weights derived 
#' using the \code{\link[brms]{loo_model_weights}} from \pkg{brms}. Individual model fits can be extracted from the \code{mod_fits} 
#' element and can be examined individually.
#' 
#' \code{model} may also be one of "all", meaning all of the available models will be fit; 
#' "ecx" meaning only models excluding a specific NEC step parameter fill be fit; "nec" meaning only models with a specific NEC step
#' parameter will be fit; or "bot_free" meaning only models without a "bot" parameter (without a bottom plateau) will be fit.
#' 
#' Models are fitted using model formula passed to \pkg{brms}.
#' 
#' All models provide an estimate for NEC. For model types with "nec" as a prefix, NEC is directly estimated as parameter "nec"
#' in the model. Models with "ecx" as a prefix are continuous curve models, typically used for extracting ECx values 
#' from concentration response data. In this instance the NEC value is defined as the concentration at which there is 
#' a user supplied (see \code{sig_val}) percentage certainty (based on the Bayesian posterior estimate) that the response 
#' falls below the estimated value of the upper asymptote (top) of the response (i.e. the response value is significantly 
#' lower than that expected in the case of no exposure). 
#' The default value for \code{sig_val} is 0.01, which corresponds to an alpha value of 0.01 for a one-sided test of significance.
#' 
#' @return When only a single model is passed \code{\link{bnec}} returns a \code{\link[base]{list}} of class "bayesnecfit", containing:
#' \itemize{
#'    \item "fit": the the fitted Bayesian model of class \code{\link[brms]{brmsfit}};
#'    \item "model" \code{\link[base]{character}} string indicating the name of the fitted model;
#'    \item "pred_vals" a \code{\link[base]{list}} containing a \code{\link[base]{data.frame}} of summary posterior predicted values
#'           and a vector containing based on the supplied \code{precision} and \code{x_range};
#'    \item "nec" the estimated NEC;
#'    \item "top" the estimate for parameter "top" in the fitted model;
#'    \item "beta" the estimate for parameter "beta" in the fitted model;
#'    \item "alpha" the estimate for parameter "alpha" in the fitted model, NA if absent for the fitted model type;
#'    \item "bot" the estimate for parameter "bot" in the fitted model, NA if absent for the fitted model type;
#'    \item "d" the estimate for parameter "d" in the fitted model, NA if absent for the fitted model type;
#'    \item "slope" the estimate for parameter "slope" in the fitted model, NA if absent for the fitted model type;
#'    \item "ec50" the estimate for parameter "ec50" in the fitted model, NA if absent for the fitted model type;
#'    \item "dispersion" an estimate of dispersion;
#'    \item "predicted_y" the predicted values for the observed data;
#'    \item "residuals" residual values of the observed data from the fitted model;
#'    \item "nec_posterior" a full posterior estimate of the NEC.
#' }
#' When more than one model is passed, \code{\link{bnec}} returns a \code{\link[base]{list}} of class "bayesmanecfit" containing:
#' \itemize{
#'    \item mod_fits a \code{\link[base]{list}} of fitted model outputs of class "bayesnecfit" for each of the fitted models, 
#'    each containing all the elements of class bayesnecfit above;
#'    \item "success_models" \code{\link[base]{character}} vector indicating the name of the successfully fitted models
#'    \item "mod_stats" a \code{\link[base]{data.frame}} of model fit statistics;
#'    \item "sample_size" the size of the posterior sample;
#'    \item "w_nec_posterior" the model-weighted posterior estimate of the NEC;
#'    \item "w_predicted_y" the model-weighted predicted values for the observed data;
#'    \item "w_residuals" model-weighted residual values (i.e. observed - w_predicted_y);
#'    \item "w_pred_vals" a \code{\link[base]{list}} containing model-weighted posterior predicted values based on the supplied \code{precision} and \code{x_range};
#'    \item "w_nec" the summary stats (median and 95% credibility intervals) of w_nec_posterior;
#' }
#' @export
bnec <- function(data, x_var, y_var, model, trials_var = NA,
                 family = NULL, priors, x_range = NA,
                 precision = 1000, sig_val = 0.01,
                 iter = 2e3, warmup = floor(iter / 5) * 4, ...) {
  if (missing(model)) {
    stop("You need to define a model type. See ?bnec")
  }

  msets <- names(mod_groups)
  if (any(model %in% msets)) {
      group_mods <- intersect(model, msets)
      model <- union(model, unname(unlist(mod_groups[group_mods])))
      model <- setdiff(model, msets)
  }

  if (length(model) > 1) {
    mod_fits <- vector(mode = "list", length = length(model))
    names(mod_fits) <- model
    for (m in seq_along(model)) {
      model_m <- model[m]
      fit_m <- try(
        fit_bayesnec(data = data, x_var = x_var, y_var = y_var,
                     trials_var = trials_var, family = family,
                     priors = priors, model = model_m,
                     iter = iter, warmup = warmup, ...),
        silent = TRUE)
      if (!inherits(fit_m, "try-error")) {
        mod_fits[[m]] <- fit_m
      } else {
        mod_fits[[m]] <- NA
      }
    }
    mod_fits <- expand_manec(mod_fits, x_range = x_range,
                             precision = precision,
                             sig_val = sig_val)
    if (!inherits(mod_fits, "prebayesnecfit")) {
      allot_class(mod_fits, "bayesmanecfit")
    } else {
      mod_fits <- expand_nec(mod_fits, x_range = x_range,
                             precision = precision,
                             sig_val = sig_val)
      allot_class(mod_fits, "bayesnecfit")
    }
  } else {
    mod_fit <- fit_bayesnec(data = data, x_var = x_var, y_var = y_var,
                            trials_var = trials_var, family = family,
                            priors = priors, model = model,
                            iter = iter, warmup = warmup, ...)
    mod_fit <- expand_nec(mod_fit, x_range = x_range,
                          precision = precision,
                          sig_val = sig_val)
    allot_class(mod_fit, "bayesnecfit")
  }
}