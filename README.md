# Documentation for Kronemer et al., Communications Biology, 2025

The following information details the data sources, analysis scripts, and visualization methods for the results and figures presented in Kronemer et al., 2025. Full methods and statistical analyses details are written in the Kronemer et al., 2025 Methods and Statistical Analyses sections.

## RAW DATA

All control (n = 8) and patient participants (n = 8) have two associated file types:

1. Behavioral files (.log): Output behavioral files from the visual perception task. Many participants have multiple log files corresponding with multiple study sessions.

2. Eye tracking and pupillometry (.mat): Output EyeLink file (SR Research, Inc.) from the visual perception task. Each EyeLink file corresponds with a single log file. 

One patient participant (P4) completed additional behavioral and magnetoencephalography (MEG) study sessions. The additional behavioral session invovled an "adapted" perception task (see the "Adapated_Task" folder). The original task was tested with P4 in both behavioral and MEG study sessions (see "Original_Task" folder). The MEG sessions includes the behavioral log file and MEG files.

## CODE

1. Behavioral analysis (Afterimage_task_behavioral_analysis_v4.m): analyzes subject behavioral files and creates subject-level figures and matrices of all subject results. The output of these behavioral analyses are stored in Participant_Afterimage_Image_VVIQ_Data.xlsx. 

2. Bootstrapping analysis (Afterimage_vs_VVIQ_bootstrapping_analysis.m): reads data from Participant_Afterimage_Image_VVIQ_Data.xlsx and performs a bootstrap analysis on image and afterimage sharpness, contrast, and duration and creates summary figures used in Figure 3 (see details below).
