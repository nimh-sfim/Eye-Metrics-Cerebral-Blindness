# Documentation for Kronemer et al., Communications Biology, 2025

Abstract: Cerebral blindness is caused by damage to the primary visual pathway. Some people with cerebral blindness retain degraded vision and non-visual sensations and can perform visually guided behaviors within their blind visual field. These cases raise questions about visual conscious perception and residual neural processing in cerebral blindness. A major challenge in this research is that subjective reporting on experiences in the blind field can be unreliable. Alternatively, eye metrics offer a promising objective marker of conscious awareness, conscious content, and brain activity. In this study, we recorded visual stimulus-evoked pupil size, blink, and microsaccade responses in neurotypical participants and both the sighted and blind fields of cerebrally blind participants. For most patients, we found that eye metrics inferred conscious awareness in the blind field. Also, pupil size responded to both real and illusory stimulus luminance in the sighted field but not in the blind field. Furthermore, eye metrics were linked to visual stimulus-evoked occipital cortical field potentials in the blind field, suggesting residual cortical processing. These findings support eye metrics as an indicator of visual conscious perception and neural processing in cerebral blindness, with potential applications for tracking vision recovery following damage to the primary visual pathway.

The following information details the data sources and analysis scripts for the results and figures presented in Kronemer et al., Communications Biology, 2025. Full methods and statistical analyses details are written in the Kronemer et al., Communications Biology, 2025 Methods and Statistical and Reproducibility sections. All source data are available at https://osf.io/cygmj/

## RAW DATA

All control (n = 8) and patient participants (n = 8) have two associated file types (see Table 1 and 2 in Kronemer et al., 2025 for demographic information):

1. Behavioral files (.log): Output behavioral files from the visual perception task. Many participants have multiple log files corresponding with multiple study sessions.

2. Eye tracking and pupillometry files (.mat): Output EyeLink file (SR Research, Inc.) from the visual perception task. Each EyeLink file corresponds with a single log file. 

One patient participant (P4) completed additional behavioral and magnetoencephalography (MEG) study sessions. The additional behavioral session invovled an "adapted" perception task (see data directory Patients/P4/Adapted_Task on https://osf.io/cygmj/). The original task was tested with P4 in both behavioral and MEG study sessions (see data directory Patients/P4/Original_Task on https://osf.io/cygmj/). The MEG sessions includes the behavioral log file and MEG files.

## TASK & STIMULI

The behavioral task script and stimuli are included. The task script is integrated with EyeLink. To use the script with EyeLink requires installing the EyeLink Developer's Kit from SR Research, Inc. 

## CODE

Behavioral Analysis 

Behavioral analysis evaluates performance on the perception task, including perception rate and reaction time in the sighted and blind field for patient participants and the left and right visual field for control participants.

Relevant figures: Figure 2, Figure 6B, C, D, E, Supplementary Figure 1, and Supplementary Figure 2 

EyeLink Analysis

EyeLink analysis invovle preprocessing and extracting of eye measures (e.g., blink detection and removal from pupil size data and microsaccade detection). Eye measure epochs are segmented relative to task events and indexed by the presentation location. Group-level analysis evaluate eye metrics across participants. Machine learning analysis involves training on the eye measure epochs and predicting stimulus presentation vs absence of task stimuli in the sighted and blind field for patient participants and the left and right visual field for control participants.

Relevant figures: Figure 3, Figure 4, Figure 5, Figure 6A, Supplementary Figure 3, Supplementary Figure 5, and Supplemenatary Figure 6

MEG Analysis

MEG analysis assess event-related field changes associated with stimuli presented in the sighted and blind field of patient participant P4. Cluster-based permutation analyses are performed to assess statistically significant field potentials.

Relevant figures: Figure 6F and Supplementary Figure 7
