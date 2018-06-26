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
% If you modify those values, you should also modify in the opening fcn of
% training_params_GUI
training_params_local.class_specific.default.subsample = 100;
training_params_local.class_specific.default.SVM.DeltaGradientTolerance = 1e-3;
training_params_local.class_specific.default.SVM.IterationLimit = 1e6;
training_params_local.class_specific.default.SVM.GapTolerance = 0;
training_params_local.class_specific.default.SVM.ShrinkagePeriod = 0;
training_params_local.class_specific.default.SVM.KKTTolerance = 0;
training_params_local.class_specific.default.SVM.KernelFunction = 'Gaussian';
training_params_local.class_specific.default.SVM.KernelScale = 1;
training_params_local.class_specific.default.SVM.PolynomialOrder = 3;
training_params_local.class_specific.default.SVM.Standardize = false;
training_params_local.class_specific.default.SVM.BoxConstraint = 1;
training_params_local.class_specific.default.OptimizeSVM.KernelFunction = {};
training_params_local.class_specific.default.OptimizeSVM.KernelScale.Optimize = false;
training_params_local.class_specific.default.OptimizeSVM.KernelScale.Range = [1e-3 1e3];
training_params_local.class_specific.default.OptimizeSVM.PolynomialOrder.Optimize = false;
training_params_local.class_specific.default.OptimizeSVM.PolynomialOrder.Range = [2 4];
training_params_local.class_specific.default.OptimizeSVM.Standardize.Optimize = false;
training_params_local.class_specific.default.OptimizeSVM.BoxConstraint.Optimize = false;
training_params_local.class_specific.default.OptimizeSVM.BoxConstraint.Range = [1e-3 1e3];