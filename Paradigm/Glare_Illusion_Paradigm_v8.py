# **************************************
# *** GLARE ILLUSION PERCEPTION TASK ***
# **************************************

# Written by: Sharif I. Kronemer
# Last Modified: 3/12/2024

# Version #
task_version = 'v8'

# ***************************
# *** IMPORTANT LIBRARIES ***
# ***************************

# Python and Psychopy Functions
import random
import warnings
from psychopy import visual, gui, data, core, event, monitors, logging, sound 
from psychopy.hardware import keyboard
import numpy as np
import time
import pylink
import os
import platform
import sys
from scipy.signal import find_peaks
import argparse
from collections import deque
from scipy.io import loadmat, savemat
import statistics 
from scipy.signal import savgol_filter, find_peaks, peak_prominences
from scipy.optimize import curve_fit
import math

# EyeLink Functions
from EyeLinkCoreGraphicsPsychoPy import EyeLinkCoreGraphicsPsychoPy
from PIL import Image
from string import ascii_letters, digits

# ********************
# *** SETUP SCREEN ***
# ********************

# Setup the subject info screen
info = {'Session #': 1, 'Subject ID': 'Test', 'EyeLink': ['n','y'], 'EyeLink EDF': 'test.edf', 'Button Condition':['1','2'], '(1) Skip Positioning Phase': ['n','y'], 
        '(2) Skip Main Phase': ['n','y'], '(3) Skip Brightness Phase': ['n','y'],'(4) Skip Afterimage Phase': ['n','y'], 'Final X position':0,'Final Y position':0}

# Experiment title
dlg = gui.DlgFromDict(info, title = 'Glare Illusion Perception Experiment')

# Find experiment date
info['date'] = data.getDateStr()

# Set this variable to True if you use the built-in retina screen as your 
# primary display device on macOS. If have an external monitor, set this 
# variable True if you choose to "Optimize for Built-in Retina Display" 
# in the Displays preference settings.
use_retina = True

# ********************
# *** SETUP WINDOW ***
# ********************

# Define screen resolution
resolution = [2560, 1440] 

# Setup the window
# Note: Screen is set to gray (0,0,0)
win = visual.Window(size = resolution, color = [0,0,0], monitor = 'testMonitor', fullscr = True, units ='cm') #Set color and fullscreen mode (True or False)

# *****************************************
# *** MANAGE DATA FOLDERS AND FILENAMES ***
# *****************************************

# Filename = Subject ID entered above
sub_filename = info['Subject ID']

# Behavioral data file
behavioral_folder = 'Behavioral_Data'

# Check for the behavioral data directory, otherwise make it
if not os.path.isdir(behavioral_folder):
        os.makedirs(behavioral_folder)  # if this fails (e.g. permissions) we will get error

# Eyelink data file
eyelink_folder = 'EyeLink_Data'

# Check for the EyeLink data directory, otherwise make it
if not os.path.isdir(eyelink_folder):
        os.makedirs(eyelink_folder) # if this fails (e.g. permissions) we will get error

# EyeLink EDF filename
tmp_str = info['EyeLink EDF']

# Strip trailing characters, ignore the ".edf" extension
edf_fname = tmp_str.rstrip().split('.')[0]

# Check if the EDF filename is valid (length <= 8 & no special char)
allowed_char = ascii_letters + digits + '_'

# If too many characters in EyeLink filename
if not all([c in allowed_char for c in edf_fname]):
    print('ERROR: *** Invalid EDF filename')
    core.quit()  # abort experiment

elif len(edf_fname) > 8:
    print('ERROR: *** EDF filename should not exceed 8 characters')
    core.quit()  # abort experiment

# Download EDF data file from the EyeLink Host PC to the local hard
# drive at the end of each testing session, here we rename the EDF to
# include session start date/time
time_str = time.strftime("_%Y_%m_%d_%H_%M", time.localtime())
session_identifier = edf_fname + time_str

# Setup log file
# Note: Show only critical log messages in the PsychoPy console
logFile = logging.LogFile(behavioral_folder + os.path.sep + sub_filename + '_Session_'+str(info['Session #'])+'_Glare_Illusion_Perception_'+info['date']+'_'+task_version+'.log', level=logging.EXP)

# Button Condition 
button_condition = int(info['Button Condition'])
    
# ***********************
# *** TASK PARAMETERS ***
# ***********************

# Max block number
max_num_blocks = 30

# Main Task Phase

# Number of stimuli
num_glare_stim = 8
num_nonglare_stim = 8
num_iso_stim = 8
num_white_stim = 8
num_distractor_plus_stim = 4
num_distractor_cross_stim = 4

# Stimulus duration
stimulus_duration = 3 # in seconds

# Set inter-stimulus interval (ISI) min and max durations
ISI_min_duration_sec = 3 # in seconds
ISI_max_duration_sec = 5 # in seconds

# Stimulus start locations
start_stim_x_pos = 12 # in centimeters
start_stim_y_pos = 5 # in centimeters

# ********************
# *** TASK STIMULI ***
# ********************

# Setup fixation cross
fixation = visual.TextStim(win, text="+", color = 'black', pos = [0, 0], autoLog = False)
fixation.size = 2 # in centimeters

# Define stimulus image directory
_thisDir = os.path.dirname(os.path.abspath(__file__))
os.chdir(_thisDir)

# Stimuli directories
glare_filename = _thisDir + os.sep + 'Stimuli' + '/' + 'glare_square.png';
nonglare_filename = _thisDir + os.sep + 'Stimuli' + '/' + 'nonglare_square.png';
iso_filename = _thisDir + os.sep + 'Stimuli' + '/' + 'iso_square.png';
white_filename = _thisDir + os.sep + 'Stimuli' + '/' + 'white_square.png';
black_filename = _thisDir + os.sep + 'Stimuli' + '/' + 'black_square.png';
distractor_filename = _thisDir + os.sep + 'Stimuli' + '/' + 'red_square.png';

# Setup stimuli 

# Stimuli size
stim_x_size = 7 # in centimeters
stim_y_size = 7 # in centimeters

# Glare stimulus
glare_stimulus = visual.ImageStim(
    win=win,
    name='glare_stimulus',
    image=glare_filename,
    ori=0.0, pos=(0,0), size=(stim_x_size, stim_y_size),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    interpolate=True, depth=0.0)
   
# Nonglare stimulus
nonglare_stimulus = visual.ImageStim(
    win=win,
    name='nonglare_stimulus',
    image=nonglare_filename,
    ori=0.0, pos=(0,0), size=(stim_x_size, stim_y_size),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    interpolate=True, depth=0.0)

# White stimulus
white_stimulus = visual.ImageStim(
    win=win,
    name='white_stimulus',
    image=white_filename,
    ori=0.0, pos=(0,0), size=(stim_x_size, stim_y_size),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    interpolate=True, depth=0.0)

# Black stimulus
black_stimulus = visual.ImageStim(
    win=win,
    name='black_stimulus',
    image=black_filename,
    ori=0.0, pos=(0,0), size=(stim_x_size, stim_y_size),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    interpolate=True, depth=0.0)
    
# Iso stimulus
iso_stimulus = visual.ImageStim(
    win=win,
    name='iso_stimulus',
    image=iso_filename,
    ori=0.0, pos=(0,0), size=(stim_x_size, stim_y_size),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    interpolate=True, depth=0.0)
    
# Distractor plus stimulus
distractor_plus_stimulus = visual.ImageStim(
    win=win,
    name='distractor_plus_stimulus',
    image=distractor_filename,
    ori=0.0, pos=(0,0), size=(stim_x_size, stim_y_size),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    interpolate=True, depth=0.0)
    
# Distractor cross stimulus
distractor_cross_stimulus = visual.ImageStim(
    win=win,
    name='distractor_cross_stimulus',
    image=distractor_filename,
    ori=45, pos=(0,0), size=(stim_x_size, stim_y_size),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    interpolate=True, depth=0.0)
    
# *******************
# *** TASK TIMERS ***
# *******************

timer = core.Clock()

# ************************
# *** INITIATE EYELINK ***
# ************************

# EyeLink Dummy mode? - Set to False if testing with actual system
if info['EyeLink'] == 'y':
    dummy_mode = False
    
elif info['EyeLink'] == 'n':
    dummy_mode = True

# Step 1: Connect to the EyeLink Host PC

# The Host IP address, by default, is "100.1.1.1".
# the "el_tracker" objected created here can be accessed through the Pylink
# Set the Host PC address to "None" (without quotes) to run the script
# in "Dummy Mode"
if dummy_mode:
    el_tracker = pylink.EyeLink(None)
else:
    try:
        el_tracker = pylink.EyeLink("100.1.1.1")
    except RuntimeError as error:
        print('ERROR:', error)
        core.quit()
        sys.exit()
    
# Step 2: Open an EDF data file on the Host PC

# Define edf fileanme
edf_file = edf_fname + ".EDF"

try:
    el_tracker.openDataFile(edf_file)
except RuntimeError as err:
    print('ERROR:', err)
    # close the link if we have one open
    if el_tracker.isConnected():
        el_tracker.close()
    core.quit()
    sys.exit()

# Step 3: Configure the tracker

# Put the tracker in offline mode before we change tracking parameters
el_tracker.setOfflineMode()

# Get the software version:  1-EyeLink I, 2-EyeLink II, 3/4-EyeLink 1000,
# 5-EyeLink 1000 Plus, 6-Portable DUO
if dummy_mode:
    eyelink_ver = 0  # set version to 0, in case running in Dummy mode
else:
    eyelink_ver = 5
    
if not dummy_mode:
    vstr = el_tracker.getTrackerVersionString()
    eyelink_ver = int(vstr.split()[-1].split('.')[0])
    # print out some version info in the shell
    print('Running experiment on %s, version %d' % (vstr, eyelink_ver))

# File and Link data control
# what eye events to save in the EDF file, include everything by default
file_event_flags = 'LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT'
# what eye events to make available over the link, include everything by default
link_event_flags = 'LEFT,RIGHT,FIXATION,SACCADE,BLINK,BUTTON,FIXUPDATE,INPUT'
# what sample data to save in the EDF data file and to make available
# over the link, include the 'HTARGET' flag to save head target sticker
# data for supported eye trackers
if eyelink_ver > 3:
    file_sample_flags = 'LEFT,RIGHT,GAZE,HREF,RAW,AREA,HTARGET,GAZERES,BUTTON,STATUS,INPUT'
    link_sample_flags = 'LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT'
else:
    file_sample_flags = 'LEFT,RIGHT,GAZE,HREF,RAW,AREA,GAZERES,BUTTON,STATUS,INPUT'
    link_sample_flags = 'LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT'
el_tracker.sendCommand("file_event_filter = %s" % file_event_flags)
el_tracker.sendCommand("file_sample_data = %s" % file_sample_flags)
el_tracker.sendCommand("link_event_filter = %s" % link_event_flags)
el_tracker.sendCommand("link_sample_data = %s" % link_sample_flags)

# Set EyeLink sample rate
if eyelink_ver > 2 and not dummy_mode:
    el_tracker.sendCommand("sample_rate 1000")
    
# Choose a calibration type, H3, HV3, HV5, HV13 (HV = horizontal/vertical),
el_tracker.sendCommand("calibration_type = HV9")
# Set a gamepad button to accept calibration/drift check target
# You need a supported gamepad/button box that is connected to the Host PC
el_tracker.sendCommand("button_function 5 'accept_target_fixation'")

# Shrink the spread of the calibration/validation targets
# if the default outermost targets are not all visible in the bore.
# The default <x, y display proportion> is 0.88, 0.83 (88% of the display
# horizontally and 83% vertically)
el_tracker.sendCommand('calibration_area_proportion 0.88 0.83')
el_tracker.sendCommand('validation_area_proportion 0.88 0.83')

# Get the native screen resolution used by PsychoPy
scn_width, scn_height = win.size

# Resolution fix for Mac retina displays
if 'Darwin' in platform.system():
    if use_retina:
        scn_width = int(scn_width/2.0)
        scn_height = int(scn_height/2.0)
        
# Optional: online drift correction.
# See the EyeLink 1000 / EyeLink 1000 Plus User Manual

# Online drift correction to mouse-click position:
# el_tracker.sendCommand('driftcorrect_cr_disable = OFF')
# el_tracker.sendCommand('normal_click_dcorr = ON')

# Online drift correction to a fixed location, e.g., screen center
el_tracker.sendCommand('driftcorrect_cr_disable = OFF')
el_tracker.sendCommand('online_dcorr_refposn %d,%d' % (int(scn_width/2.0),
                                                        int(scn_height/2.0)))
el_tracker.sendCommand('online_dcorr_button = ON')
el_tracker.sendCommand('normal_click_dcorr = OFF')

# Pass the display pixel coordinates (left, top, right, bottom) to the tracker
# see the EyeLink Installation Guide, "Customizing Screen Settings"
el_coords = "screen_pixel_coords = 0 0 %d %d" % (scn_width - 1, scn_height - 1)
el_tracker.sendCommand(el_coords)

# Write a DISPLAY_COORDS message to the EDF file
# Data Viewer needs this piece of info for proper visualization, see Data
# Viewer User Manual, "Protocol for EyeLink Data to Viewer Integration"
dv_coords = "DISPLAY_COORDS  0 0 %d %d" % (scn_width - 1, scn_height - 1)
el_tracker.sendMessage(dv_coords)

# Configure a graphics environment (genv) for tracker calibration
genv = EyeLinkCoreGraphicsPsychoPy(el_tracker, win)
print(genv)  # print out the version number of the CoreGraphics library

# Set background and foreground colors for the calibration target
# in PsychoPy, (-1, -1, -1)=black, (1, 1, 1)=white, (0, 0, 0)=mid-gray
foreground_color = (-1, -1, -1)
background_color = win.color # Use the same background color as the entire study
genv.setCalibrationColors(foreground_color, background_color)

# Set up the calibration target

# Use a picture as the calibration target
genv.setTargetType('circle')
genv.setTargetSize(24)
#genv.setPictureTarget(os.path.join('images', 'fixTarget.bmp')) #CALIBRATION TARGET IMAGE

# Configure the size of the calibration target (in pixels)
# this option applies only to "circle" and "spiral" targets
# genv.setTargetSize(24)

# Beeps to play during calibration, validation and drift correction
# parameters: target, good, error
#     target -- sound to play when target moves
#     good -- sound to play on successful operation
#     error -- sound to play on failure or interruption
# Each parameter could be ''--default sound, 'off'--no sound, or a wav file
genv.setCalibrationSounds('off', 'off', 'off')

# Resolution fix for macOS retina display issues
if use_retina:
    genv.fixMacRetinaDisplay()

# Request Pylink to use the PsychoPy window we opened above for calibration
pylink.openGraphicsEx(genv)

#calibration task constants
#set random seed
rng = np.random.default_rng()

# ************************
# *** CUSTOM FUNCTIONS ***
# ************************

def clear_screen(win):
    """Clear up the PsychoPy window""" 
    
    win.fillColor = genv.getBackgroundColor()
    win.flip()

def terminate_task():
    """ Terminate the task gracefully and retrieve the EDF data file
    file_to_retrieve: The EDF on the Host that we would like to download
    win: the current window used by the experimental script"""
    
    el_tracker = pylink.getEYELINK()
    if el_tracker.isConnected():
        error = el_tracker.isRecording()
        if error == pylink.TRIAL_OK:
            abort_trial()
        el_tracker.setOfflineMode()
        el_tracker.sendCommand('clear_screen 0')
        pylink.msecDelay(500)
        el_tracker.closeDataFile()         
        el_tracker.sendMessage('End EyeLink Recording')
        el_tracker.close()
    win.close()
    core.quit()
    sys.exit()
    
def abort_trial():   
    """Ends recording abruptly"""
    
    el_tracker = pylink.getEYELINK()
    if el_tracker.isRecording():
        pylink.pumpDelay(100)
        el_tracker.stopRecording()  
    clear_screen(win)
    bgcolor_RGB = (116, 116, 116)
    el_tracker.sendMessage('!V CLEAR %d %d %d' % bgcolor_RGB)
    el_tracker.sendMessage('TRIAL_RESULT %d' % pylink.TRIAL_ERROR)
    return pylink.TRIAL_ERROR

def end_experiment() -> None:
    '''End of Experiment'''
    
    # Log
    logging.log(level=logging.EXP,msg='*** END EXPERIMENT ***')
    el_tracker.sendMessage('*** END EXPERIMENT ***')
    
    # Stop recording
    pylink.pumpDelay(100)
    el_tracker.stopRecording()
    terminate_task()
    core.wait(2)
    win.close()
   
def quit_task() -> None:
    '''Quit task based off of button press'''
    
    # Wait for specified keys 
    allKeys = event.getKeys(['p','escape'])
    
    # If key is pressed
    if allKeys != None:
        for thisKey in allKeys:
            if thisKey in ['p', 'escape']:
                end_experiment()
                
def instruction_continue():
    '''Proceed from instructions screen'''
    
    # Wait for key press
    key = event.waitKeys(keyList=['space', 'escape', 'p'])

    # End experiment
    if np.in1d(key,['escape','p']):
        end_experiment()
        
def block_continue():
    '''Proceed from end of block'''
    
    # Wait for key press
    key = event.waitKeys(keyList=['space', 'b', 'escape', 'p', 'l'])

    # End experiment
    if np.in1d(key,['escape','p']):
        end_experiment()
        
    # Share key press
    return(key)
        
def instructions_screens(instruction: str) -> None: 
    '''Function presents all the instructions needed for the task'''
    
    # Setup instructions
    task_instructions = visual.TextStim(win, instruction, color = genv.getForegroundColor(), wrapWidth = scn_width/2)
    clear_screen(win)
    
    # Draw instructions
    task_instructions.draw()
    win.flip()   
    
    # Proceed from instructions
    instruction_continue()

def start_trigger():
    """Wait for task start trigger"""
    
    # Log
    logging.log(level=logging.EXP,msg='Waiting for start trigger')
    el_tracker.sendMessage('Waiting for start trigger')
        
    # On-screen text
    start_instructions = visual.TextStim(win, text='Waiting for start trigger. Please standby...', color = genv.getForegroundColor(), wrapWidth = scn_width/2) 
    start_instructions.draw()
    win.flip()

    # Wait for key press
    key = event.waitKeys(keyList=['5','t','escape', 'p'])

    # If pressed escape quit task
    if np.in1d(key,['escape','p']):
       end_experiment()
       
    # Log
    logging.log(level=logging.EXP,msg='Start trigger received')
    el_tracker.sendMessage('Start trigger received')

def check_keypresses():
    '''Check the key/buttons are received'''
    
    # Check '1' key
    
    # Setup instructions
    task_instructions = visual.TextStim(win, "Please press '1'",color = 'black', pos = [0, 0])
    clear_screen(win)
    
    # Show instructions
    task_instructions.draw()
    win.flip() 
    
    # Only continue if the subject presses 1
    event.waitKeys(keyList = ['1'])
    
    # Check '2' key
    
    # Setup instructions
    task_instructions = visual.TextStim(win, "Please press '2'",color = 'black', pos = [0, 0])
    clear_screen(win)
    
    # Show instructions
    task_instructions.draw()
    win.flip() 
    
    # Only continue if the subject presses 2
    event.waitKeys(keyList = ['2'])
    
    # Check '3' key
    
    # Setup instructions
    task_instructions = visual.TextStim(win, "Please press '3'",color = 'black', pos = [0, 0])
    clear_screen(win)
    
    # Show instructions
    task_instructions.draw()
    win.flip() 
    
    # Only continue if the subject presses 3
    event.waitKeys(keyList = ['3'])
    
def stimulus_loc_positioning(start_stim_x_pos, start_stim_y_pos):
    '''Define two mirrored locations on screen to display the stimulus'''
    
    # Run function
    if 'n' == info['(1) Skip Positioning Phase']:

        # Log
        logging.log(level=logging.EXP,msg='Stimulus Location Positioning Phase')
        el_tracker.sendMessage('Stimulus Location Positioning Phase')
    
        # Nonglare stimuli - Right side 
        nonglare_right = visual.ImageStim(
            win=win,
            name='nonglare_right',
            image=nonglare_filename,
            ori=0.0, pos=(start_stim_x_pos,start_stim_y_pos), size=(stim_x_size, stim_y_size),
            color=[1,1,1], colorSpace='rgb', opacity=1,
            flipHoriz=False, flipVert=False,
            interpolate=True, depth=0.0, units='cm')
    
        # Nonglare stimuli - Left side 
        nonglare_left = visual.ImageStim(
            win=win,
            name='nonglare_left',
            image=nonglare_filename,
            ori=0.0, pos=(-start_stim_x_pos,start_stim_y_pos), size=(stim_x_size, stim_y_size),
            color=[1,1,1], colorSpace='rgb', opacity=1,
            flipHoriz=False, flipVert=False,
            interpolate=True, depth=0.0, units='cm')
        
        # Initial x and y-dimension
        stim_y_pos = start_stim_y_pos
        stim_x_pos = start_stim_x_pos
    
        # Move_on
        # Note: Used to decide when to end positioning stimulus
        move_on = False
    
        # Instructions
        instructions_screens('Now we will check how well you can see images on screen. ' +
                             '\nPlease keep your gaze at the center of the screen \n\nExperimenter:' +
                             ' Press space to continue. \n\n1 = move up\n 2 = move down\n3 = move left\n4 = move right')
    
        # Set auto draw to True for stimuli 
        nonglare_right.setAutoDraw(True)
        nonglare_left.setAutoDraw(True)
        fixation.setAutoDraw(True)
    
        # Keep looping until move on is True
        while not move_on:
    
            # Get all pressed keys
            allKeys = event.getKeys(['1','2','3','4','space','p','escape'])
    
            # If a key was pressed
            if allKeys != None:
    
                # Loop over key presses
                for thisKey in allKeys:
    
                    # End experiment
                    if thisKey in ['p', 'escape']:
    
                        end_experiment()
    
                    # End positioning and record final position
                    elif thisKey in ['space']:
    
                        # Save final stimulus position
                        final_stim_y_pos = stim_y_pos
                        final_stim_x_pos = stim_x_pos
    
                        # Switch move_on case
                        move_on = True
    
                    # Move up
                    elif thisKey in ['1']:
    
                        # Add to y position
                        stim_y_pos = stim_y_pos + 0.25
    
                        # Update stimulus position
                        nonglare_left.pos = (-stim_x_pos, stim_y_pos)
                        nonglare_right.pos = (stim_x_pos, stim_y_pos)
    
                    # Move down
                    elif thisKey in ['2']:
    
                        # Subtract from y position
                        stim_y_pos = stim_y_pos - 0.25
    
                        # Update stimulus position
                        nonglare_left.pos = (-stim_x_pos, stim_y_pos)
                        nonglare_right.pos = (stim_x_pos, stim_y_pos)
                    
                    # Move left
                    elif thisKey in ['3']:
    
                        # Add to y position
                        stim_x_pos = stim_x_pos + 0.25
    
                        # Update stimulus position
                        nonglare_left.pos = (-stim_x_pos, stim_y_pos)
                        nonglare_right.pos = (stim_x_pos, stim_y_pos)
    
                    # Move right
                    elif thisKey in ['4']:
    
                        # Subtract from y position
                        stim_x_pos = stim_x_pos - 0.25
    
                        # Update stimulus position
                        nonglare_left.pos = (-stim_x_pos, stim_y_pos)
                        nonglare_right.pos = (stim_x_pos, stim_y_pos)
    
            # Show screen
            win.update()
    
        # Remove stimuli from screen
        nonglare_right.setAutoDraw(False)
        nonglare_left.setAutoDraw(False)
        fixation.setAutoDraw(False)
        
    # Skipping positioning    
    else:

        # Take the position information from values entered in startup screen
        #final_stim_x_pos = int(info['Final X position'])
        #inal_stim_y_pos = int(info['Final Y position']) 
        final_stim_x_pos = float(info['Final X position'])
        final_stim_y_pos = float(info['Final Y position']) 
        
    # Log
    logging.log(level=logging.EXP,msg='Final x-axis position of stimuli: ' + str(final_stim_x_pos))
    logging.log(level=logging.EXP,msg='Final y-axis position of stimuli: ' + str(final_stim_y_pos))
    el_tracker.sendMessage('Final x-axis position of stimuli: ' + str(final_stim_x_pos))
    el_tracker.sendMessage('Final y-axis position of stimuli: ' + str(final_stim_y_pos))

    # Return location info
    return final_stim_y_pos, final_stim_x_pos       

def glare_main_phase(final_stim_x_pos, final_stim_y_pos):
    ''' Main glare illusion task function'''
    
    # Run function
    if 'n' == info['(2) Skip Main Phase']:
        
        # Log
        logging.log(level=logging.EXP,msg='Starting Glare Illusion Main Phase')
        el_tracker.sendMessage('Starting Glare Illusion Main Phase')
        
        # Log Button Condition
        if button_condition == 1:
            
            # Log
            logging.log(level=logging.EXP,msg='Button Condition: 1')
            el_tracker.sendMessage('Button Condition: 1')
            
        elif button_condition == 2:

            # Log
            logging.log(level=logging.EXP,msg='Button Condition: 2')
            el_tracker.sendMessage('Button Condition: 2')
        
        # Instructions
        instructions_screens("Main Task Phase \n\nPlease fixate on the [+] at the center of the screen at all times."+
        "\nImages will appear but please do not look at the images directly.")

        # Update stimuli position for instructions
        glare_stimulus.pos = (-12,5)
        nonglare_stimulus.pos = (-12,-5)
        iso_stimulus.pos = (12,5)
        white_stimulus.pos = (12,-5)
        distractor_plus_stimulus.pos = (0,5)
        distractor_cross_stimulus.pos = (0,-5)

        # Show stimuli
        glare_stimulus.setAutoDraw(True)
        nonglare_stimulus.setAutoDraw(True)
        iso_stimulus.setAutoDraw(True)
        white_stimulus.setAutoDraw(True)
        distractor_plus_stimulus.setAutoDraw(True)
        distractor_cross_stimulus.setAutoDraw(True)
        fixation.setAutoDraw(True)
        win.update()

        # Instructions continue 
        instruction_continue()
        
        # Remove stimuli
        glare_stimulus.setAutoDraw(False)
        nonglare_stimulus.setAutoDraw(False)
        iso_stimulus.setAutoDraw(False)
        white_stimulus.setAutoDraw(False)
        distractor_plus_stimulus.setAutoDraw(False)
        distractor_cross_stimulus.setAutoDraw(False)
        fixation.setAutoDraw(False)
        win.update()
        
        # Button press instructions
        if button_condition == 1:
        
            # Define instructions
            instruction = "When you see a red plus sign [+] image - Press 1 \nWhen you see a red cross [x] image - Press 2 \n\nPlease select your button/key as soon as you see the red image."
            
            # Setup instructions
            task_instructions = visual.TextStim(win, instruction, color = genv.getForegroundColor(), wrapWidth = scn_width/2)
            clear_screen(win)
            
            # Set image position
            distractor_plus_stimulus.pos = (-8,-9)
            distractor_cross_stimulus.pos = (8,-9)
            
            # Draw instructions
            distractor_plus_stimulus.setAutoDraw(True)
            distractor_cross_stimulus.setAutoDraw(True)
            task_instructions.draw()
            win.flip()   
            
            # Proceed from instructions
            instruction_continue()
            
            distractor_plus_stimulus.setAutoDraw(False)
            distractor_cross_stimulus.setAutoDraw(False)
            win.update()

        elif button_condition == 2:

            # Define instructions
            instruction = "When you see a red cross [x] image - Press 1 /n/nWhen you see a red plus sign [+] image - Press 2 /n/nPlease select your button/key as soon as you see the red image."

            # Setup instructions
            task_instructions = visual.TextStim(win, instruction, color = genv.getForegroundColor(), wrapWidth = scn_width/2)
            clear_screen(win)
            
            # Set image position
            distractor_plus_stimulus.pos = (8,-10)
            distractor_cross_stimulus.pos = (-8,-10)
            
            # Draw instructions
            distractor_plus_stimulus.setAutoDraw(True)
            distractor_cross_stimulus.setAutoDraw(True)
            task_instructions.draw()
            win.flip()   
            
            # Proceed from instructions
            instruction_continue()
            
            distractor_plus_stimulus.setAutoDraw(False)
            distractor_cross_stimulus.setAutoDraw(False)
            win.update()

        # Define initial right/left stimulus locations
        right_loc = (final_stim_x_pos, final_stim_y_pos)
        left_loc = (-final_stim_x_pos, final_stim_y_pos)
        
        # Setup block counter
        block_counter = 1

        # Loop over blocks
        for block in range(max_num_blocks):
            
            # Reset trial and stimulus counter
            trial_counter = 0
            glare_stim_counter = 0
            nonglare_stim_counter = 0
            iso_stim_counter = 0
            white_stim_counter = 0
            distractor_plus_stim_counter = 0
            distractor_cross_stim_counter = 0
            right_distractor_perceived_num = 0
            left_distractor_perceived_num = 0
            
            # Initialize variable 
            right_perception_rate = []
            left_perception_rate = []
            
            # Block start screen
            instructions_screens("Are you ready to start Block "+str(block_counter)+"?")

            # Create stimuli type array (0 = glare; 1 = nonglare; 2 = iso; 3 = white; 4 = distractor plus stimulus; 5 = distractor cross stimulus)
            glare_stim_array = np.array(np.zeros(num_glare_stim))
            nonglare_stim_array = np.array(np.zeros(num_nonglare_stim)+1)
            iso_stimulus_array = np.array(np.zeros(num_iso_stim)+2)
            white_stimulus_array = np.array(np.zeros(num_white_stim)+3)
            distractor_plus_stim_array = np.array(np.zeros(num_distractor_plus_stim)+4)
            distractor_cross_stim_array = np.array(np.zeros(num_distractor_cross_stim)+5)

            # Combine stimuli arrays
            all_stim_array = np.concatenate((glare_stim_array,nonglare_stim_array,iso_stimulus_array,white_stimulus_array,distractor_plus_stim_array,distractor_cross_stim_array))
            
            # Shuffle stimuli array
            random.shuffle(all_stim_array)
                
            # Create stimuli location arrays (0 = left; 1 = right)
            glare_left_loc_array = np.array(np.zeros(int(num_glare_stim/2)))
            glare_right_loc_array = np.array(np.zeros(int(num_glare_stim/2))+1)
            
            nonglare_left_loc_array = np.array(np.zeros(int(num_nonglare_stim/2)))
            nonglare_right_loc_array = np.array(np.zeros(int(num_nonglare_stim/2))+1)
            
            iso_left_loc_array = np.array(np.zeros(int(num_iso_stim/2)))
            iso_right_loc_array = np.array(np.zeros(int(num_iso_stim/2))+1)
            
            white_left_loc_array = np.array(np.zeros(int(num_white_stim/2)))
            white_right_loc_array = np.array(np.zeros(int(num_white_stim/2))+1)
            
            distractor_plus_left_loc_array = np.array(np.zeros(int(num_distractor_plus_stim/2)))
            distractor_plus_right_loc_array = np.array(np.zeros(int(num_distractor_plus_stim/2))+1)
            
            distractor_cross_left_loc_array = np.array(np.zeros(int(num_distractor_cross_stim/2)))
            distractor_cross_right_loc_array = np.array(np.zeros(int(num_distractor_cross_stim/2))+1)
            
            # Combine stimuli location arrays
            all_glare_loc_array = np.concatenate((glare_left_loc_array,glare_right_loc_array))
            all_nonglare_loc_array = np.concatenate((nonglare_left_loc_array,nonglare_right_loc_array))
            all_iso_loc_array = np.concatenate((iso_left_loc_array,iso_right_loc_array))
            all_white_loc_array = np.concatenate((white_left_loc_array,white_right_loc_array))
            all_distractor_plus_loc_array = np.concatenate((distractor_plus_left_loc_array,distractor_plus_right_loc_array))
            all_distractor_cross_loc_array = np.concatenate((distractor_cross_left_loc_array,distractor_cross_right_loc_array))

            # Shuffle stimuli arrays
            random.shuffle(all_glare_loc_array)
            random.shuffle(all_nonglare_loc_array)
            random.shuffle(all_iso_loc_array)
            random.shuffle(all_white_loc_array)
            random.shuffle(all_distractor_plus_loc_array)
            random.shuffle(all_distractor_cross_loc_array)

            # Task start trigger
            start_trigger()
            
            # Log block
            logging.log(level=logging.EXP,msg='Block #' + str(block_counter))
            el_tracker.sendMessage("Block #%d" % (block_counter))
            
            # Log stimulus location
            logging.log(level=logging.EXP,msg='Right Stimulus Location: ' + str(right_loc))
            logging.log(level=logging.EXP,msg='Left Stimulus Location: ' + str(left_loc))

            el_tracker.sendMessage('Right Stimulus Location: ' + str(right_loc))
            el_tracker.sendMessage('Left Stimulus Location: ' + str(left_loc))
        
            # Log the stimulus and location arrays
            logging.log(level=logging.EXP,msg='All Stimuli Type Array (0 = glare; 1 = nonglare; 2 = iso; 3 = white; 4 = distractor): ' + str(all_stim_array))
            logging.log(level=logging.EXP,msg='Glare Stimuli Location Array (0 = left; 1 = right): ' + str(all_glare_loc_array))
            logging.log(level=logging.EXP,msg='Nonglare Stimuli Location Array (0 = left; 1 = right): ' + str(all_nonglare_loc_array))
            logging.log(level=logging.EXP,msg='Iso Stimuli Location Array (0 = left; 1 = right): ' + str(all_iso_loc_array))
            logging.log(level=logging.EXP,msg='White Stimuli Location Array (0 = left; 1 = right): ' + str(all_white_loc_array))
            logging.log(level=logging.EXP,msg='Distractor Plus Stimuli Location Array (0 = left; 1 = right): ' + str(all_distractor_plus_loc_array))
            logging.log(level=logging.EXP,msg='Distractor Cross Stimuli Location Array (0 = left; 1 = right): ' + str(all_distractor_cross_loc_array))
            
            el_tracker.sendMessage('All Stimuli Type Array (0 = glare; 1 = nonglare; 2 = iso; 3 = white; 4 = distractor): ' + str(all_stim_array))
            el_tracker.sendMessage('Glare Stimuli Location Array (0 = left; 1 = right): ' + str(all_glare_loc_array))
            el_tracker.sendMessage('Nonglare Stimuli Location Array (0 = left; 1 = right): ' + str(all_nonglare_loc_array))
            el_tracker.sendMessage('Iso Stimuli Location Array (0 = left; 1 = right): ' + str(all_iso_loc_array))
            el_tracker.sendMessage('White Stimuli Location Array (0 = left; 1 = right): ' + str(all_white_loc_array))
            el_tracker.sendMessage('Distractor Plus Stimuli Location Array (0 = left; 1 = right): ' + str(all_distractor_plus_loc_array))
            el_tracker.sendMessage('Distractor Cross Stimuli Location Array (0 = left; 1 = right): ' + str(all_distractor_cross_loc_array))

            # Track time taken to complete block
            block_start = time.time()
    
            # Loop over trials/stimuli
            for current_stim in all_stim_array:
                
                # Count the number of trials
                trial_counter = trial_counter+1
                
                # Select the pre and post stimulus durations
                trial_pre_stim_time = random.randint(ISI_min_duration_sec,ISI_max_duration_sec)
                trial_post_stim_time = random.randint(ISI_min_duration_sec,ISI_max_duration_sec)
                
                # Log
                logging.log(level=logging.EXP,msg='Starting Trial #'+str(trial_counter))
                logging.log(level=logging.EXP,msg='Trial Pre-Stimulus Time: '+str(trial_pre_stim_time))
                logging.log(level=logging.EXP,msg='Trial Post-Stimulus Time: '+str(trial_post_stim_time))
                
                el_tracker.sendMessage("Starting Trial " + str(trial_counter))
                el_tracker.sendMessage("Trial Pre-Stimulus Time: " + str(trial_pre_stim_time))
                el_tracker.sendMessage("Trial Post-Stimulus Time: " + str(trial_post_stim_time))
                
                # Quit task
                quit_task()
                
                # Start task trial
                
                # Setup fixation
                fixation.setAutoDraw(True)
                
                # Log
                logging.log(level=logging.EXP,msg='Pre-stimulus interval')
                el_tracker.sendMessage('Pre-stimulus interval')
                
                # Reset timer
                timer.reset()
                
                # Wait pre-stimulus ISI
                while timer.getTime() < trial_pre_stim_time:
                    win.update()
                
                # If glare stimulus
                if current_stim == 0:
                    
                    # Set right position
                    if all_glare_loc_array[glare_stim_counter] == 1:
                        glare_stimulus.pos = right_loc
                          
                    # Set left position
                    elif all_glare_loc_array[glare_stim_counter] == 0:
                        glare_stimulus.pos = left_loc
                    
                    # Add to stimulus counter
                    glare_stim_counter = glare_stim_counter+1
                
                    # Show stimulus
                    glare_stimulus.setAutoDraw(True)
                    
                    # Log
                    logging.log(level=logging.EXP,msg='Draw Glare Stimulus')
                    el_tracker.sendMessage('Draw Glare Stimulus')
        
                # If nonglare stimulus
                elif current_stim == 1:
                    
                    # Set right position
                    if all_nonglare_loc_array[nonglare_stim_counter] == 1:
                        nonglare_stimulus.pos = right_loc
                        
                    # Set left position
                    elif all_nonglare_loc_array[nonglare_stim_counter] == 0:
                        nonglare_stimulus.pos = left_loc
                        
                    # Add to stimulus counter
                    nonglare_stim_counter = nonglare_stim_counter+1
                
                    # Show stimulus
                    nonglare_stimulus.setAutoDraw(True)
                
                    # Log
                    logging.log(level=logging.EXP,msg='Draw Nonglare Stimulus')
                    el_tracker.sendMessage('Draw Nonglare Stimulus')
                    
                # If iso stimulus
                elif current_stim == 2:
                    
                    # Set right position
                    if all_iso_loc_array[iso_stim_counter] == 1:
                        iso_stimulus.pos = right_loc
                          
                    # Set left position
                    elif all_iso_loc_array[iso_stim_counter] == 0:
                        iso_stimulus.pos = left_loc
                        
                    # Add to stimulus counter
                    iso_stim_counter = iso_stim_counter+1
                
                    # Show stimulus
                    iso_stimulus.setAutoDraw(True)
                    
                    # Log
                    logging.log(level=logging.EXP,msg='Draw Iso Stimulus')
                    el_tracker.sendMessage('Draw Iso Stimulus')
        
                # If white stimulus
                elif current_stim == 3:
                    
                    # Set right position
                    if all_white_loc_array[white_stim_counter] == 1:
                        white_stimulus.pos = right_loc
                        
                    # Set left position
                    elif all_white_loc_array[white_stim_counter] == 0:
                        white_stimulus.pos = left_loc
                        
                    # Add to stimulus counter
                    white_stim_counter = white_stim_counter+1
                
                    # Show stimulus
                    white_stimulus.setAutoDraw(True)
                
                    # Log
                    logging.log(level=logging.EXP,msg='Draw White Stimulus')
                    el_tracker.sendMessage('Draw White Stimulus')
        
                # If distractor plus stimulus
                elif current_stim == 4:
                    
                    # Set distractor perception variable
                    not_perceived = 1
                    
                    # Set right position
                    if all_distractor_plus_loc_array[distractor_plus_stim_counter] == 1:
                        distractor_plus_stimulus.pos = right_loc
                        
                    # Set left position
                    elif all_distractor_plus_loc_array[distractor_plus_stim_counter] == 0:
                        distractor_plus_stimulus.pos = left_loc
                        
                    # Add to stimulus counter
                    distractor_plus_stim_counter = distractor_plus_stim_counter+1
                
                    # Show stimulus
                    distractor_plus_stimulus.setAutoDraw(True)
                        
                    # Log
                    logging.log(level=logging.EXP,msg='Draw Distractor Plus Stimulus')
                    el_tracker.sendMessage('Draw Distractor Plus Stimulus')
                
                # If distractor cross stimulus
                elif current_stim == 5:
                    
                    # Set distractor perception variable
                    not_perceived = 1
                    
                    # Set right position
                    if all_distractor_cross_loc_array[distractor_cross_stim_counter] == 1:
                        distractor_cross_stimulus.pos = right_loc
                        
                    # Set left position
                    elif all_distractor_cross_loc_array[distractor_cross_stim_counter] == 0:
                        distractor_cross_stimulus.pos = left_loc
                        
                    # Add to stimulus counter
                    distractor_cross_stim_counter = distractor_cross_stim_counter+1
                
                    # Show stimulus
                    distractor_cross_stimulus.setAutoDraw(True)
                        
                    # Log
                    logging.log(level=logging.EXP,msg='Draw Distractor Cross Stimulus')
                    el_tracker.sendMessage('Draw Distractor Cross Stimulus')
                
                # Clear the key press buffer
                event.clearEvents()
               
                # Reset timer
                timer.reset()
                
                # Display for stimulus for stimulus duration
                while timer.getTime() < stimulus_duration:
                    
                    # Receive specified keys
                    allKeys = event.getKeys(['1', '2', 'p','escape']) 
                        
                    # Loop over key presses 
                    for thisKey in allKeys:
                            
                        # Distractor stimulus keys
                        if thisKey == '1' or thisKey == '2':
                                                      
                           # If a distractor stimulus was shown this trial                     
                           if current_stim == 4 and not_perceived:
                                
                               # Log 
                               logging.log(level=logging.EXP,msg='Perceived Distractor')
                               el_tracker.sendMessage('Perceived Distractor')   
                           
                               # Distractor was shown on the right side 
                               if all_distractor_plus_loc_array[distractor_plus_stim_counter-1] == 1:
                            
                                   # Add 1 to distractor response array
                                   right_distractor_perceived_num = right_distractor_perceived_num+1
                            
                               # Distractor was shown on the left side
                               elif all_distractor_plus_loc_array[distractor_plus_stim_counter-1] == 0:
                                    
                                   # Add 1 to distractor response array
                                   left_distractor_perceived_num = left_distractor_perceived_num+1
                                   
                               # Flip not_perceived
                               not_perceived = 0
                               
                           elif current_stim == 5 and not_perceived:

                               # Log 
                               logging.log(level=logging.EXP,msg='Perceived Distractor')
                               el_tracker.sendMessage('Perceived Distractor')   
                           
                               # Distractor was shown on the right side 
                               if all_distractor_cross_loc_array[distractor_cross_stim_counter-1] == 1:
                            
                                   # Add 1 to distractor response array
                                   right_distractor_perceived_num = right_distractor_perceived_num+1
                            
                               # Distractor was shown on the left side
                               elif all_distractor_cross_loc_array[distractor_cross_stim_counter-1] == 0:
                                    
                                   # Add 1 to distractor response array
                                   left_distractor_perceived_num = left_distractor_perceived_num+1
                                   
                               # Flip not_perceived
                               not_perceived = 0
                        
                        # Exit task button press
                        elif np.in1d(thisKey,['escape','p']):
                            core.quit() 
                    
                    # Update window
                    win.update()
                
                # Turn off glare stimulus
                if current_stim == 0:
                    glare_stimulus.setAutoDraw(False)
                
                # Turn off nonglare stimulus
                elif current_stim == 1:
                    nonglare_stimulus.setAutoDraw(False)
                
                # Turn off iso circle stimulus
                elif current_stim == 2:
                    iso_stimulus.setAutoDraw(False)

                # Turn off white circle stimulus
                elif current_stim == 3:
                    white_stimulus.setAutoDraw(False)

                # Turn off distractor plus stimulus
                elif current_stim == 4:
                    distractor_plus_stimulus.setAutoDraw(False)
                
                # Turn off distractor cross stimulus
                elif current_stim == 5:
                    distractor_cross_stimulus.setAutoDraw(False)
                
                # Remove stimulus from screen
                win.update()
                
                # Log
                logging.log(level=logging.EXP,msg='Post-stimulus interval')
                el_tracker.sendMessage('Post-stimulus interval')
                
                # Reset timers
                timer.reset()
                
                # Wait post-stimulus time
                while timer.getTime() < trial_post_stim_time:
                    
                    # Update window
                    win.update()
            
            # End of block        
            
            # Update screen
            fixation.setAutoDraw(False)
            clear_screen(win)
                        
            # End block time
            block_end = time.time()
    
            # Calculate distractor stimulus perception rate
            left_perception_rate = left_distractor_perceived_num/(num_distractor_plus_stim/2+num_distractor_cross_stim/2)
            right_perception_rate = right_distractor_perceived_num/(num_distractor_plus_stim/2+num_distractor_cross_stim/2)
    
            # Log
            logging.log(level=logging.EXP,msg='Block duration: ' + str(block_end-block_start))
            logging.log(level=logging.EXP,msg='Right distractor perception rate: '+str(right_perception_rate))
            logging.log(level=logging.EXP,msg='Left distractor perception rate: '+str(left_perception_rate))
            
            el_tracker.sendMessage("Block duration: " +str(block_end-block_start))
            el_tracker.sendMessage("Right distractor perception rate: " +str(right_perception_rate))
            el_tracker.sendMessage("Left distractor perception rate: " +str(left_perception_rate))

            # Block break screen
            block_break = visual.TextStim(win, text="Great job! Take a break.\n\nYou completed Block "+str(block_counter)+
                                          ".\n[<<- "+str(left_perception_rate)+" ->> "+str(right_perception_rate)+
                                          "]\n\nExperimenter:\nspace = continue to next block \nb = break to new task phase \nl = stim positioning", color='black')
            
            # Show break screen
            block_break.draw()
            win.flip()
            
            # Continue or quit
            key = block_continue()
            
            # Break from current block
            if np.in1d(key, ['b']):
                
                # Return final stimuli locations
                return final_stim_x_pos, final_stim_y_pos
            
                #break
            
            # Redo repositioning of stimulus
            # Note: This might be necessary if the perception rate for the distractor stimulus shows suboptimal perception
            elif np.in1d(key, ['l']):
                
                # Target location positioning 
                final_stim_y_pos, final_stim_x_pos = stimulus_loc_positioning(final_stim_x_pos, final_stim_y_pos)
                
                # Define right/left locations
                right_loc = (final_stim_x_pos, final_stim_y_pos)
                left_loc = (-final_stim_x_pos, final_stim_y_pos)
                
            # Add to block counter
            block_counter = block_counter + 1
            
def brightness_perception():
    '''Test the subjective brightness of each stimulus'''
    
    # Run function
    if 'n' == info['(3) Skip Brightness Phase']: 
    
        # Log
        logging.log(level=logging.EXP,msg='Starting Glare Illusion Perception Phase')
        el_tracker.sendMessage('Starting Glare Illusion Perception Phase')
        
        # Instructions
        instructions_screens("Brightness Perception Phase \n\nInstructions: You will see two images at a time. \nPlease judge if the center " + 
                              "is brigther in one image or if both images have the same center brightness. \n\nPlease report your judgment with a key response. " + 
                              "\n\nLeft image is brighter = 1\n Right image is brighter = 2\n Same brightness = 3")

        # Update stimuli position for instructions
        glare_stimulus.pos = (-12,0)
        nonglare_stimulus.pos = (0,0)
        iso_stimulus.pos = (12,0)
        
        # Show stimuli
        glare_stimulus.setAutoDraw(True)
        nonglare_stimulus.setAutoDraw(True)
        iso_stimulus.setAutoDraw(True)
        win.update()

        # Instructions continue 
        instruction_continue()
        
        # Remove stimuli
        glare_stimulus.setAutoDraw(False)
        nonglare_stimulus.setAutoDraw(False)
        iso_stimulus.setAutoDraw(False)
        win.update()

        # Define right/left locations
        right_loc = (12, 0)
        left_loc = (-12, 0)
    
        # Number of contrast types
        num_glare_vs_nonglare = 10
        num_glare_vs_iso = 10
        num_nonglare_vs_iso = 10
    
        # Block counter reset
        block_counter = 1
            
        # Loop over blocks
        for block in range(max_num_blocks):
                
            # Reset trial and stimulus counter
            trial_counter = 0
            glare_vs_nonglare_counter = 0
            glare_vs_iso_counter = 0
            nonglare_vs_iso_counter = 0
            
            # Initialize variables 
            brightness_answers = []
            
            # Block start screen
            instructions_screens("Are you ready to start Block "+str(block_counter)+"?")

            # Create stimuli type array (0 = glare vs nonglare; 1 = glare vs iso; 2 = nonglare vs iso)
            glare_vs_nonglare_array = np.array(np.zeros(num_glare_vs_nonglare))
            glare_vs_iso_array = np.array(np.zeros(num_glare_vs_iso)+1)
            nonglare_vs_iso_array = np.array(np.zeros(num_nonglare_vs_iso)+2)
             
            # Combine stimuli arrays
            all_stim_array = np.concatenate((glare_vs_nonglare_array,glare_vs_iso_array,nonglare_vs_iso_array))
            
            # Shuffle stimuli array
            random.shuffle(all_stim_array)
                
            # Create stimuli location arrays (0 = left; 1 = right)
            glare_vs_nonglare_left_loc_array = np.array(np.zeros(int(num_glare_vs_nonglare/2)))
            glare_vs_nonglare_right_loc_array = np.array(np.zeros(int(num_glare_vs_nonglare/2))+1)
            
            glare_vs_iso_left_loc_array = np.array(np.zeros(int(num_glare_vs_iso/2)))
            glare_vs_iso_right_loc_array = np.array(np.zeros(int(num_glare_vs_iso/2))+1)
            
            nonglare_vs_iso_left_loc_array = np.array(np.zeros(int(num_nonglare_vs_iso/2)))
            nonglare_vs_iso_right_loc_array = np.array(np.zeros(int(num_nonglare_vs_iso/2))+1)
            
            # Combine stimuli location arrays
            all_glare_vs_nonglare_loc_array = np.concatenate((glare_vs_nonglare_left_loc_array,glare_vs_nonglare_right_loc_array))
            all_glare_vs_iso_loc_array = np.concatenate((glare_vs_iso_left_loc_array,glare_vs_iso_right_loc_array))
            all_nonglare_vs_iso_loc_array = np.concatenate((nonglare_vs_iso_left_loc_array,nonglare_vs_iso_right_loc_array))

            # Shuffle stimuli arrays
            random.shuffle(all_glare_vs_nonglare_loc_array)
            random.shuffle(all_glare_vs_iso_loc_array)
            random.shuffle(all_nonglare_vs_iso_loc_array)

            # Task start trigger
            start_trigger()
            
            # Log
            logging.log(level=logging.EXP,msg='Block #' + str(block_counter))
            el_tracker.sendMessage("Block #%d" % (block_counter))
        
            # Log the stimulus and location arrays
            logging.log(level=logging.EXP,msg='All Stimuli Type Array (0 = glare; 1 = nonglare; 2 = iso; 3 = white; 4 = distractor): ' + str(all_stim_array))
            logging.log(level=logging.EXP,msg='Glare Stimuli Location Array (0 = left; 1 = right): ' + str(all_glare_vs_nonglare_loc_array))
            logging.log(level=logging.EXP,msg='Nonglare Stimuli Location Array (0 = left; 1 = right): ' + str(all_glare_vs_iso_loc_array))
            logging.log(level=logging.EXP,msg='Iso Stimuli Location Array (0 = left; 1 = right): ' + str(all_nonglare_vs_iso_loc_array))

            el_tracker.sendMessage('All Stimuli Type Array (0 = glare; 1 = nonglare; 2 = iso; 3 = white; 4 = distractor): ' + str(all_stim_array))
            el_tracker.sendMessage('Glare Stimuli Location Array (0 = left; 1 = right): ' + str(all_glare_vs_nonglare_loc_array))
            el_tracker.sendMessage('Nonglare Stimuli Location Array (0 = left; 1 = right): ' + str(all_glare_vs_iso_loc_array))
            el_tracker.sendMessage('Iso Stimuli Location Array (0 = left; 1 = right): ' + str(all_nonglare_vs_iso_loc_array))
       
            # Track time taken to complete block
            block_start = time.time()
    
            # Loop over trials/stimuli
            for current_stim in all_stim_array:
                
                # Count the number of trials
                trial_counter = trial_counter+1
                
                # Log
                logging.log(level=logging.EXP,msg='Starting Trial #'+str(trial_counter))
                el_tracker.sendMessage("Starting Trial " + str(trial_counter))
                
                # Quit task
                quit_task()
                
                # Start task trial
                
                # Reset timer
                timer.reset()
                
                # Wait pre-stimulus ISI
                while timer.getTime() < 2:
                    win.update()
                
                # If glare vs nonglare
                if current_stim == 0:
                    
                    # Set right position
                    if all_glare_vs_nonglare_loc_array[glare_vs_nonglare_counter] == 1:
                        glare_stimulus.pos = right_loc
                        nonglare_stimulus.pos = left_loc
                          
                    # Set left position
                    elif all_glare_vs_nonglare_loc_array[glare_vs_nonglare_counter] == 0:
                        glare_stimulus.pos = left_loc
                        nonglare_stimulus.pos = right_loc
                    
                    # Add to stimulus counter
                    glare_vs_nonglare_counter = glare_vs_nonglare_counter+1
                
                    # Show stimulus
                    glare_stimulus.setAutoDraw(True)
                    nonglare_stimulus.setAutoDraw(True)
                    
                    # Log
                    logging.log(level=logging.EXP,msg='Draw Glare vs Nonglare Stimulus')
                    el_tracker.sendMessage('Draw Glare vs Nonglare Stimulus')
                
                # If glare vs iso
                elif current_stim == 1:
                    
                    # Set right position
                    if all_glare_vs_iso_loc_array[glare_vs_iso_counter] == 1:
                        glare_stimulus.pos = right_loc
                        iso_stimulus.pos = left_loc
                          
                    # Set left position
                    elif all_glare_vs_iso_loc_array[glare_vs_iso_counter] == 0:
                        glare_stimulus.pos = left_loc
                        iso_stimulus.pos = right_loc
                    
                    # Add to stimulus counter
                    glare_vs_iso_counter = glare_vs_iso_counter+1
                
                    # Show stimulus
                    glare_stimulus.setAutoDraw(True)
                    iso_stimulus.setAutoDraw(True)
                    
                    # Log
                    logging.log(level=logging.EXP,msg='Draw Glare vs Iso Stimulus')
                    el_tracker.sendMessage('Draw Glare vs Iso Stimulus')
                    
                # If nonglare vs iso    
                elif current_stim == 2:
                    
                    # Set right position
                    if all_nonglare_vs_iso_loc_array[nonglare_vs_iso_counter] == 1:
                        iso_stimulus.pos = right_loc
                        nonglare_stimulus.pos = left_loc
                          
                    # Set left position
                    elif all_nonglare_vs_iso_loc_array[nonglare_vs_iso_counter] == 0:
                        iso_stimulus.pos = left_loc
                        nonglare_stimulus.pos = right_loc
                    
                    # Add to stimulus counter
                    nonglare_vs_iso_counter = nonglare_vs_iso_counter+1
                
                    # Show stimulus
                    iso_stimulus.setAutoDraw(True)
                    nonglare_stimulus.setAutoDraw(True)
                    
                    # Log
                    logging.log(level=logging.EXP,msg='Draw Nonglare vs Iso Stimulus')
                    el_tracker.sendMessage('Draw Nonglare vs Iso Stimulus')
                        
                # On-screen text
                subjective_instructions = visual.TextStim(win, text='Which image is brighter at its center?\n\n 1 = Left image\n 2 = Right image\n 3 = Same brightness', color = genv.getForegroundColor(), wrapWidth = scn_width/2) 
                subjective_instructions.draw()
                win.flip()
    
                # Wait for key press
                brightness_key = event.waitKeys(keyList=['1','2','3','escape', 'p'])
                
                # Quit task
                if np.in1d(brightness_key,['escape','p']):
                    core.quit() 
    
                # Store answers
                else: 
                
                    brightness_answers = np.append(brightness_answers, brightness_key)
        
                # Update window
                win.update()
            
                # Turn off stimuli
                if current_stim == 0:
                    glare_stimulus.setAutoDraw(False)
                    nonglare_stimulus.setAutoDraw(False)
    
                elif current_stim == 1:
                    iso_stimulus.setAutoDraw(False)
                    glare_stimulus.setAutoDraw(False)
                
                elif current_stim == 2:
                    iso_stimulus.setAutoDraw(False)
                    nonglare_stimulus.setAutoDraw(False)
                
                # Update window
                win.update()
                
            # End of Block
            
            # End block time
            block_end = time.time()
    
            # Log
            logging.log(level=logging.EXP,msg='Block Perception Answers: ' + str(brightness_answers))
            logging.log(level=logging.EXP,msg='Block '+str(block_counter)+' Duration: ' + str(block_end-block_start))
            
            el_tracker.sendMessage('Block Perception Answers: ' + str(brightness_answers))
            el_tracker.sendMessage('Block '+str(block_counter)+' Duration: ' + str(block_end-block_start))

            # Block Break Screen
            block_break = visual.TextStim(win, text="Great job! Take a break.\n\nYou completed Block "+str(block_counter)+
                                          ". \n\nExperimenter: \nspace = continue to next block \nb = break to next task phase", color='black')
    
            # Show break screen
            block_break.draw()
            win.flip()
            
            # Continue or quit
            key = block_continue()
            
            # Break from current block
            if np.in1d(key, ['b']):
                
                break
            
            # Add to block counter
            block_counter = block_counter + 1

def afterimage_perception(final_stim_x_pos, final_stim_y_pos):
    '''Afterimage perception task phase'''
    
    # Run function
    if 'n' == info['(4) Skip Afterimage Phase']: 
        
        # Set screen color to white
        win.color = [1,1,1]
        
        # Define right/left stimulus locations
        right_loc = (final_stim_x_pos, final_stim_y_pos)
        left_loc = (-final_stim_x_pos, final_stim_y_pos)
    
        # Number of contrast types
        num_stimuli = 6
        num_blanks = 2
    
        # Log
        logging.log(level=logging.EXP,msg='Starting Afterimage Perception Phase')
        el_tracker.sendMessage('Starting Afterimage Perception Phase')
        
        # Task instructions
        
        # Instructions
        instructions_screens("Afterimage Perception Phase \n\nInstructions: You might see images and afterimages. " +
                             "Please report the start and stop of an afterimage you see with a key press.")

        # Update stimuli position for instructions
        black_stimulus.pos = (0,0)
        
        # Setup fixation
        fixation.setAutoDraw(True)
        
        # Move on 
        move_on = False
        
        # Continue showing examples until move_on is triggered
        while not move_on:
            
            # Reset timer
            timer.reset()
            
            # Wait pre-stimulus ISI
            while timer.getTime() < 1:
                
                win.update()
            
            # Show stimuli
            black_stimulus.setAutoDraw(True)
            
            # Reset timer
            timer.reset()
            
            # Wait stimulus presentation
            while timer.getTime() < 4:
                
                # Receive specified keys
                allKeys = event.getKeys(['space', 'p','escape']) 
                    
                # Loop over key presses 
                for thisKey in allKeys:
                        
                    # Perceived afterimage keys
                    if thisKey == 'space':
                                                  
                        move_on = True
                        
                    # Exit task button press
                    elif np.in1d(thisKey,['escape','p']):
                        core.quit() 
                        
                win.update()
                
            # Show stimuli
            black_stimulus.setAutoDraw(False)
            
            # Reset timer
            timer.reset()
            
            # Wait post-stimulus ISI
            while timer.getTime() < 8:
                
                # Receive specified keys
                allKeys = event.getKeys(['space', 'p','escape']) 
                    
                # Loop over key presses 
                for thisKey in allKeys:
                        
                    # Perceived afterimage keys
                    if thisKey == 'space':
                                                  
                        move_on = True
                        
                    # Exit task button press
                    elif np.in1d(thisKey,['escape','p']):
                        core.quit() 
                        
                win.update()
            
        # Remove stimuli
        fixation.setAutoDraw(False)
        black_stimulus.setAutoDraw(False)
        win.update()

        # Start Task
    
        # Block counter reset
        block_counter = 1
            
        # Loop over blocks
        for block in range(max_num_blocks):
                
            # Reset trial and stimulus counter
            trial_counter = 0
            stimuli_counter = 0
            blanks_counter = 0
            
            # Block start screen
            instructions_screens("Are you ready to start Block "+str(block_counter)+"?")

            # Create stimuli type array (0 = stimuli; 1 = blanks)
            stimuli_array = np.array(np.zeros(num_stimuli))
            blank_array = np.array(np.zeros(num_blanks)+1)
             
            # Combine stimuli arrays
            all_stim_array = np.concatenate((stimuli_array,blank_array))
            
            # Shuffle stimuli array
            random.shuffle(all_stim_array)
                
            # Create stimuli location arrays (0 = left; 1 = right)
            stimuli_left_loc_array = np.array(np.zeros(int(num_stimuli/2)))
            stimuli_right_loc_array = np.array(np.zeros(int(num_stimuli/2))+1)
            
            blanks_left_loc_array = np.array(np.zeros(int(num_blanks/2)))
            blanks_right_loc_array = np.array(np.zeros(int(num_blanks/2))+1)

            # Combine stimuli location arrays
            all_stimuli_loc_array = np.concatenate((stimuli_left_loc_array,stimuli_right_loc_array))
            all_blanks_loc_array = np.concatenate((blanks_left_loc_array,blanks_right_loc_array))
      
            # Shuffle stimuli arrays
            random.shuffle(all_stimuli_loc_array)
            random.shuffle(all_blanks_loc_array)

            # Task start trigger
            start_trigger()
            
            # Log
            logging.log(level=logging.EXP,msg='Block #' + str(block_counter))
            el_tracker.sendMessage("Block #%d" % (block_counter))
        
            # Log the stimulus and location arrays
            logging.log(level=logging.EXP,msg='All Stimuli Type Array (0 = stimuli; 1 = blank): ' + str(all_stim_array))
            logging.log(level=logging.EXP,msg='Stimuli Location Array (0 = left; 1 = right): ' + str(all_stimuli_loc_array))
            logging.log(level=logging.EXP,msg='Blank Stimuli Location Array (0 = left; 1 = right): ' + str(all_blanks_loc_array))

            el_tracker.sendMessage('All Stimuli Type Array (0 = stimuli; 1 = blank): ' + str(all_stim_array))
            el_tracker.sendMessage('Stimuli Location Array (0 = left; 1 = right): ' + str(all_stimuli_loc_array))
            el_tracker.sendMessage('Blank Stimuli Location Array (0 = left; 1 = right): ' + str(all_blanks_loc_array))
       
            # Track time taken to complete block
            block_start = time.time()
    
            # Loop over trials/stimuli
            for current_stim in all_stim_array:
                
                # Count the number of trials
                trial_counter = trial_counter+1
                
                # Log
                logging.log(level=logging.EXP,msg='Starting Trial #'+str(trial_counter))
                el_tracker.sendMessage("Starting Trial " + str(trial_counter))
                
                # Quit task
                quit_task()
                
                # Start task trial
                
                # Setup fixation
                fixation.setAutoDraw(True)
                
                # Reset timer
                timer.reset()
                
                # Wait pre-stimulus ISI
                while timer.getTime() < 2:
                    win.update()
                
                # If stimuli
                if current_stim == 0:
                    
                    # Set right position
                    if all_stimuli_loc_array[stimuli_counter] == 1:
                        black_stimulus.pos = right_loc
                          
                    # Set left position
                    elif all_stimuli_loc_array[stimuli_counter] == 0:
                        black_stimulus.pos = left_loc
                    
                    # Add to stimulus counter
                    stimuli_counter = stimuli_counter+1
                
                    # Show stimulus
                    black_stimulus.setAutoDraw(True)
                    
                    # Log
                    logging.log(level=logging.EXP,msg='Draw Stimulus')
                    el_tracker.sendMessage('Draw Stimulus')
                
                # If blank
                elif current_stim == 1:
                             
                    # Add to stimulus counter
                    blanks_counter = blanks_counter+1
                    
                    # Log
                    logging.log(level=logging.EXP,msg='Draw Blank Stimulus')
                    el_tracker.sendMessage('Draw Blank Stimulus')
           
                # Reset timer
                timer.reset()
                
                # Display stimulus
                while timer.getTime() < 4:
                    
                    # Receive specified keys
                    allKeys = event.getKeys(['p','escape']) 
                        
                    # Loop over key presses 
                    for thisKey in allKeys:
 
                        # Exit task button press
                        if np.in1d(thisKey,['escape','p']):
                            core.quit() 
                    
                    # Update window
                    win.update()
            
                # Turn off stimuli
                if current_stim == 0:
                    black_stimulus.setAutoDraw(False)
                    
                # Reset timer
                timer.reset()
                
                # Post inducer interval
                while timer.getTime() < 10:
                    
                    # Receive specified keys
                    allKeys = event.getKeys(['1', '2', 'p','escape']) 
                        
                    # Loop over key presses 
                    for thisKey in allKeys:
                            
                        # Perceived afterimage onset
                        if thisKey == '1':
                                                      
                           # If stimulus was shown                    
                           if current_stim == 0:
                                
                               # Log 
                               logging.log(level=logging.EXP,msg='True positive afterimage onset')
                               el_tracker.sendMessage('True positive afterimage onset')   
                           
                           # If blank trial
                           elif current_stim == 1:
                                
                               # Log 
                               logging.log(level=logging.EXP,msg='False positive afterimage onset')
                               el_tracker.sendMessage('False positive afterimage onset')   
                              
                        # Perceived afterimage offset        
                        elif thisKey == '2':
                            
                            # If stimulus was shown                    
                            if current_stim == 0:
                                 
                                # Log 
                                logging.log(level=logging.EXP,msg='True positive afterimage offset')
                                el_tracker.sendMessage('True positive afterimage offset')   
                            
                            # If blank trial
                            elif current_stim == 1:
                                 
                                # Log 
                                logging.log(level=logging.EXP,msg='False positive afterimage offset')
                                el_tracker.sendMessage('False positive afterimage offset')   
                            
                        # Exit task button press
                        elif np.in1d(thisKey,['escape','p']):
                            core.quit() 
                    
                    # Update window
                    win.update()
                
            # End of Block
            
            # Turn off fixation
            fixation.setAutoDraw(False)
            
            # End block time
            block_end = time.time()
    
            # Log
            logging.log(level=logging.EXP,msg='Block '+str(block_counter)+' duration: ' + str(block_end-block_start))
            el_tracker.sendMessage('Block '+str(block_counter)+' duration: ' + str(block_end-block_start))   

            # Block Break Screen
            block_break = visual.TextStim(win, text="Great job! Take a break.\n\nYou completed Block "+str(block_counter)+". \n\nExperimenter: \nspace = continue to next block \nb = end experiment", color='black')
    
            # Show break screen
            block_break.draw()
            win.flip()
            
            # Continue or quit
            key = block_continue()
            
            # Break from current block
            if np.in1d(key, ['b']):
                
                break
            
            # Add to block counter
            block_counter = block_counter + 1

# *********************
# *** MAIN FUNCTION ***
# *********************
    
def main():

    # *********************
    # *** Setup EyeLink ***
    # *********************
    
    #rel = RealEyeLink() #sets up real eyelink object

    # If running EyeLink
    if not dummy_mode:
        task_msg = 'Press O to calibrate tracker'
        instructions_screens(task_msg)
    
    if not dummy_mode:
        try:
            el_tracker.doTrackerSetup()
        except RuntimeError as err:
            print('ERROR:', err)
            el_tracker.exitCalibration()
            
    el_tracker.setOfflineMode()
    
    try:
        el_tracker.startRecording(1, 1, 1, 1)
    except RuntimeError as error:
        print("ERROR:", error)
        terminate_task()

    eye_used = el_tracker.eyeAvailable()
    
    if eye_used == 1:
        el_tracker.sendMessage("EYE_USED 1 RIGHT")
    elif eye_used == 0 or eye_used == 2:
        el_tracker.sendMessage("EYE_USED 0 LEFT")
        eye_used = 0
    else:
        print("Error in getting the eye information!")
    pylink.pumpDelay(100)
    
    # *******************************
    # *** Beginning of Experiment ***
    # *******************************
    
    # Log
    logging.log(level=logging.EXP,msg='Start Experiment')
    
    # Instruction screen
    instructions_screens("Experiment is setup! Let's get started!")
    
    # *******************************
    # ********* Test Keys ***********
    # ******************************* 
    
    # Log
    logging.log(level=logging.EXP,msg='Check keypresses')
    
    # Instruction screen
    instructions_screens("Let's check if the keypresses are working...")
    
    # Check keys
    check_keypresses()
    
    # Instruction screen 
    instructions_screens("The keys are working! Please keep your hand in approximately its current position.")
   
    # *************************************
    # *** Stimulus Location Positioning ***
    # *************************************
    
    # Note: Running as a separate task event to allow for skipping directly to certain task phases
    final_stim_y_pos, final_stim_x_pos = stimulus_loc_positioning(start_stim_x_pos, start_stim_y_pos)
    
    # *****************************
    # *** Glare Main Task Phase ***
    # *****************************
   
    glare_main_phase(final_stim_x_pos, final_stim_y_pos)

    # ******************************
    # *** Glare Brightness Phase ***
    # ******************************
    
    brightness_perception()
    
    # ************************
    # *** Afterimage Phase ***
    # ************************
    
    afterimage_perception(final_stim_x_pos, final_stim_y_pos)

    # *******************************
    # ***** End of Experiment *******
    # *******************************
    
    end_experiment()
            
if __name__ == "__main__":
    main()