function initialize_training_params()

global training_params_local


training_params_local.maxmemUse = 4;
training_params_local.frames_subselection.type = 'all';
training_params_local.frames_subselection.nbframes_linlog = 20;
training_params_local.frames_subselection.custom_set = [1, 2, 3];
training_params_local.frames_subselection.frames = process_framessubselection(training_params_local.frames_subselection,training_params_local.nbframes);
training_params_local.feature_extraction.nbcomponents = 15;
training_params_local.feature_extraction.subsampling = 100;
training_params_local.focus_shifting.status = true;
training_params_local.focus_shifting.radius = 5;
training_params_local.parallel_processing.status = false;
training_params_local.parallel_processing.cluster_profile = parallel.defaultClusterProfile;
% Class-specific default:
training_params_local.class_specific.default.subsample = 100;
training_params_local.class_specific.default.SVM.NumTrees = 50;
training_params_local.class_specific.default.SVM.InBagFraction = 1;
training_params_local.class_specific.default.SVM.MinLeafSize = 1;
training_params_local.class_specific.default.SVM.SampleWithReplacement = 1;