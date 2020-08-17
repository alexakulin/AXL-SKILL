# AXL-SKILL
Collection of SKILL scripts for Cadence Allegro / OrCAD PCB Editor
Developed for Allegro 17.4

## BRIEF INTRO

The Cadence SKILL is used to customize your design environment of Cadence Allegro, it is based on Lisp and supports a more conventional C-like syntax.
For more infomation, just refer to *sklanguser.pdf* by Cadence.

## ABOUT THIS REPOSITORY

Every program here is supposed to achieve certain function, or play as a module. Most of them are interdependent. In addition, programs here are written for universal use, namely that (generally) they won't be restricted by specific design rules, criteria, etc.

## CONTENTS

- allegro.ilinit - load all skill files at start (put it in %HOME/pcbenv)
- grids - interactive grid control form
- set_target - interactively set the target in the matchgroup by pick in the canvas
- addeskd - add ESKD-compatible (Russian standard) Cyrillic text to the canvas

## USE

Put the *allegro.ilinit* file and required skill files to the %HOME%/pcbenv folder,
or to the %CDS_SITE%/pcb/skill folder, and restart Allegro PCB Editor.
HOME is the system variable which shows your "home" path for the PCB Editor.
CDS_SITE is the system variable which shows your "site settings" path.
When Allegro PCB Editor starts, it looks into these folders for *allegro.ilinit* file,
and if it exists it will be loaded and should start the required scripts from the folder.

The use model of each script is described inside the script code in first comment.
You are welcome to suggest the changes and improvements for these scripts.