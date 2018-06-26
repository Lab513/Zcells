# ZstackSegmentation
ZstackSegmentation is a segmentation technique of microscopy images based on Z-stacks, inspired by hyperspectral imaging.
For more information on the same, you may visit the wiki at <https://github.com/Lab513/ZstackSegmentation/wiki>

The whole process is divided into two main parts, training and prediction. Thus, there are two main user scripts, training_script.m and prediction_script.m, about which we will discuss in the following sections.

For further details about each of the functions and the parameters they take and return, you may read the relevant parts of the source code, which have comments explaining the same.

## Training Phase
To launch the training, just type the following command in Matlab (version R2016b or later required)

`````matlab
training_script
`````

#### Labelling the Zstacks
A GUI window should pop up, where you can either load new and unlabelled Zstacks, or even load some already labelled Zstack. The Zstacks should be somewhere in the working directory or one of its subdirectories the system to work.

Once the selected Zstack displays on the screen, you may proceed to start labelling. You can add a class, decide its hierarchial relationship with the other classes, the colour used to represent it and so on. Once you set up the class, you can click the "Append Pixels" button to start labelling the picture. The pixels will be labelled with the class that is selected from the list of classes on the left. You can use the zoom option of the Matlab GUI to zoom in and out of the image as per the requirement, then left click to mark the corner edges of the closed region that you want to select. After putting in the last vertex, it can be automatically joined to the first one by right clicking anywhere on the image. Then double left click on the selected closed loop to finally colour it solid with the colour of the selected class.

You can save the labelled dataset for future use using the save option from the Matlab GUI.

#### Selecting Parameters and Launching the Training
You can click the "Training Parameters" button to get a GUI window which allows you to specify the various parameters for training. These include choice of kernel for the SVM, various parallelization options, frame sub-selection options, options for PCA etc.

A good set of default, off-the shelf parameters would be as follows-

(1) Focus shifting enabled, with radius anywhere between 1 to 5- the higher the better (this is like data augmentation, and the higher the number, the more the augmentation)

(2) Parallel processing enabled- For purely performance reasons

(3) Standardize option within the SVM hyperparameters enabled - This helps in faster and better convergence of the SVMs.

(4) Auto option within SVM hyperparamters enabled.

It should be a good starting point to label around 2000 pixels of each class while training. Once this gives the proof of concept, larger datasets can be labelled for even better performance.

Once you specify all that, you can simply close this window, and click on "Launch Training" to start training the SVMs.

Once the training is over, you will be asked if you want to save the newly trained classifier.

## Prediction Phase
For the prediction phase, you need to issue the following commands in Matlab

`````matlab
addpath(genpath('.'));
predictionDisplayGUI
`````

This should make a GUI window pop-up. It would have some default image, but you need not worry about that. You can select a trained SVM that you want to use for the prediction as well as the Zstacks that you want to run the prediction on. You can select the options for frame sub-selection and parallelization. Then click on the "Launch Prediction" button to start the prediction. 

This may take a while so feel free to grab a coffee while this goes on. If you don't like coffee, that's fine too. 

Once done, you will notice that the within the "Display" section of the GUI, the two radio buttons at the bottom are now usable. If you want to see the classification results of all the pixels for all the classes, click on the "Classification For Selected Class" radio button, and select all the classes by clicking on the one by one and pressing and holding the ctrl key for the whole time. You will see all classes being displayed on the screen.

Here too you can use the Matlab GUI save button to write your results to the disk.
