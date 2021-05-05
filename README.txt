Repository containing the Matlab code for the paper
"Disentangling the percepts of illusory movement and sensory stimulation during tendon vibration in the EEG", Schneider et al. (submitted)
That dataset used in this study is publicly available as OpenNeuro dataset 10.18112/openneuro.ds003343.v2.0.1.


Before running the scripts make sure Matlab is installed (equal or newer than version 2021a).
Likewise, large parts of the code depend on the FieldTrip toolbox being integrated in Matlab.

In order to launch the processing pipeline, make sure you first set your local data paths by changing the paths in Set_Paths.m and run the script. Then, run the Run_all.m script. Individual parts of the analysis pipeline can be run independently by using the Run_* scripts in the subfolders 1 - 5, as long as the necessary data is located in the local directories.


Author: Christoph Schneider
Acute Neurorehabilitation Unit (LRNA)
Division of Neurology, Department of Clinical Neurosciences
Centre Hospitalier Universitaire Vaudois (CHUV)
Rue du Bugnon 46, CH-1011 Lausanne, Switzerland
email: christoph.schneider.phd@gmail.com 

Last update: May 2021