#---------------------------------------
# This script sets out to test the core
# functionality of the {theft} package.
#
# NOTE: This should be converted to the
# {testthat} package for full proper
# unit tests
#---------------------------------------

#---------------------------------------
# Author: Trent Henderson, 7 April 2021
#---------------------------------------

library(dplyr)
library(theft)
library(reticulate)

#------------------- Feature extraction -----------------------------

#outs_all <- calculate_features(data = simData, id_var = "id", time_var = "timepoint", values_var = "values", group_var = "process", feature_set = "all")
outs_22 <- calculate_features(data = simData, id_var = "id", time_var = "timepoint", values_var = "values", group_var = "process", feature_set = "catch22", catch24 = FALSE)
outs_24 <- calculate_features(data = simData, id_var = "id", time_var = "timepoint", values_var = "values", group_var = "process", feature_set = "catch22", catch24 = TRUE)
#outs_fe <- calculate_features(data = simData, id_var = "id", time_var = "timepoint", values_var = "values", group_var = "process", feature_set = "feasts")
#outs_ts <- calculate_features(data = simData, id_var = "id", time_var = "timepoint", values_var = "values", group_var = "process", feature_set = "tsfeatures")

#reticulate::use_python("~/opt/anaconda3/bin/python", required = TRUE)
#outs_tsfresh <- calculate_features(data = simData, id_var = "id", time_var = "timepoint", values_var = "values", group_var = "process", feature_set = "tsfresh", tsfresh_cleanup = FALSE)
#outs_tsfel <- calculate_features(data = simData, id_var = "id", time_var = "timepoint", values_var = "values", group_var = "process", feature_set = "tsfel")
#outs_kats <- calculate_features(data = simData, id_var = "id", time_var = "timepoint", values_var = "values", group_var = "process", feature_set = "kats")

#------------------- Other package functionality --------------------

# Test 1: Data quality matrix

plot_quality_matrix(outs_22)

# Test 2: Normalisation

normed <- normalise_feature_frame(outs_22, names_var = "names", values_var = "values", method = c("RobustSigmoid"))

# Test 3: Feature matrix

plot_feature_matrix(normed, is_normalised = TRUE, id_var = "id", method = "RobustSigmoid", interactive = FALSE)
plot_feature_matrix(outs_22, is_normalised = FALSE, id_var = "id", method = "RobustSigmoid", interactive = FALSE)
plot_feature_matrix(outs_22, is_normalised = FALSE, id_var = "id", method = "RobustSigmoid", interactive = TRUE)

plot_feature_matrix(outs_22, is_normalised = FALSE, id_var = "id", method = "z-score", interactive = FALSE)
plot_feature_matrix(outs_22, is_normalised = FALSE, id_var = "id", method = "z-score", interactive = TRUE)

# Test 4: Low dimension

plot_low_dimension(outs_22, is_normalised = FALSE, id_var = "id", group_var = "group", plot = TRUE, method = "RobustSigmoid", low_dim_method = "PCA", show_covariance = FALSE)
plot_low_dimension(outs_22, is_normalised = FALSE, id_var = "id", group_var = "group", plot = TRUE, method = "RobustSigmoid", low_dim_method = "PCA", show_covariance = TRUE)
plot_low_dimension(normed, is_normalised = TRUE, id_var = "id", group_var = "group", plot = TRUE, method = "RobustSigmoid", low_dim_method = "PCA")
plot_low_dimension(outs_22, is_normalised = FALSE, id_var = "id", group_var = "group", plot = TRUE, method = "RobustSigmoid", low_dim_method = "t-SNE", perplexity = 5)
plot_low_dimension(normed, is_normalised = TRUE, id_var = "id", group_var = "group", plot = TRUE, method = "RobustSigmoid", low_dim_method = "t-SNE", perplexity = 5)
d1 <- plot_low_dimension(outs_22, is_normalised = FALSE, id_var = "id", group_var = "group", plot = FALSE, method = "RobustSigmoid", low_dim_method = "PCA")
d2 <- plot_low_dimension(outs_22, is_normalised = FALSE, id_var = "id", group_var = "group", plot = FALSE, method = "RobustSigmoid", low_dim_method = "t-SNE", perplexity = 5)

# Test 5: Time-series correlations

plot_ts_correlations(simData, is_normalised = FALSE, id_var = "id", time_var = "timepoint", values_var = "values", method = "RobustSigmoid", cor_method = "pearson", interactive = FALSE)
plot_ts_correlations(simData, is_normalised = FALSE, id_var = "id", time_var = "timepoint", values_var = "values", method = "RobustSigmoid", cor_method = "spearman", interactive = FALSE)
plot_ts_correlations(simData, is_normalised = FALSE, id_var = "id", time_var = "timepoint", values_var = "values", method = "RobustSigmoid", interactive = TRUE)

# Test 6: Feature correlations

plot_feature_correlations(outs_22, is_normalised = FALSE, id_var = "id", names_var = "names", values_var = "values", method = "RobustSigmoid", cor_method = "pearson", interactive = FALSE)
plot_feature_correlations(outs_22, is_normalised = FALSE, id_var = "id", names_var = "names", values_var = "values", method = "RobustSigmoid", cor_method = "spearman", interactive = FALSE)
plot_feature_correlations(outs_22, is_normalised = FALSE, id_var = "id", names_var = "names", values_var = "values", method = "RobustSigmoid", interactive = TRUE)

# Test 9: Multivariable classification

feature_matrix2 <- calculate_features(data = simData, 
                                      id_var = "id", 
                                      time_var = "timepoint", 
                                      values_var = "values", 
                                      group_var = "process", 
                                      feature_set = c("catch22", "feasts"))

multi_classifier_outputs <- fit_multivariable_classifier(feature_matrix2, id_var = "id", group_var = "group",
                                                        by_set = TRUE, test_method = "gaussprRadial",
                                                        use_k_fold = TRUE, num_folds = 10, 
                                                        use_empirical_null = TRUE, null_testing_method = "model free shuffles",
                                                        p_value_method = "empirical", num_permutations = 100)

multi_classifier_outputs2 <- fit_multivariable_classifier(feature_matrix2, id_var = "id", group_var = "group",
                                                        by_set = FALSE, test_method = "svmLinear",
                                                        use_k_fold = FALSE, num_folds = 10, 
                                                        use_empirical_null = TRUE, null_testing_method = "null model fits",
                                                        p_value_method = "empirical", num_permutations = 50)

# Test 8: Feature-level classification

# Multiclass

classifier_outputs <- compute_top_features(outs_22, 
                                           id_var = "id", 
                                           group_var = "group",
                                           num_features = 10, 
                                           normalise_violin_plots = FALSE,
                                           method = "RobustSigmoid",
                                           cor_method = "pearson",
                                           test_method = "gaussprRadial",
                                           use_k_fold = TRUE,
                                           num_folds = 10,
                                           use_empirical_null =  TRUE,
                                           null_testing_method = "model free shuffles",
                                           num_permutations = 100,
                                           p_value_method = "empirical",
                                           pool_empirical_null = FALSE) 

classifier_outputs_2 <- compute_top_features(outs_22, 
                                             id_var = "id", 
                                             group_var = "group",
                                             num_features = 40, 
                                             normalise_violin_plots = FALSE,
                                             method = "z-score",
                                             cor_method = "pearson",
                                             test_method = "gaussprRadial",
                                             use_k_fold = TRUE,
                                             num_folds = 10,
                                             use_empirical_null =  TRUE,
                                             null_testing_method = "null model fits",
                                             num_permutations = 10,
                                             p_value_method = "gaussian",
                                             pool_empirical_null = TRUE)

classifier_outputs_3 <- compute_top_features(outs_22, 
                                             id_var = "id", 
                                             group_var = "group",
                                             num_features = 40, 
                                             normalise_violin_plots = FALSE,
                                             method = "z-score",
                                             cor_method = "pearson",
                                             test_method = "gaussprRadial",
                                             use_k_fold = FALSE,
                                             num_folds = 10,
                                             use_empirical_null =  FALSE,
                                             num_permutations = 10,
                                             pool_empirical_null = TRUE)
  
# Two-class

twoclass <- outs_22 %>% filter(group %in% c("Gaussian Noise", "AR(1)"))
classifier_outputs_two <- compute_top_features(twoclass, id_var = "id", group_var = "group", num_features = 40, normalise_violin_plots = FALSE, method = "RobustSigmoid", cor_method = "pearson", test_method = "t-test")
classifier_outputs_two_2 <- compute_top_features(twoclass, id_var = "id", group_var = "group", num_features = 40, normalise_violin_plots = FALSE, method = "RobustSigmoid", cor_method = "pearson", test_method = "wilcox")
classifier_outputs_two_3 <- compute_top_features(twoclass, id_var = "id", group_var = "group", num_features = 40, normalise_violin_plots = FALSE, method = "RobustSigmoid", cor_method = "pearson", test_method = "binomial logistic")

# Test 9: Processing hctsa formatted file

d2 <- process_hctsa_file("https://cloudstor.aarnet.edu.au/plus/s/6sRD6IPMJyZLNlN/download")

#------------------- Non-real value catches --------------------

data1 <- data.frame(values = c(1,2,3,NA,Inf,-Inf,NA,8,9,10)) %>% mutate(id = "1", timepoint = row_number())
data2 <- data.frame(values = c(1,2,3,4,5,6,7,8,9,10)) %>% mutate(id = "2", timepoint = row_number())
data <- bind_rows(data1, data2)
outs_NA <- calculate_features(data, id_var = "id", time_var = "timepoint", values_var = "values", feature_set = "catch22")
