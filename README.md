# AXL-SKILL
Collection of SKILL scripts for Cadence Allegro / OrCAD PCB Editor
Developed for Allegro 17.4

## BRIEF INTRO

The Cadence SKILL is used to customize your design environment of Cadence Allegro, it is based on Lisp and supports a more conventional C-like syntax.
For more infomation, just refer to *sklanguser.pdf* by Cadence.

## ABOUT THIS REPOSITORY

Every program here is supposed to achieve certain function, or play as a module. Most of them are interdependent. In addition, programs here are written for universal use, namely that (generally) they won't be restricted by specific design rules, criteria, etc.

## CONTENTS

- allegro.ilinit - load all skill files at start (put it in %HOME%/pcbenv)
- grids - interactive grid control form
- set_target - interactively set the target in the matchgroup by pick in the canvas
- addeskd - add ESKD-compatible (Russian standard) Cyrillic text to the canvas
- set_net_color - set the net color by pick

## USE

Put the *allegro.ilinit* file and required skill files to the %HOME%/pcbenv folder,
or to the %CDS_SITE%/pcb/skill folder, and restart Allegro PCB Editor.
HOME is the system variable which shows your "home" path for the PCB Editor.
In Windows use %HOME% in the File Explorer to open this folder.
CDS_SITE is the system variable which shows your "site settings" path.
When Allegro PCB Editor starts, it looks into these folders for *allegro.ilinit* file,
and if it exists it will be loaded and should start the required scripts from the folder.

The use model of each script is described inside the script code in first comment.
You are welcome to suggest the changes and improvements for these scripts.

## DESCRIPTION

### grids - interactive grid control form

Creates the permanent form which allows to see the current grid setting
and to choose the new grid value by single click.

*Advantage:* you can always see the current grid value and you can quickly change it by pick.

### set_target - interactively set the target in the matchgroup by pick

You can pick the cline in the canvas, and if it is inside some matchgroup
it will become the TARGET in this matchgroup.

*Advantage:* you can change the target interactively and quickly just during the routing and
aligning the DDR memory traces, just by pick of the trace which is very quick and convenient.

### addeskd - add Cyrillic text to the canvas

You can add the 8-bit "local language" text in your topology,
based on vector font. Currently the font is Cyrillic ESKD type A,
but the script can be easily modified to support more fonts.
The font standard is SHP which is widely available.

*Advantage:* you can easily add the vector text to your project
in local language, Russian, German or almost any other.

### set_net_color - set the net color by pick

You can change the color of the net, one by one,
selecting the color by pick in the dialog box, then selecting the net trace (cline),
pins or shapes. You can use the temp group and then the window to select multiple objects.
This is useful if you want to separate the nets visually using different colors.

*Advantage:* you can quickly and easily set the net color just by pick
with a compact dialog box with wide color selection.
Please notice that the cross-probe with Capture doesn't create
any problems when you select the "global" nets. When you use
the standard net color function of Allegro, the Capture will open all pages
containing the selected "global" net.

