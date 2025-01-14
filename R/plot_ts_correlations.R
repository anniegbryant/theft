#' Produce a correlation matrix plot showing pairwise correlations of time series with automatic hierarchical clustering
#' 
#' @import dplyr
#' @importFrom magrittr %>%
#' @import ggplot2
#' @importFrom tidyr pivot_wider
#' @importFrom reshape2 melt
#' @importFrom stats hclust
#' @importFrom stats dist
#' @importFrom stats cor
#' @importFrom plotly ggplotly
#' @importFrom plotly config
#' @param data a dataframewith at least 2 columns for \code{"id"} and \code{"values"} variables
#' @param is_normalised a Boolean as to whether the input feature values have already been scaled. Defaults to \code{FALSE}
#' @param id_var a string specifying the ID variable to compute pairwise correlations between. Defaults to \code{"id"}
#' @param time_var a string specifying the time index variable. Defaults to \code{NULL}
#' @param values_var a string denoting the name of the variable/column that holds the numerical feature values. Defaults to \code{"values"}
#' @param method a rescaling/normalising method to apply. Defaults to \code{"RobustSigmoid"}
#' @param cor_method the correlation method to use. Defaults to \code{"pearson"}
#' @param interactive a Boolean as to whether to plot an interactive \code{plotly} graphic. Defaults to \code{FALSE}
#' @return an object of class \code{ggplot}
#' @author Trent Henderson
#' @export
#' @examples
#' \dontrun{
#' plot_ts_correlations(data = featMat, 
#'   is_normalised = FALSE, 
#'   id_var = "id", 
#'   time_var = "timepoint",
#'   values_var = "values",
#'   method = "RobustSigmoid",
#'   cor_method = "person",
#'   interactive = FALSE)
#' }
#'

plot_ts_correlations <- function(data, is_normalised = FALSE, id_var = "id", 
                                 time_var = "timepoint", values_var = "values",
                                 method = c("z-score", "Sigmoid", "RobustSigmoid", "MinMax"),
                                 cor_method = c("pearson", "spearman"),
                                 interactive = FALSE){
  
  # Make RobustSigmoid and pearson the default
  
  if(missing(method)){
    method <- "RobustSigmoid"
  } else{
    method <- match.arg(method)
  }
  
  if(missing(cor_method)){
    cor_method <- "pearson"
  } else{
    cor_method <- match.arg(cor_method)
  }
  
  #------------ Checks ---------------
  
  if(is.null(id_var) || is.null(time_var) || is.null(values_var)){
    stop("An id variable, time variable, and values variable from your dataframe must be specified.")
  }
  
  # Method selection
  
  '%ni%' <- Negate('%in%')
  the_methods <- c("z-score", "Sigmoid", "RobustSigmoid", "MinMax")
  
  if(method %ni% the_methods){
    stop("method should be a single selection of 'z-score', 'Sigmoid', 'RobustSigmoid' or 'MinMax'")
  }
  
  if(length(method) > 1){
    stop("method should be a single selection of 'z-score', 'Sigmoid', 'RobustSigmoid' or 'MinMax'")
  }
  
  # Correlation method selection
  
  the_cor_methods <- c("pearson", "spearman")
  
  if(cor_method %ni% the_cor_methods){
    stop("cor_method should be a single selection of 'pearson' or 'spearman'")
  }
  
  if(length(cor_method) > 1){
    stop("cor_method should be a single selection of 'pearson' or 'spearman'")
  }
  
  # Dataframe length checks and tidy format wrangling
  
  data_re <- data %>%
    dplyr::rename(id = dplyr::all_of(id_var),
                  timepoint = dplyr::all_of(time_var),
                  values = dplyr::all_of(values_var))
  
  #------------- Normalise data -------------------
  
  if(is_normalised){
    normed <- data_re
  } else{
    
    normed <- data_re %>%
      dplyr::select(c(id, timepoint, values)) %>%
      tidyr::drop_na() %>%
      dplyr::mutate(values = normalise_feature_vector(values, method = method)) %>%
      tidyr::drop_na()
    
    if(nrow(normed) != nrow(data_re)){
      message("Filtered out rows containing NaNs.")
    }
  }
  
  #------------- Data reshaping -------------
  
  cor_dat <- normed %>%
    tidyr::pivot_wider(id_cols = timepoint, names_from = id, values_from = values) %>%
    dplyr::select(-c(timepoint)) %>%
    tidyr::drop_na()
  
  #--------- Correlation ----------
  
  result <- stats::cor(cor_dat, method = cor_method)
  
  #--------- Clustering -----------
  
  # Wrangle into tidy format
  
  melted <- reshape2::melt(result)
  
  # Perform clustering
  
  row.order <- stats::hclust(stats::dist(result))$order # Hierarchical cluster on rows
  col.order <- stats::hclust(stats::dist(t(result)))$order # Hierarchical cluster on columns
  dat_new <- result[row.order, col.order] # Re-order matrix by cluster outputs
  cluster_out <- reshape2::melt(as.matrix(dat_new)) # Turn into dataframe
  
  #--------- Graphic --------------
  
  if(interactive){
    p <- cluster_out %>%
      ggplot2::ggplot(ggplot2::aes(x = Var1, y = Var2,
                                   text = paste('<br><b>ID 1:</b>', Var1,
                                                '<br><b>ID 2:</b>', Var2,
                                                '<br><b>Correlation:</b>', round(value, digits = 3))))
  } else{
    p <- cluster_out %>%
      ggplot2::ggplot(ggplot2::aes(x = Var1, y = Var2)) 
  }
  
  p <- p +
    ggplot2::geom_tile(ggplot2::aes(fill = value)) +
    ggplot2::labs(title = "Pairwise correlation matrix",
                  x = NULL,
                  y = NULL,
                  fill = "Correlation coefficient") +
    ggplot2::scale_fill_distiller(palette = "RdBu", limits = c(-1,1)) +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                   legend.position = "bottom")
  
  if(nrow(cluster_out) <= 20){
    p <- p +
      ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90, hjust = 1))
  } else {
    p <- p +
      ggplot2::theme(axis.text = ggplot2::element_blank())
  }
  
  if(interactive){
    p <- plotly::ggplotly(p, tooltip = c("text")) %>%
      plotly::config(displayModeBar = FALSE)
  } else{
    
  }
  
  return(p)
}
