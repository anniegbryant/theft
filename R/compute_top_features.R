#--------------- Helper functions ----------------

#--------------------------
# Pairwise correlation plot
#--------------------------

draw_top_feature_plot <- function(data, method, cor_method, num_features){
  
  # Wrangle dataframe
  
  cor_dat <- data %>%
    dplyr::select(c(id, names, values)) %>%
    tidyr::drop_na() %>%
    dplyr::group_by(names) %>%
    dplyr::mutate(values = normalise_feature_vector(values, method = method)) %>%
    tidyr::drop_na() %>%
    tidyr::pivot_wider(id_cols = id, names_from = names, values_from = values) %>%
    dplyr::select(-c(id))
  
  # Calculate correlations
  
  result <- stats::cor(cor_dat, method = cor_method)
  
  # Perform clustering
  
  row.order <- stats::hclust(stats::dist(result))$order # Hierarchical cluster on rows
  col.order <- stats::hclust(stats::dist(t(result)))$order # Hierarchical cluster on columns
  dat_new <- result[row.order, col.order] # Re-order matrix by cluster outputs
  cluster_out <- reshape2::melt(as.matrix(dat_new)) # Turn into dataframe
  
  # Draw plot
  
  FeatureFeatureCorrelationPlot <- cluster_out %>%
    ggplot2::ggplot(ggplot2::aes(x = Var1, y = Var2)) +
    ggplot2::geom_tile(ggplot2::aes(fill = value)) +
    ggplot2::labs(title = paste0("Pairwise correlation matrix of top ", num_features, " features"),
                  x = NULL,
                  y = NULL,
                  fill = "Correlation coefficient") +
    ggplot2::scale_fill_distiller(palette = "RdBu", limits = c(-1, 1)) +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                   legend.position = "bottom",
                   axis.text.x = ggplot2::element_text(angle = 90, hjust = 1))
  
  return(FeatureFeatureCorrelationPlot)
}

#-------------
# Violin plots
#-------------

plot_feature_discrimination <- function(data, id_var = "id", group_var = "group",
                                        normalise = FALSE,
                                        method = c("z-score", "Sigmoid", "RobustSigmoid", "MinMax"),
                                        rank_data){
  
  #------------- Normalise data -------------------
  
  if(normalise){
    
    normed <- data %>%
      dplyr::select(c(id, names, values, group)) %>%
      tidyr::drop_na() %>%
      dplyr::group_by(names) %>%
      dplyr::mutate(values = normalise_feature_vector(values, method = method)) %>%
      dplyr::ungroup() %>%
      tidyr::drop_na()
    
    if(nrow(normed) != nrow(data)){
      message("Filtered out rows containing NaNs.")
    }
  } else{
    normed <- data
  }
  
  #------------- Normalise data -------------------
  
  facet_order <- rank_data %>%
      dplyr::pull(feature)
  
  normed <- normed %>% 
    dplyr::mutate(names = factor(names, levels = facet_order))
  
  #------------- Produce plots --------------------
  
  # Draw plot
  
  p <- normed %>%
    dplyr::mutate(group = as.factor(group)) %>%
    ggplot2::ggplot(ggplot2::aes(x = group, y = values, colour = group)) +
    ggplot2::geom_violin() +
    ggplot2::geom_point(size = 1, alpha = 0.9, position = ggplot2::position_jitter(w = 0.05)) +
    ggplot2::labs(title = "Class discrimination for top performing features",
                  subtitle = "Features are ordered by performance from left to right",
                  x = "Class",
                  y = "Value") +
    ggplot2::scale_colour_brewer(palette = "Dark2") +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = "none",
                   panel.grid.minor = ggplot2::element_blank(),
                   strip.background = ggplot2::element_blank(),
                   axis.text.x = element_text(angle = 90))
  
  if(normalise){
    p <- p +
      ggplot2::facet_wrap(~names, ncol = 4)
  } else{
    p <- p +
      ggplot2::facet_wrap(~names, ncol = 4, scales = "free_y")
  }
  
  return(p)
}

#-------------- Main exported function ---------------

#' Return an object containing results from top-performing features on a classification task
#' @import dplyr
#' @importFrom magrittr %>%
#' @import ggplot2
#' @importFrom tidyr drop_na pivot_wider
#' @importFrom stats hclust dist cor
#' @importFrom reshape2 melt
#' @importFrom janitor clean_names
#' @param data the dataframe containing the raw feature matrix
#' @param id_var a string specifying the ID variable to group data on (if one exists). Defaults to \code{"id"}
#' @param group_var a string specifying the grouping variable that the data aggregates to. Defaults to \code{"group"}
#' @param num_features the number of top features to retain and explore. Defaults to \code{40}
#' @param normalise_violin_plots a Boolean of whether to normalise features before plotting. Defaults to \code{FALSE}
#' @param method a rescaling/normalising method to apply. Defaults to \code{"RobustSigmoid"}
#' @param cor_method the correlation method to use. Defaults to \code{"pearson"}
#' @param test_method the algorithm to use for quantifying class separation. Defaults to \code{"gaussprRadial"}
#' @param use_k_fold a Boolean specifying whether to use k-fold procedures for generating a distribution of classification accuracy estimates if a \code{caret} model is specified for \code{test_method}. Defaults to \code{ FALSE}
#' @param num_folds an integer specifying the number of k-folds to perform if \code{use_k_fold} is set to \code{TRUE}. Defaults to \code{10}
#' @param use_empirical_null a Boolean specifying whether to use empirical null procedures to compute p-values if a \code{caret} model is specified for \code{test_method}. Defaults to \code{FALSE}
#' @param null_testing_method a string specifying the type of statistical method to use to calculate p-values. Defaults to \code{model free shuffles}
#' @param p_value_method a string specifying the method of calculating p-values. Defaults to \code{"empirical"}
#' @param num_permutations an integer specifying the number of class label shuffles to perform if \code{use_empirical_null} is \code{TRUE}. Defaults to \code{50}
#' @param pool_empirical_null a Boolean specifying whether to use the pooled empirical null distribution of all features or each features' individual empirical null distribution if a \code{caret} model is specified for \code{test_method} use_empirical_null is \code{TRUE}. Defaults to \code{FALSE}
#' @return an object of class list containing a dataframe of results, a feature x feature matrix plot, and a violin plot
#' @author Trent Henderson
#' @export
#' @examples
#' \dontrun{
#' featMat <- calculate_features(data = simData, 
#'   id_var = "id", 
#'   time_var = "timepoint", 
#'   values_var = "values", 
#'   group_var = "process", 
#'   feature_set = "catch22")
#'   
#' compute_top_features(featMat,
#'   id_var = "id",
#'   group_var = "group",
#'   num_features = 10,
#'   normalise_violin_plots = FALSE,
#'   method = "RobustSigmoid",
#'   cor_method = "pearson",
#'   test_method = "gaussprRadial",
#'   use_k_fold = FALSE,
#'   num_folds = 10,
#'   use_empirical_null = TRUE,
#'   null_testing_method = "model free shuffles",
#'   p_value_method = "empirical",
#'   num_permutations = 100,
#'   pool_empirical_null = FALSE) 
#' }
#' 

compute_top_features <- function(data, id_var = "id", group_var = "group",
                                 num_features = 40,
                                 normalise_violin_plots = FALSE,
                                 method = c("z-score", "Sigmoid", "RobustSigmoid", "MinMax"),
                                 cor_method = c("pearson", "spearman"),
                                 test_method = "gaussprRadial",
                                 use_k_fold = FALSE, num_folds = 10, 
                                 use_empirical_null = FALSE, null_testing_method = c("model free shuffles", "null model fits"),
                                 p_value_method = c("empirical", "gaussian"), num_permutations = 50,
                                 pool_empirical_null = FALSE){
  
  # Make RobustSigmoid the default
  
  if(missing(method)){
    method <- "RobustSigmoid"
  } else{
    method <- match.arg(method)
  }
  
  # Make pearson the default
  
  if(missing(cor_method)){
    cor_method <- "pearson"
  } else{
    cor_method <- match.arg(cor_method)
  }
  
  # Check other arguments
  
  expected_cols_1 <- "names"
  expected_cols_2 <- "values"
  expected_cols_3 <- "method"
  the_cols <- colnames(data)
  '%ni%' <- Negate('%in%')
  
  if(expected_cols_1 %ni% the_cols){
    stop("data should contain at least three columns called 'names', 'values', and 'method'. These are automatically produced by calculate_features(). Please consider running this first and then passing the resultant dataframe in to this function.")
  }
  
  if(expected_cols_2 %ni% the_cols){
    stop("data should contain at least three columns called 'names', 'values', and 'method'. These are automatically produced by calculate_features(). Please consider running this first and then passing the resultant dataframe in to this function.")
  }
  
  if(expected_cols_3 %ni% the_cols){
    stop("data should contain at least three columns called 'names', 'values', and 'method'. These are automatically produced by calculate_features(). Please consider running this first and then passing the resultant dataframe in to this function.")
  }
  
  if(!is.numeric(data$values)){
    stop("'values' column in data should be a numerical vector.")
  }
  
  if(!is.null(id_var) && !is.character(id_var)){
    stop("id_var should be a string specifying a variable in the input data that uniquely identifies each observation.")
  }
  
  if(!is.null(group_var) && !is.character(group_var)){
    stop("group_var should be a string specifying a variable in the input data that identifies an aggregate group each observation relates to.")
  }
  
  # Method selection
  
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
  
  # Null testing options
  
  theoptions <- c("model free shuffles", "null model fits")
  
  if(is.null(null_testing_method) || missing(null_testing_method)){
    null_testing_method <- "model free shuffles"
    message("No argument supplied to null_testing_method. Using 'model free shuffles' as default.")
  }
  
  if(length(null_testing_method) != 1){
    stop("null_testing_method should be a single string of either 'model free shuffles' or 'null model fits'.")
  }
  
  if(null_testing_method %ni% theoptions){
    stop("null_testing_method should be a single string of either 'model free shuffles' or 'null model fits'.")
  }
  
  if(null_testing_method == "model free shuffles" && pool_empirical_null){
    stop("'model free shuffles' and pooled empirical null are incompatible (pooled null combines each feature's null into a grand null and features don'tt get a null if 'model free shuffles' is used). Please respecify.")
  }
  
  # p-value options
  
  theoptions_p <- c("empirical", "gaussian")
  
  if(is.null(p_value_method) || missing(p_value_method)){
    p_value_method <- "empirical"
    message("No argument supplied to p_value_method Using 'empirical' as default.")
  }
  
  if(length(p_value_method) != 1){
    stop("p_value_method should be a single string of either 'empirical' or 'gaussian'.")
  }
  
  if(p_value_method %ni% theoptions_p){
    stop("p_value_method should be a single string of either 'empirical' or 'gaussian'.")
  }
  
  # Default feature number
  
  if(!is.numeric(num_features)){
    stop("num_features should be a positive integer >= 2 specifying the number of features to produce analysis for.")
  }
  
  if(num_features < 2){
    stop("num_features should be a positive integer >= 2 specifying the number of features to produce analysis for.")
  }
  
  if(is.null(id_var)){
    stop("Data is not uniquely identifiable. Please add a unique identifier variable.")
  }
  
  if(!is.null(id_var)){
    data_id <- data %>%
      dplyr::rename(id = dplyr::all_of(id_var),
                    group = dplyr::all_of(group_var)) %>%
      dplyr::select(c(id, group, method, names, values))
  }
  
  num_classes <- length(unique(data_id$group)) # Get number of classes in the data
  
  if(num_classes == 1){
    stop("Your data only has one class label. At least two are required to performed analysis.")
  }
  
  if(num_classes == 2){
    message("Your data has two classes. Setting test_method to one of 't-test', 'wilcox', or 'binomial logistic' is recommended.")
  }
  
  if(((missing(test_method) || is.null(test_method))) && num_classes == 2){
    test_method <- "t-test"
    message("test_method is NULL or missing. Running t-test for 2-class problem.")
  }
  
  if(((missing(test_method) || is.null(test_method))) && num_classes > 2){
    test_method <- "gaussprRadial"
    message("test_method is NULL or missing, fitting 'gaussprRadial' by default.")
  }
  
  if(test_method %in% c("t-test", "wilcox", "binomial logistic") && num_classes > 2){
    stop("t-test, Mann-Whitney-Wilcoxon Test and binomial logistic regression can only be run for 2-class problems.")
  }
  
  # Splits and shuffles
  
  if(use_k_fold == TRUE && !is.numeric(num_folds)){
    stop("num_folds should be a positive integer. 10 folds is recommended.")
  }
  
  if(use_empirical_null == TRUE && !is.numeric(num_permutations)){
    stop("num_permutations should be a postive integer. A minimum of 50 permutations is recommended.")
  }
  
  if(use_empirical_null == TRUE && num_permutations < 3){
    stop("num_permutations should be a positive integer >= 3 for empirical null calculations. A minimum of 50 permutations is recommended.")
  }
  
  if(use_k_fold == TRUE && num_folds < 1){
    stop("num_folds should be a positive integer. 10 folds is recommended.")
  }
  
  # Number of top features
  
  if(num_features > length(unique(data_id$names))){
    num_features <- length(unique(data_id$names))
    message(paste0("Number of specified features exceeds number of features in your data. Automatically adjusting to ", num_features))
  }
  
  # Prep factor levels as names for {caret} if the 3 base two-class options aren't being used
  
  if(test_method %ni% c("t-test", "wilcox", "binomial logistic")){
    data_id <- data_id %>%
      dplyr::mutate(group = make.names(group),
                    group = as.factor(group))
  } else{
    data_id <- data_id %>%
      dplyr::mutate(group = as.factor(group))
  }
  
  #---------------  Computations ----------------
  
  #---------------
  # Classification
  #---------------
  
  # Fit algorithm
  
  classifierOutputs <- fit_feature_classifier(data_id, 
                                              id_var = "id", 
                                              group_var = "group",
                                              test_method = test_method,
                                              use_k_fold = use_k_fold,
                                              num_folds = num_folds,
                                              use_empirical_null = use_empirical_null,
                                              null_testing_method = null_testing_method,
                                              p_value_method = p_value_method,
                                              num_permutations = num_permutations,
                                              pool_empirical_null = pool_empirical_null,
                                              return_raw_estimates = FALSE)
  
  # Filter results to get list of top features
  
  if(test_method %in% c("t-test", "wilcox", "binomial logistic")){
    
    message("\nSelecting top features using p-values.")
    
    ResultsTable <- classifierOutputs %>%
      dplyr::slice_min(p_value, n = num_features)
    
  } else{
    
    if(use_empirical_null == FALSE){
      
      message("\nSelecting top features using mean classification accuracy.")
      
      ResultsTable <- classifierOutputs %>%
        dplyr::slice_max(statistic_value, n = num_features)
      
    } else{
      
      # Catch cases where most of the p-values are the same (likely 0 given empirical null performance from experiments)
      
      unique_p_values <- classifierOutputs %>%
        dplyr::slice_min(p_value, n = num_features)
      
      if(length(unique(unique_p_values$feature)) > num_features || length(unique(unique_p_values$p_value)) == 1){
        
        message("\nNot enough unique p-values to select top features informatively. Selecting top features using mean classification accuracy instead.")
        
        ResultsTable <- classifierOutputs %>%
          dplyr::slice_max(statistic_value, n = num_features)
        
      } else{
        
        message("\nSelecting top features using p-value.")
        
        ResultsTable <- classifierOutputs %>%
          dplyr::slice_min(p_value, n = num_features)
      }
    }
  }
  
  # Filter original data to just the top performers
  
  dataFiltered <- data_id %>%
    dplyr::mutate(names = paste0(method, "_", names)) %>%
    dplyr::select(-c(method)) %>%
    tidyr::pivot_wider(id_cols = c("id", "group"), names_from = "names", values_from = "values") %>%
    janitor::clean_names() %>%
    tidyr::pivot_longer(cols = !c("id", "group"), names_to = "names", values_to = "values") %>%
    dplyr::filter(names %in% ResultsTable$feature)
  
  #-----------------------
  # Feature x feature plot
  #-----------------------
  
  # Wrap in a try because sometimes normalisation methods create issues that error out the whole function
  
  FeatureFeatureCorrelationPlot <- try(draw_top_feature_plot(data = dataFiltered,
                                                             method = method,
                                                             cor_method = cor_method,
                                                             num_features = num_features))
  
  if("try-error" %in% class(FeatureFeatureCorrelationPlot)){
    
    message("An error occured producing the summary plot. Re-running with z-score normalisation to see if error is corrected.")
    
    FeatureFeatureCorrelationPlot <- try(draw_top_feature_plot(data = dataFiltered,
                                                               method = "z-score",
                                                               cor_method = cor_method,
                                                               num_features = num_features))
  }
  
  #---------------
  # Violin plot
  #---------------
  
  ViolinPlots <- plot_feature_discrimination(dataFiltered, 
                                             id_var = "id", 
                                             group_var = "group",
                                             normalise = normalise_violin_plots,
                                             method = method,
                                             rank_data = ResultsTable)
  
  #---------------  Returns ---------------------
  
  # Compile into one object and return
  
  if("try-error" %in% class(FeatureFeatureCorrelationPlot)){
    
    message("An error occured in producing the second attempted graphic with different normalisation. Only returning numerical results and violin plots instead.")
    myList <- list(ResultsTable, ViolinPlots)
    names(myList) <- c("ResultsTable", "ViolinPlots")
    
  } else{
    
    myList <- list(ResultsTable, FeatureFeatureCorrelationPlot, ViolinPlots)
    names(myList) <- c("ResultsTable", "FeatureFeatureCorrelationPlot", "ViolinPlots")
  }
  
  return(myList)
}
