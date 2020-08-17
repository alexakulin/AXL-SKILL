; Use: skill load("addeskd.il")
; The Menu item will be added: Add / ESKD TEXT
;============================================================================
;  Copyright (C) 2012-2020 PCB SOFT.
;  License: Free use and free modification. No support.
;
;  Program Name: addeskd.il
;  Author: Alexander Akulin. akulin@pcbsoftware.com
;
;  Purpose:
;				Create Cyrillic ESKD (or any other 8-bit local font) text in Allegro PCB, based on vector fonts SHP type.
;
;				When using Allegro PCB, scaled and/or mirrored text characters are attached
;				to a group with timestamp. This group may be moved or deleted (use Find pane / Group).
;
;				Also, by running this utility in the Allegro PCB symbol editor you can create a
;				(non-scalable) mechanical symbol with the texts, for placing in your company library and using later
;				(but when you place this symbol in the PCB project, the lines of text will not be attached to the group
;				but just the lines attached to the mech.symbol)
;
;
;  Platforms tested (It should work on others too, but depends on local codepage for the characters \300...\377):
;				Windows 10
;
;  Allegro versions tested:
;				17.4 qir7
;				
;  Products tested:
;				OrCAD/Allegro PCB Designer
;				Allegro Mechanical symbol editor
;
;  Notes:
;				The "Edit existing text" functionality is disabled in this version, because there is no possibility
;				to set correctly the 8-bit text in the form, in version SPB17.4
;
;============================================================================
;
;  Installation instructions:
;
;				Copy this file into your default skill folder. For example:
;					<cdssite>/pcb/skill
;				or  <home>/pcbenv
;				(<cdssite>/pcb/skill defaults to <cdsroot>/share/local/pcb/skill, otherwise
;				you can check or set the CDS_SITE variable to point to another location)
;				(<home> is defined by the HOME system variable, use %HOME% in Windows file explorer to locate it)
;				Add the line:
;				 load("addeskd.il") 
;					to the allegro.ilinit text file in your skill folder
;				Or see the file:
;					<cdsroot>/share/local/pcb/skill/example.ilinit - it can be copied to allegro.ilinit in your skill folder,
;				and then it will load all *.il files in your skill folder automatically.
;				Read the readme.txt file in %CDSROOT%\share\local\pcb for details.
;
;  Use in Allegro:
;				Menu
;					Add - ESKD TEXT
;				Use the Options pane to change the text in Cyrillic, and to set the parameters.
;				Use Setup / Grid to set the grid, or use P to pick the point, or use RMB / snap pick to...
;				You can use RMB / Cancel to cancel the last text and exit, or Done to finish the command.
;				To move, rotate or delete the whole text - set Filter pane selector to Group.
;				It's not recommended to rotate the group, it's better to setup the text angle in the Options pane.
;
;============================================================================
;  The SHP type font format (just the text file):
;
; *33,17,! EXCLAMATION MARK			; code 33, contains 17 points, "!"
; 2,8,(6,2),1,024,2,0A4,1,8,(0,24),2,8,(6,-38),0		
;					; 2 - pen up, 8 - pen move to 6,2, 1 - pen down, 
;					; 024 - draw 2 steps up
;					; 2 up, 0A4 move 10 steps up
;					; 1 down, 8 move 0,24
;					; 2 up, 8 move to 6, -38
;					; 0 - end
; This can be imported to the following list:
;    (33 (list 2 8 6 2 1 0x24 2 0xA4 1 8 0 24 2 8 6 -38 0))
;
;============================================================================

; command parameters (initial)
  defvar(RS_mirror, 		nil)
  defvar(RS_text_size, 		3.0)   
  defvar(RS_text_line_width, 	3.0/5)
  defvar(RS_text_layer, 	"etch/top") 	; this parameter is re-initialized from current active layer
  defvar(RS_text_rotate, 	0.0) 
  defvar(RS_txtJust,		"Left")
  defvar(RS_text, 			"TEXT") 
  defvar(RS_formID, 		nil) 

  defvar(RS_EditMode		nil)				; =t when the text is in editing mode
  defvar(RS_id				nil)				; the id of the text group

  defvar(RS_scale			1.0)				; the scale of drawing the characters
  
;---- menu parameters
defvar(RS_CommandName1, "ADD_ESKD")
defvar(RS_CommandVisible1, "ESKD TEXT")

;---- menu insertion
procedure( RS_menuTrig1(t_menufile)
let( (q z1 z2)
    q = axlUIMenuFind( nil "add text")
	z1 = axlUIMenuInsert(q 'separator )
    z2 = axlUIMenuInsert(q RS_CommandVisible1 RS_CommandName1) 
))

;--- register the command in PCB Editor, and allow to insert menu both for auto-load and manual load:
axlCmdRegister(RS_CommandName1 'RS_start ?cmdType "interactive" ?undo t)
RS_menuTrig1("none")
axlTriggerSet( 'menu 'RS_menuTrig1) 	; allow to reload my menu at every menu change

when(axlVersion( 'version) != 17.4, printf("!WARNING - The %s script was tested only under version 17.4\n", RS_CommandName1) )

/****************************************************************/
/***** Main routine *********************************************/
/****************************************************************/
procedure( RS_start( @optional (EditMode nil) )
    let(( p fn activeLayer mp (EnableCycle t) (x 0) (y 1)
		str ch
	   )

;---- set initial text value
	RS_text = "TEXT"
	RS_id = nil
	RS_Cancel = nil
	   
;---- create the mini-form
  p = AFn_formOpenFile()
  fn = get_filename(p)
  AFn_formHeader(p, 30, "Add Russian Text")
  AFn_formPopupDefine(p, "ANGLES", '(0.0, 45.0, 90.0, 135.0, 180.0, 235.0, 270.0, 315.0))
  AFn_formPopupDefine(p, "JUSTIFICATIONS", '("Left", "Right", "Center"))
  AFn_formText(p, "Active Class and Subclass:", x + 1, y), y = y + 2
  AFn_formPop(p, "class", "CLASS", x + 5, y, 19, ?options "prettyprint"), y = y + 3
  AFn_formColor(p, "subcolour", x + 2, y, 2, 1)
  AFn_formPop(p, "usersubclass", "subclass", x + 5, y, 19 ?options "prettyprint ownerdrawn"), y = y + 3
  AFn_formRealFillin(p, "txtsize", 8, 7, x + 5, y, ?title "Text size:", ?fillInX x + 15, ?minVal 0, ?units car(AFn_getDesignUnits())), y = y + 2
  AFn_formRealFillin(p, "linwidth", 8, 7, x + 5, y, ?title "Line width:", ?fillInX x + 15, ?minVal 0, ?units car(AFn_getDesignUnits())), y = y + 2
  AFn_formRealFillin(p, "rotate", 8, 7, x + 5, y, ?title "Rotate:", ?fillInX x + 15, ?minVal 0, ?maxVal 359.0, ?units "deg", ?pop "ANGLES"), y = y + 2
  AFn_formChecklistItem(p, "mirror", x + 3, y, "Mirror"), y = y + 3
  AFn_formStrFillin(p, "text", 20, 80, x + 2, y, ?title "Text:", ?x2 x + 6), y = y + 3
  AFn_formEnd(p)
  axlDMClose(p)
  RS_formID = axlMiniStatusLoad(gensym(), fn, 'RS_formAction)
	   
;---- set the fields in the form (from initial values or from the selected Edit text)
  activeLayer = parseString(axlDBControl('activeLayer), "/")
  AFn_formSetLayerFields(RS_formID, "class", "usersubclass", "subcolour", car(activeLayer), cadr(activeLayer))
  AFn_formLayerSubColour(RS_formID, "class", "usersubclass", "subcolour")
  axlFormSetField(RS_formID, "mirror", RS_mirror)
  axlFormSetField(RS_formID, "txtsize", RS_text_size)
  axlFormSetField(RS_formID, "linwidth", RS_text_line_width)
  axlFormSetField(RS_formID, "rotate", RS_text_rotate)
  axlFormSetField(RS_formID, "text", RS_text)
  axlFormDisplay(RS_formID)

;---- set right mouse button menu with Cancel and Done
	mp = axlUIPopupDefine( nil (list (list "Cancel" 'RS_MyCancel)	(list "Done" 'RS_MyDone)))
	axlUIPopupSet( mp)

;---- set the cursor to rectangle view
	_RSCreateCursor( RS_formID)
	
; Ask user for point and allow to setup text and its parameters in the Options form
	axlControlRaise('options)
	axlFormSetActiveField( RS_formID "text")
	printf( "Enter the text in the Options pane...\n")
	while( EnableCycle && (mypoint = axlEnterPoint(?prompts list("Add Text - enter XY point")   ?gridSnap t))
		printf( "Draw text '%s' at XY = %f %f\n", RS_text, car(mypoint) cadr(mypoint))
		RS_id = _RSCreateText(  mypoint)
		_RSCreateCursor( RS_formID)
	)

;---- delete the text if Cancel
	when( (RS_Cancel && RS_id)
			axlDeleteObject(RS_id->groupMembers)	; remove old text from database
			axlDBDisbandGroup( RS_id)
			RS_id = nil
	)
	
;---- reset the cursor
	axlClearDynamics()
	
))

/************************************************************************************/
/*** Draw the rectangle cursor according to the Options form text size and mirror ***/
/************************************************************************************/
procedure( _RSCreateCursor( formID)
let((mypath, 	mypoint	char_code	char_data	line_path	text)
  	axlClearDynamics()
	text = axlFormGetField( formID, "text")
	if( text == ""	
	then
		mypath = axlPathStart(  list( 
			0:0 
			_RSXY( 0:0, 							0:0, RS_text_rotate RS_mirror)
			_RSXY( RS_text_size*0.5:0 , 			0:0, RS_text_rotate RS_mirror)
			_RSXY( RS_text_size*0.5:RS_text_size, 	0:0, RS_text_rotate RS_mirror)
			_RSXY( 0:RS_text_size  , 				0:0, RS_text_rotate RS_mirror)
			0:0))
		axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
	else		
	mypoint = 0:0
	foreach( char_code parseString( text "" ) 
		char_data = _RSDrawChar( char_code, mypoint, 1.0)
		foreach( line_path car(char_data)
			axlAddSimpleMoveDynamics(0:0 line_path "path" ?ref_point 0:0)
		)
		mypoint = cadr( char_data)
	))
))

/*** Rotate the point by angle around the Text_XY base point. Optional mirror horizontally ***/
procedure( _RSXY( XY Text_XY Text_Rot Text_Mirror)
	axlGeoRotatePt( Text_Rot XY Text_XY Text_Mirror)
)

/***********************************************/
/*** Get the changed value from Options form ***/
/***********************************************/
defun( RS_formAction (form)
 let((class, subclass, subclasses, mypath,  mypoint, id, char_code, char_data, line_path,  (Change_Flag nil) )
  case(form ->curField
    ("mirror", RS_mirror = axlFormGetField(form, "mirror"), Change_Flag = t)
    ("txtsize", RS_text_size = axlFormGetField(form, "txtsize"), Change_Flag = t)
    ("linwidth", RS_text_line_width = axlFormGetField(form, "linwidth") , Change_Flag = t)	
    ("rotate", RS_text_rotate = axlFormGetField(form, "rotate"), Change_Flag = t)
    ("class",
      class = AFn_formInterpretClassPopField(axlFormGetField(form, "class"))
      axlBuildSubclassPopup(form, "usersubclass", class)
      subclasses = sort(axlGetParam(strcat("paramLayerGroup:", class)) ->groupMembers, 'alphalessp)
      subclass = car(setof(sub, subclasses, axlIsVisibleLayer(strcat(class, "/", sub))) || subclasses)
      axlFormSetField(form, "usersubclass", subclass)
      AFn_formLayerSubColour(form, "class", "usersubclass", "subcolour")
	  Change_Flag = t
    )
    ("usersubclass", AFn_formLayerSubColour(form, "class", "usersubclass", "subcolour"), Change_Flag = t)
    ("subcolour", AFn_formLayerSubColour(form, "class", "usersubclass", "subcolour", t))
    ("text", 	RS_text = axlFormGetField( RS_formID, "text"), Change_Flag = t)
  )
  
;--- if new value entered, and if the text is selected, change this text, otherwise change the cursor size
  when( Change_Flag
	if( RS_EditMode
	then
		when( RS_id
			mypoint = car(car(RS_id->groupMembers)->bBox)    ; get xy of first obj of old text = base position of old text
																	;(at the moment - approximately!!!)
																	; we need to know the base point (origin of the group)
																	; and the position of the first character bBox from origin
			x = car(mypoint) - RS_orig_x
			y = cadr(mypoint) - RS_orig_y
			mypoint = list(x y)
			id = _RSCreateText(  mypoint)
			axlDeleteObject(RS_id->groupMembers)	; remove old text from database
			axlDBDisbandGroup( RS_id)
			RS_id = id
			axlSingleSelectObject( RS_id->groupMembers)
		)
	else
		_RSCreateCursor( form)
	)
  )
))

/*****************************************/
/*** TERMINATING FUNCTIONS ***/
/*****************************************/
(defun RS_MyCancel ()
	RS_Cancel = t
	axlClearDynamics()
	axlCancelEnterFun()
	axlUIPopupSet(nil))
	
(defun RS_MyDone ()
	axlClearDynamics()
	axlFinishEnterFun()
	axlUIPopupSet(nil))


/***************************************************************/
/* create new text from the Options form in position "mypoint" */
/* return id of Group                                          */
/***************************************************************/
procedure(   _RSCreateText(  mypoint)
; get the new class/subclass
	let( 	(point, orig_x, orig_y t_name o_group char_data l_result )
		RS_class = AFn_formInterpretClassPopField(axlFormGetField(RS_formID, "class"))
		RS_subclass = axlFormGetField(RS_formID, "usersubclass")
		RS_text_layer = strcat( RS_class "/" RS_subclass)
; get the text string
		RS_text = axlFormGetField( RS_formID, "text")
		when( RS_text && (RS_text != "")
		; draw the string and add it to created group
			t_name = getCurrentTime()
			o_group = axlDBCreateGroup( t_name, "generic", nil)
			point = mypoint
			foreach( Char_Code parseString( RS_text "" ) 
				char_data = _RSDrawChar( Char_Code, point, RS_scale)
				foreach( line_path car(char_data)
					l_result = axlDBCreatePath( line_path, RS_text_layer, 'line)
					when( l_result && o_group
						when( car( l_result)
							axlDBAddGroupObjects( o_group,  car( l_result))
						)
					)
				)
				point = cadr( char_data)
			)
			point = car(car(o_group->groupMembers)->bBox)
			when( point
				orig_x = car(point) - car(mypoint)
				orig_y = cadr(point) - cadr(mypoint)
				RS_orig_x = orig_x
				RS_orig_y = orig_y
				axlDBAddProp( list(o_group), list( 'COMMENT,  RS_ConvToHex( RS_text,  orig_x, orig_y)))
			)
		)
		o_group
))

procedure(   RS_ConvToHex( text, orig_x, orig_y)
(let (string char)
	string = "ESKD"
	if( RS_mirror,	then string = strcat( string, "1 "), else string = strcat( string, "0 "))
	string = strcat( string, sprintf( nil, "%f ", RS_text_size))
	string = strcat( string, sprintf( nil, "%f ", RS_text_line_width))
	string = strcat( string, sprintf( nil, "%f ", RS_text_rotate))
	string = strcat( string, sprintf( nil, "%f %f ", orig_x, orig_y))
	string = strcat( string, sprintf( nil, "%s ", RS_txtJust))
	foreach( char parseString( text "" ) 
		string = strcat( string, sprintf( nil, "%2x", charToInt(stringToSymbol(char) )))
	)
	string
))

procedure(   RS_ConvFromHex( text)
(let ((string "") char s_length port i num)
	text = substring(text, 5)
	port = instring(text)
	fscanf(port, "%d %f %f %f %f %f %s ", RS_mirror, RS_text_size, RS_text_line_width, RS_text_rotate, RS_orig_x, RS_orig_y, RS_txtJust)
	RS_mirror = (RS_mirror == 1)
	while( fscanf(port "%2x" num)
		string = strcat( string, intToChar(num) )
	)
	close(port)
	string
))

procedure( _RSDrawChar( char_code text_XY0 scale_coef)
    let( (char_graphics TXY1, TXY2, TTXY1, TTXY2, Xscale, Yscale, path_list, Char_Data
          (font_upper 40)  (font_lower 12)  (x_char 155) (y_char 93)  (k 0) (k1 0) (stage 0) 
	    (X1 0.0) (X2 0.0) (Y1 0.0) (Y2 0.0) 		; local XY of line segment
	    (text_X0 155) (text_Y0 93) (cmd_pen 1) 
		(stack_X nil)  (stack_Y nil)
 	    line_path clock_wise (Arc_H 0.0) (Arc_L 0.0) ( Arc_R 0.0) (Move_Value 0.0)
	    (Arc_OctStart 0.0) ( Arc_OctNum 0.0) ( Arc_CenterX 0.0) ( Arc_CenterY 0.0) Arc_BIG  (Arc_Finish 0.0)  )	; local variables

	text_X0 = xCoord(text_XY0 ) 
	text_Y0 = yCoord(text_XY0 )
	Xscale = RS_text_size/float(font_upper)
	Yscale = Xscale		; should depend on text block width parameter
	path_list = nil		; will contain the whole graphics of character

      ; take the graphical description of character from the library
      char_graphics = _RSRead_Char_Graphs( charToInt(stringToSymbol(char_code) ) )
      if( char_graphics
	foreach( graph_cmd  char_graphics
	  caseq( stage
	  (0 				; read the command
	    if( graph_cmd <=15
	    then
	      caseq( graph_cmd
		(1
			cmd_pen=1	; pen down
		)
		(2
			cmd_pen=2	; pen up
		)
		(3   
			stage=3	; scale coef to divide by
		)
		(4   
			stage=4	; scale coef to multiply by 
		)
		(5   
			stack_X = cons( X1, stack_X)		;save current XY in stack
			stack_Y = cons( Y1, stack_Y)
			stage=0
		)
		(6   
			X1 = car( stack_X)		; restore current XY from stack
			Y1 = car( stack_Y)
			stack_X = cdr( stack_X)
			stack_Y = cdr( stack_Y)
			stage=0
		)
		(7   
			stage=7	; use another character shape - 7 CharCode
		)
		(8   
			stage=8	; move with dX dY
		)
		(9   
			stage=9	; sequence of moves with dX dY, ..., 0,0
		)
		(10
			stage=10	; arc R 0xSN
		)
		(11
			stage=11	; arc 
		)
		(12
			stage=12	; arc with dX dY h
		)
		(13   
			stage=13	; sequence of arcs with dX dY h, ..., 0,0
		)
		)	; graph_cmd
	    else
		Move_Dir = graph_cmd & 0x0F
		Move_Value = (graph_cmd & 0xF0)/16 / scale_coef
		caseq( Move_Dir
		( (0 2 14)
			X2 = X1+Move_Value
		)
		( (6 8 10)
			X2 = X1-Move_Value
		))
		caseq( Move_Dir
		( (2 4 6)
			Y2 = Y1+Move_Value
		)
		( (10 12 14)
			Y2 = Y1-Move_Value
		))

		TXY1 = _RSXY( xCoord(text_XY0)+float(X1)*Xscale : yCoord(text_XY0)+float(Y1)*Yscale, text_XY0, RS_text_rotate RS_mirror)
		TXY2 = _RSXY( xCoord(text_XY0)+float(X2)*Xscale : yCoord(text_XY0)+float(Y2)*Yscale, text_XY0, RS_text_rotate RS_mirror)
		
		when( cmd_pen==1
			line_path = axlPathStart( (list TXY1))
			axlPathLine( line_path, RS_text_line_width, TXY2 )
			path_list = cons( line_path, path_list)
		)
		X1 = X2
		Y1 = Y2
	    )		; graph_cmd > 15
	  )		; (0
	  (3
		scale_coef = scale_coef*graph_cmd
		stage=0
	  )
	  (4
		scale_coef = scale_coef/graph_cmd
		stage=0
	  )
	  (7 					; char code of sub-shape
		text_XY0 = _RSXY( xCoord(text_XY0)+float(X1)*Xscale : yCoord(text_XY0)+float(Y1)*Yscale, text_XY0, RS_text_rotate RS_mirror)
		Char_Data =  _RSDrawChar( symbolToString(intToChar(graph_cmd)), text_XY0, scale_coef )
		foreach( line_path,  car(Char_Data)
			path_list = cons( line_path, path_list)
		)
		text_XY0  =  cadr(Char_Data)
		text_X0 = xCoord(text_XY0 ) 
		text_Y0 = yCoord(text_XY0 )
		stage=0
		X1 = 0
		Y1 = 0
	  )
	  (8 					; dX parameter of dX dY
		X2 = X1+graph_cmd/scale_coef 
		stage=81	
	  )
	  (81					; dY parameter of dX dY
		Y2 = Y1+graph_cmd/scale_coef 
		stage=0	
		TXY1 = _RSXY( xCoord(text_XY0)+float(X1)*Xscale : yCoord(text_XY0)+float(Y1)*Yscale, text_XY0, RS_text_rotate RS_mirror)
		TXY2 = _RSXY( xCoord(text_XY0)+float(X2)*Xscale : yCoord(text_XY0)+float(Y2)*Yscale, text_XY0, RS_text_rotate RS_mirror)

		; draw the lines according to the entered string characters
		when( cmd_pen==1
			line_path = axlPathStart( (list TXY1))
			axlPathLine( line_path, RS_text_line_width, TXY2 )
			path_list = cons( line_path, path_list)
		)
		X1 = X2
		Y1 = Y2
	  )
	  (9					; move dX of dX dY
		X2 = X1+graph_cmd/scale_coef 
		stage=91	
	  )
	  (91					; move dY of dX dY
		Y2 = Y1+graph_cmd/scale_coef 
		if( (X1==X2 && Y1==Y2)
		  then
		stage=0		; 0,0 - end of arc sequence
		  else
		stage=9		; sequence not finished
;		TX1 = _RSX( X1 text_X0 RS_text_size/font_upper RS_text_rotate )
;		TX2 = _RSX( X2 text_X0 RS_text_size/font_upper RS_text_rotate )
;		TY1 = _RSY( Y1 text_Y0 RS_text_size/font_upper RS_text_rotate )
;		TY2 = _RSY( Y2 text_Y0 RS_text_size/font_upper RS_text_rotate )
		TXY1 = _RSXY( xCoord(text_XY0)+float(X1)*Xscale : yCoord(text_XY0)+float(Y1)*Yscale, text_XY0, RS_text_rotate RS_mirror)
		TXY2 = _RSXY( xCoord(text_XY0)+float(X2)*Xscale : yCoord(text_XY0)+float(Y2)*Yscale, text_XY0, RS_text_rotate RS_mirror)

		when( cmd_pen==1
			line_path = axlPathStart( (list TXY1))
			axlPathLine( line_path, RS_text_line_width, TXY2 )
			path_list = cons( line_path, path_list)
		)
		X1 = X2
		Y1 = Y2
		)	; !(X1==X2 && Y1==Y2)
	  )
; 10, радиус, код дуги  :   
; 0x ... начальный октант (0...7) ... число октантов (если 0 - окружность), минус - по часовой
	  (10					; arc R (-)0xSN	
		Arc_R = graph_cmd/scale_coef 
		stage=101
	  )
	  (101					; (-)0xSN
		stage=0
		if( graph_cmd<0
		then
			clock_wise = t			; minus - clockwise arc
			graph_cmd = abs( graph_cmd)
		else
			clock_wise = nil
		)
		Arc_OctNum = graph_cmd & 0x0F		; N
		if( Arc_OctNum == 0
		then
			Arc_OctNum = 8		; N=0 - full circle
		)
		Arc_OctStart = (graph_cmd & 0xF0)/16	; S

; axlUIWPrint(nil "Start: %n, Num: %n, Cmd: %x" Arc_OctStart Arc_OctNum graph_cmd)

		caseq( Arc_OctStart
		( 0
		  Arc_CenterX = X1-Arc_R
		  Arc_CenterY = Y1
		)
		( 1
		  Arc_CenterX = X1-0.707*Arc_R
		  Arc_CenterY = Y1-0.707*Arc_R
		)
		( 2
		  Arc_CenterX = X1
		  Arc_CenterY = Y1-Arc_R
		)
		( 3
		  Arc_CenterX = X1+0.707*Arc_R
		  Arc_CenterY = Y1-0.707*Arc_R
		)
		( 4
		  Arc_CenterX = X1+Arc_R
		  Arc_CenterY = Y1
		)
		( 5
		  Arc_CenterX = X1+0.707*Arc_R
		  Arc_CenterY = Y1+0.707*Arc_R
		)
		( 6
		  Arc_CenterX = X1
		  Arc_CenterY = Y1+Arc_R
		)
		( 7
		  Arc_CenterX = X1-0.707*Arc_R
		  Arc_CenterY = Y1+0.707*Arc_R
		)
		) ; Arc_Start

		Arc_BIG = (Arc_OctNum > 4)		; ? I'm not sure: >4 or >=4?

		if( clock_wise
		then
			Arc_OctNum = (-Arc_OctNum)	; clockwise direction is negative angle
		)
		Arc_Finish = 0x7 & (Arc_OctStart+Arc_OctNum)		; normalize the octant number by 7

		caseq( Arc_Finish
		( 0
		  X2 = Arc_CenterX+Arc_R
		  Y2 = Arc_CenterY
		)
		( 1
		  X2 = Arc_CenterX+0.707*Arc_R
		  Y2 = Arc_CenterY+0.707*Arc_R
		)
		( 2
		  X2 = Arc_CenterX
		  Y2 = Arc_CenterY+Arc_R
		)
		( 3
		  X2 = Arc_CenterX-0.707*Arc_R
		  Y2 = Arc_CenterY+0.707*Arc_R
		)
		( 4
		  X2 = Arc_CenterX-Arc_R
		  Y2 = Arc_CenterY
		)
		( 5
		  X2 = Arc_CenterX-0.707*Arc_R
		  Y2 = Arc_CenterY-0.707*Arc_R
		)
		( 6
		  X2 = Arc_CenterX
		  Y2 = Arc_CenterY-Arc_R
		)
		( 7
		  X2 = Arc_CenterX+0.707*Arc_R
		  Y2 = Arc_CenterY-0.707*Arc_R
		)
		) ; Arc_Finish

		TXY1 = _RSXY( xCoord(text_XY0)+float(X1)*Xscale : yCoord(text_XY0)+float(Y1)*Yscale, text_XY0, RS_text_rotate RS_mirror)
		TXY2 = _RSXY( xCoord(text_XY0)+float(X2)*Xscale : yCoord(text_XY0)+float(Y2)*Yscale, text_XY0, RS_text_rotate RS_mirror)

		Arc_R = Arc_R*RS_text_size/font_upper 		; we suppose that Xscale == Yscale, and we draw circle, not oval
		when( cmd_pen==1
		    if( ( (Arc_OctNum == 8) || (Arc_OctNum == (-8) ) )
		    then
			  TXY1 = _RSXY( xCoord(text_XY0)+float(Arc_CenterX)*Xscale : yCoord(text_XY0)+float(Arc_CenterY)*Yscale, text_XY0, RS_text_rotate RS_mirror)
			  line_path = axlPathStartCircle( (list TXY1 Arc_R), RS_text_line_width)
			  path_list = cons( line_path, path_list)
		    else
			  when( RS_mirror, clock_wise = !clock_wise)
			  line_path = axlPathStart( (list TXY1))
			  axlPathArcRadius( line_path, RS_text_line_width, TXY2, clock_wise, Arc_BIG, Arc_R )
			  path_list = cons( line_path, path_list)
		    )
		)
		X1 = X2
		Y1 = Y2
	  )
; 11, Shift of start, of end, higher digits of Radius, lower, arc code
; - shift of start is difference between start of precious octant 
; and arc start (in degreeх), div by 45 and mul by 256;
; - shift of end - the same, to last octant, crossed by arc;
; - higher digits - hundreds 
; (R=325 higher - 3, lower - 25, if R=75 higher - 0, lower - 75).
; 11,(108,0,0,18,062)
; 108 - shift of start arc angle from previous octant angle in degrees, X=Angle/45*256
; 0 - shift of arc end of last crossed octant
; 0 - hundreds in R value
; 18 - ones and tens in R value
; 062 - arc code		(6th octant, 2 octants clockwise)
	  (11					; arc Shift_Start Shift_End Rad_100 Rad_001 Arc_Code
		Shift_Start = float( graph_cmd)/256.*45./180*3.1415	; in degrees -> in Radian
		stage=111
	  )
	  (111					; Shift_End
		Shift_End = float( graph_cmd)/256.*45./180*3.1415	; in degrees -> in Radian
		stage=112
	  )
	  (112					; Rad_100 Rad_001 Arc_Code
		Arc_R = graph_cmd*100/scale_coef 
		stage=113
	  )
	  (113					; Rad_001 Arc_Code
		Arc_R = Arc_R+graph_cmd/scale_coef 
		stage=114
	  )
	  (114					; 0xSN
		stage=0
		if( graph_cmd<0
		then
			clock_wise = t			; minus - clockwise arc
			graph_cmd = abs( graph_cmd)
		else
			clock_wise = nil
		)
		Arc_OctNum = graph_cmd & 0x0F		; N
		if( Arc_OctNum == 0
		then
			Arc_OctNum = 8		; N=0 - full circle
		)
		Arc_OctStart = (graph_cmd & 0xF0)/16	; S

; axlUIWPrint(nil "Start: %n, Num: %n, Cmd: %x" Arc_OctStart Arc_OctNum graph_cmd)

; may be, if arc is clockwise, we should subtract Shift_Start 
		  Arc_CenterX = X1-Arc_R*cos(Arc_OctStart*3.1415/4+Shift_Start)
		  Arc_CenterY = Y1-Arc_R*sin(Arc_OctStart*3.1415/4+Shift_Start)

		Arc_BIG = (Arc_OctNum > 4)		; ? I'm not sure: >4 or >=4?

; axlUIWPrint(nil "Shift_Start: %f, Shift_End: %f, CX: %f CY: %f" Shift_Start Shift_End Arc_CenterX Arc_CenterY )

		if( clock_wise
		then
			Arc_OctNum = (-Arc_OctNum)	; clockwise direction is negative angle
		)
		Arc_Finish = 0x7 & (Arc_OctStart+Arc_OctNum)		; normalize the octant number by 7

; may be if arc is clockwise we need to subtract  Shift_End 
		  X2 = Arc_CenterX+Arc_R*cos(Arc_Finish*3.1415/4+Shift_End)
		  Y2 = Arc_CenterY+Arc_R*sin(Arc_Finish*3.1415/4+Shift_End)

; axlUIWPrint(nil "A: %n %n - %n %n, R:%n S:%n F:%n N:%n P:%n" X1 Y1 X2 Y2 Arc_R Arc_OctStart Arc_Finish Arc_OctNum cmd_pen)


;		TX1 = _RSX( X1 text_X0 RS_text_size/font_upper RS_text_rotate )
;		TX2 = _RSX( X2 text_X0 RS_text_size/font_upper RS_text_rotate )
;		TY1 = _RSY( Y1 text_Y0 RS_text_size/font_upper RS_text_rotate )
;		TY2 = _RSY( Y2 text_Y0 RS_text_size/font_upper RS_text_rotate )
		TXY1 = _RSXY( xCoord(text_XY0)+float(X1)*Xscale : yCoord(text_XY0)+float(Y1)*Yscale, text_XY0, RS_text_rotate RS_mirror)
		TXY2 = _RSXY( xCoord(text_XY0)+float(X2)*Xscale : yCoord(text_XY0)+float(Y2)*Yscale, text_XY0, RS_text_rotate RS_mirror)

		Arc_R = Arc_R*RS_text_size/font_upper 
		if( cmd_pen==1
		  then
		    if( ( (Arc_OctNum == 8) || (Arc_OctNum == (-8) ) )
		    then
			  TXY1 = _RSXY( xCoord(text_XY0)+float(Arc_CenterX)*Xscale : yCoord(text_XY0)+float(Arc_CenterY)*Yscale, text_XY0, RS_text_rotate RS_mirror)
			  line_path = axlPathStartCircle( (list TXY1 Arc_R), RS_text_line_width)
			  path_list = cons( line_path, path_list)
		    else
			  when( RS_mirror, clock_wise = !clock_wise)
			  line_path = axlPathStart( (list TXY1))
			  axlPathArcRadius( line_path, RS_text_line_width, TXY2, clock_wise, Arc_BIG, Arc_R )
			  path_list = cons( line_path, path_list)
		    )
		)
		X1 = X2
		Y1 = Y2

	  )
	  (12					; arc dX of dX dY h
		X2 = X1+graph_cmd/scale_coef 
		stage=121
	  )
	  (121				; arc dY of dX dY h
		Y2 = Y1+graph_cmd/scale_coef 
		stage=122
	  )
	  (13					; arc dX of dX dY h in sequence
		X2 = X1+graph_cmd/scale_coef 
		stage=131
	  )
	  (131				; arc dY of dX dY h
		Y2 = Y1+graph_cmd/scale_coef 
		if( X1==X2 && Y1==Y2
		  then
			stage=0		; 0,0 - end of arc sequence
		  else
			stage=132
		)
	  )
	  (132				; arc h of dX dY h sequence
		stage=13			; sequence not finished

; The h is given as S=2 * H / L * 127
;  H = S*L/2/127
; we here don't manage the case if H > R (big arc: angle > 180)
		Arc_L = sqrt( float((X2-X1)**2 + (Y2-Y1)**2) )
		Arc_H = float(abs(graph_cmd ))*Arc_L/2/127
		clock_wise = (graph_cmd<0)
		when( RS_mirror, clock_wise = !clock_wise)
		Arc_R = ((Arc_L/2)**2/Arc_H + Arc_H)/2
		TXY1 = _RSXY( xCoord(text_XY0)+float(X1)*Xscale : yCoord(text_XY0)+float(Y1)*Yscale, text_XY0, RS_text_rotate RS_mirror)
		TXY2 = _RSXY( xCoord(text_XY0)+float(X2)*Xscale : yCoord(text_XY0)+float(Y2)*Yscale, text_XY0, RS_text_rotate RS_mirror)
		Arc_R = Arc_R*RS_text_size/font_upper 

		; draw the lines according to the entered string characters
		when( cmd_pen==1
			line_path = axlPathStart( (list TXY1))
			axlPathArcRadius( line_path, RS_text_line_width, TXY2, clock_wise, nil, Arc_R )
			path_list = cons( line_path, path_list)
		)
		X1 = X2
		Y1 = Y2
	  )
	  (122				; arc h of dX dY h
		stage=0			

; The h is given as S=2 * H / L * 127
;  H = S*L/2/127
; we here don't manage the case if H > R (big arc: angle > 180)
		Arc_L = sqrt( float((X2-X1)**2 + (Y2-Y1)**2) )
		Arc_H = float(abs(graph_cmd ))*Arc_L/2/127
		clock_wise = (graph_cmd<0)
		when( RS_mirror, clock_wise = !clock_wise)
		
		Arc_R = ((Arc_L/2)**2/Arc_H + Arc_H)/2
		TXY1 = _RSXY( xCoord(text_XY0)+float(X1)*Xscale : yCoord(text_XY0)+float(Y1)*Yscale, text_XY0, RS_text_rotate RS_mirror)
		TXY2 = _RSXY( xCoord(text_XY0)+float(X2)*Xscale : yCoord(text_XY0)+float(Y2)*Yscale, text_XY0, RS_text_rotate RS_mirror)
		Arc_R = Arc_R*RS_text_size/font_upper 

		; draw the lines according to the entered string characters
		when( cmd_pen==1
			line_path = axlPathStart( (list TXY1))
			axlPathArcRadius( line_path, RS_text_line_width, TXY2, clock_wise, nil, Arc_R )
			path_list = cons( line_path, path_list)
		)
		X1 = X2
		Y1 = Y2
	  )
	  )	; stage
      ))	; graph_cmd  
	text_XY0 = _RSXY( xCoord(text_XY0)+float(X1)*Xscale : yCoord(text_XY0)+float(Y1)*Yscale, text_XY0, RS_text_rotate RS_mirror)
	list( path_list, text_XY0)
))

; ************* This reads the character graphics from the current font data
; 2 - pen up
; 1 - pen down
; 8 - move dX dY
; 0 - end
; 9 - sequence of moves dx, dy, ..., 0,0
; 10 - arc R 0xSN
; 13 - sequence of arcs dx, dy, h, ...., 0,0
procedure( _RSRead_Char_Graphs( char )
  caseq( char

; *32 5 SPACE
    (32 (list 2 8 16 0 0))

; *33 17 ! EXCLAMATION MARK			; номер 33  17 точек  "!"
    (33 (list 2 8 6 2 1 0x24 2 0xA4 1 8 0 24 2 8 6 -38 0))

; *34 19 " QUOTATION MARK
    (34 (list 2 8 6 30 1 8 2 8 2 0xA0 1 8 -2 -8 2 8 8 -30 0))

; *35 27 N LATIN CAPITAL LETTER N
;    (35 (list 2 8 6 2 1 9 0 36 20 -36 0 36 0 0 2 8 4 -4 1 10 4 0x40 2 8 10 -34 0))
; *35      # SYMBOL #
;    (35 (list 2 8 6 2 1 8 10 36 2 8 12 0 1 8 -10 -36 2 8 -15 10 1 8 24 0 2 8 -20 16 1 8 24 0 2 8 6 -28 0))
    (35 (list 2 8 6 2 1 8   8 36 2 8 10 0 1 8   -8 -36 2 8 -13 10 1 8 20 0 2 8 -16 16 1 8 20 0 2 8 5 -28 0))

; *36 39 $ DOLLAR SIGN
    (36 (list 2 8 14 2 1 8 0 36 2 8 8 -6 1 12 -8 2 16 0x28 12 -3 -11 98 8 10 -6 12 -3 -11 -98
 0x28 12 -8 2 -16 2 8 22 -8 0))

; *37 29 % PERCENT SIGN
    (37 (list 2 8 6 2 1 8 32 36 2 8 -20 -6 1 10 6 0x00 2 8 8 -24 1 10 6 0x40 2 8 18 -8 0))

; *38 41 & AMPERSAND
    (38 (list 2 8 30 14 1 3 10 4 2 8 -72 -54 3 2 12 -89 76 -102 4 4 8 31 45 3 4 4 10 11 68 187
 0 6 0x76 8 17 -27 2 8 10 -2 0))

; *39 13 ' APOSTROPHE = APOSTROPHE-QUOTE
    (39 (list 2 8 6 30 1 8 2 8 2 8 6 -38 0))

; *40 14  LEFT PARENTHESIS = OPENING PARENTHESIS
    (40 (list 2 8 10 42 1 12 0 -44 23 2 8 6 2 0))

; *41 14  RIGHT PARENTHESIS = CLOSING PARENTHESIS
    (41 (list 2 8 6 -2 1 12 0 44 23 2 8 10 -42 0))

; *42 29 ; *
    (42 (list 2 8 8 38 1 8 8 -12 2 8 -8 0 1 8 8 12 2 8 -10 -6 1 8 12 0 2 8 6 -32 0))

; *43 19 + PLUS SIGN
    (43 (list 2 8 14 6 1 8 0 16 2 0x8A 1 8 16 0 2 8 6 -14 0))

; *44 11   COMMA
    (44 (list 2 0x6E 1 8 2 8 2 8 6 -2 0))

; *45 13 - HYPHEN-MINUS
    (45 (list 2 8 6 14 1 8 16 0 2 8 6 -14 0))

; *46 11 . FULL STOP
    (46 (list 2 8 6 2 1 0x24 2 8 6 -4 0))

; *47 13 / SOLIDUS = SLASH
    (47 (list 2 8 6 2 1 8 16 36 2 8 6 -38 0))

; *48 25 0 DIGIT ZERO
    (48 (list 2 8 10 4 1 13 0 32 -32 8 0 -64 0 -32 -32 -8 0 -64 0 0 2 8 18 -4 0))

; *49 14 1 DIGIT ONE
    (49 (list 2 8 14 2 1 8 0 36 0x8A 2 8 14 -30 0))

; *50 32 2 DIGIT TWO
    (50 (list 2 8 6 32 1 12 8 6 -43 3 10 12 68 -122 -75 4 2 8 -74 -119 4 10 3 2 8 16 0 2 8 6
 -2 0))

; *51 25 3 DIGIT THREE
    (51 (list 2 8 6 38 1 0x80 10 8 -0x24 5 0x48 6 10 8 -0x22 0x4C 10 8 -0x02 0x88 2 8 22 -2 0))

; *52 24 4 DIGIT FOUR
    (52 (list 2 8 14 38 1 8 -8 -28 8 20 0 2 8 -6 8 1 8 0 -16 2 8 12 -2 0))

; *53 23 5 DIGIT FIVE
    (53 (list 2 8 6 2 1 0x80 10 8 0x62 0x44 10 8 0x02 0x88 8 0 16 0xE0 2 8 8 -38 0))

; *54 25 6 DIGIT SIX
    (54 (list 2 8 18 38 1 12 -12 -16 38 0xCC 12 16 0 127 0x44 12 -8 8 63 0x88 2 8 22 -22 0))

; *55 17 7 DIGIT SEVEN
    (55 (list 2 8 14 2 1 8 8 36 8 -16 0 0x4C 2 8 22 -34 0))

; *56 24 8 DIGIT EIGHT
    (56 (list 2 8 14 22 1 10 8 0x60 2 0x8A 1 10 8 -0x44 0x4C 10 8 -0x04 0x44 2 8 22 -14 0))

; *57 25 9 DIGIT NINE
    (57 (list 2  8 10 2 1     11 108 0 0 18 0x62    0xB4    10 8 0x04   0x4C   10 8 0x42  
  0x80 2    8 6 -18 0))


; *58 13 : COLON
    (58 (list 2 0x62 1 0x24 2 0xC4 1 0x24 2 8 6 -22 0))

; *59 15
    (59 (list 2 0x6E 1 8 2 8 2 0xE4 1 0x24 2 8 6 -18 0))

; *60 16 < LESS-THAN SIGN
    (60 (list 2 8 22 20 1 8 -16 -6 8 16 -6 2 8 6 -8 0))

; *61 19 = EQUALS SIGN
    (61 (list 2 8 6 8 1 8 16 0 2 0xC4 1 8 -16 0 2 8 22 -20 0))

; *62 16 > GREATER-THAN SIGN
    (62 (list 2 8 6 8 1 8 16 6 8 -16 6 2 8 22 -20 0))

; *63 34 ? QUESTION MARK
    (63 (list 2 8 6 36 1 12 10 2 -16 3 10 12 42 -102 -85 8 -45 -45 12 -17 -42 25 4 10 0x5C
 2 0xAC 1 0x2C 2 8 14 -2 0))

; *64 40 @ COMMERCIAL AT
    (64 (list 2 8 20 -10 1 10 14 -0x62 8 0 18 10 16 -0x44 8 0 -15 10 5 -0x04 8 0 19 8 -6 0
 10 6 0x22 8 0 -12 10 6 0x44 2 8 16 -8 0))

; *65 28 A LATIN CAPITAL LETTER A
    (65 (list 2 8 6 2 1 8 12 36 8 12 -36 3 2 2 8 -7 20 1 8 -34 0 2 8 53 -24 4 2 0))

; *66 25 B LATIN CAPITAL LETTER B
    (66 (list 2 8 6 2 1 0xA0 10 10 0x64 0xA8 2 0xA0 1 10 8 0x64 0xA8 8 0 -36 2 8 26 -2 0))

; *67 21 C LATIN CAPITAL LETTER C
    (67 (list 2 8 22 2 1 0x78 10 9 -0x62 8 0 18 10 9 -0x42 0x70 2 8 6 -38 0))

; *68 22 D LATIN CAPITAL LETTER D
    (68 (list 2 8 6 2 1 0x90 10 11 0x62 0xE4 10 11 0x02 0x98 8 0 -36 2 8 26 -2 0))

; *69 25 E LATIN CAPITAL LETTER E
    (69 (list 2 8 22 2 1 9 -16 0 0 36 16 0 0 0 2 8 -4 -16 1 0xC8 2 8 22 -22 0))

; *70 24 F LATIN CAPITAL LETTER F
    (70 (list 2 8 6 2 1 8 0 36 8 16 0 2 8 -16 -16 1 8 16 0 2 8 6 -22 0))

; *71 25 G LATIN CAPITAL LETTER G
    (71 (list 2 8 20 22 1 0x60 8 0 -20 0xA8 10 10 -0x62 8 0 16 10 10 -0x42 0xA0 2 8 6 -38 0))

; *72 29 H LATIN CAPITAL LETTER H
    (72 (list 2 8 6 2 1 8 0 36 2 8 0 -16 1 8 20 0 2 8 0 16 1 8 0 -36 2 8 6 -2 0))

; *73 13 I LATIN CAPITAL LETTER I
    (73 (list 2 8 6 2 1 8 0 36 2 8 6 -38 0))

; *74 17 J LATIN CAPITAL LETTER J
    (74 (list 2 8 6 2 1 0x40 10 8 0x62 8 0 28 2 8 6 -38 0))

; *75 37 K LATIN CAPITAL LETTER K
    (75 (list 2 8 6 2 1 8 0 36 2 8 20 0 1 8 -20 -22 3 10 2 8 77 85 4 10 3 2 1 8 25 -45 4 2
 2 8 6 -2 0))

; *76 16 L LATIN CAPITAL LETTER L
    (76 (list 2 8 6 38 1 8 0 -36 8 16 0 2 8 6 -2 0))

; *77 21 M LATIN CAPITAL LETTER M
    (77 (list 2 8 6 2 1 9 0 36 12 -20 12 20 0 -36 0 0 2 8 6 -2 0))

; *78 19 N LATIN CAPITAL LETTER N
    (78 (list 2 8 6 2 1 9 0 36 20 -36 0 36 0 0 2 8 6 -38 0))

; *79 22 O LATIN CAPITAL LETTER O
    (79 (list 2 8 6 12 1 8 0 16 10 10 -0x44 8 0 -16 10 10 -0x04 2 8 26 -12 0))

; *80 22 P LATIN CAPITAL LETTER P
    (80 (list 2 8 6 2 1 8 0 36 8 10 0 10 10 -0x24 8 -10 0 2 8 26 -18 0))

; *81 30 Q LATIN CAPITAL LETTER Q
    (81 (list 2 8 6 12 1 8 0 16 10 10 -0x44 8 0 -16 10 10 -0x04 2 8 14 -2 1 8 10 -8 2 8 6 -2 0))

; *82 28 R LATIN CAPITAL LETTER R
    (82 (list 2 8 6 2 1 8 0 36 8 10 0 10 10 -0x24 8 -10 0 2 0xC0 1 8 8 -16 2 8 6 -2 0))

; *83 37 S LATIN CAPITAL LETTER S
    (83 (list 2 8 24 36 1 12 -10 2 12 3 10 4 2 12 -18 -76 100 8 56 -28 12 -18 -76 -100 4 10
 3 2 12 -12 4 -18 2 8 26 -6 0))

; *84 19 T LATIN CAPITAL LETTER T
    (84 (list 2 8 16 2 1 8 0 36 2 0xA8 1 8 20 0 2 8 6 -38 0))

; *85 19 U LATIN CAPITAL LETTER U
    (85 (list 2 8 6 38 1 8 0 -26 10 10 0x44 8 0 26 2 8 6 -38 0))

; *86 16 V LATIN CAPITAL LETTER V
    (86 (list 2 8 6 38 1 8 12 -36 8 12 36 2 8 6 -38 0))

; *87 21 W LATIN CAPITAL LETTER W
    (87 (list 2 8 6 38 1 9 8 -36 8 24 8 -24 8 36 0 0 2 8 6 -38 0))

; *88 21 X LATIN CAPITAL LETTER X
    (88 (list 2 8 6 38 1 8 24 -36 2 8 0 36 1 8 -24 -36 2 8 30 -2 0))

; *89 22 Y LATIN CAPITAL LETTER Y
    (89 (list 2 8 6 38 1 8 12 -18 5 8 12 18 6 1 8 0 -18 2 8 18 -2 0))

; *90 19 Z LATIN CAPITAL LETTER Z
    (90 (list 2 8 6 38 1 9 20 0 -20 -36 20 0 0 0 2 8 6 -2 0))
; *91 19 [ LEFT SQUARE BRACKET = OPENING SQUARE BRACKET
    (91 (list 2 8 10 42 1 9 -4 0 0 -44 4 0 0 0 2 8 6 2 0))

; *92 13 \ REVERSE SOLIDUS = BACKSLASH
    (92 (list 2 8 6 38 1 8 16 -36 2 8 6 -2 0))

; *93 19 ] RIGHT SQUARE BRACKET = CLOSING SQUARE BRACKET
    (93 (list 2 8 6 42 1 9 4 0 0 -44 -4 0 0 0 2 8 10 2 0))

; *94 12 ^ CIRCUMFLEX ACCENT = SPACING CIRCUMFLEX
    (94 (list 2 8 6 48 1 0x62 0x6E 2 8 6 -48 0))

; *95 9 _ LOW LINE
    (95 (list 2 0xAC 1 8 44 0 2 0xA4 0))

; *96 13 ` GRAVE ACCENT = SPACING GRAVE
    (96 (list 2 8 6 54 1 8 8 -6 2 8 6 -48 0))

; *97 22 a
    (97 (list 2 8 8 26 1 0x70 10 7 -0x22 8 0 -17 0xA8 10 6 -0x64 0xA0 2 8 6 -14 0))

; *98 22 b
    (98 (list 2 8 6 38 1 8 0 -36 0x90 10 7 0x62 0xA4 10 7 0x02 0x98 2 8 22 -26 0))

; *99 19 c
    (99 (list 2 8 18 2 1 0x58 10 7 -0x62 0xA4 10 7 -0x42 0x50 2 8 6 -26 0))

; *100 22 d
    (100 (list 2 8 22 38 1 8 0 -36 0x98 10 7 -0x62 0xA4 10 7 -0x42 0x90 2 8 6 -26 0))

; *101 22 e
    (101 (list 2 8 22 2 1 0xA8 10 6 -0x62 0xA4 10 8 -0x44 0x4C 8 -16 0 2 8 22 -14 0))

; *102 20 f
    (102 (list 2 8 10 2 1 8 0 28 10 8 -0x42 2 0xCA 1 0xC0 2 8 6 -26 0))

; *103 26 g
    (103 (list 2 8 8 -10 1 0x70 10 7 0x62 8 0 29 0x98 10 7 0x22 0xAC 10 7 0x42 0x90 2 8 6 -2 0))

; *104 23 h
    (104 (list 2 8 6 2 1 8 0 36 2 0xCC 1 0x90 10 7 -0x22 8 0 -17 2 8 6 -2 0))

; *105 17 i
    (105 (list 2 8 6 2 1 8 0 24 2 0xA4 1 0x24 2 8 6 -38 0))

; *106 20 j
    (106 (list 2 8 6 -10 1 10 8 0x62 8 0 28 2 0xA4 1 0x24 2 8 6 -38 0))

; *107 29 k
    (107 (list 2 8 6 2 1 8 0 36 2 8 16 -16 1 8 -16 -8 2 8 8 4 1 8 8 -16 2 8 6 -2 0))

; *108 16 l
    (108 (list 2 8 10 2 1 10 4 -0x62 8 0 32 2 8 10 -38 0))

; *109 28 m
    (109 (list 2 8 6 2 1 8 0 24 8 17 0 10 7 -0x22 8 0 -17 2 0xC8 1 8 0 24 2 8 18 -26 0))

; *110 20 n
    (110 (list 2 8 6 2 1 8 0 24 0x90 10 7 -0x22 8 0 -17 2 8 6 -2 0))

; *111 18 o
    (111 (list 2 8 6 18 1 10 8 -0x44 0x8C 10 8 -0x04 0x84 2 8 22 -18 0))

; *112 22 p
    (112 (list 2 8 6 -10 1 8 0 36 0x90 10 7 -0x22 0xAC 10 7 -0x02 0x98 2 8 22 -2 0))

; *113 22 q
    (113 (list 2 8 22 -10 1 8 0 36 0x98 10 7 0x22 0xAC 10 7 0x42 0x90 2 8 6 -2 0))

; *114 15 r
    (114 (list 2 8 6 2 1 8 0 24 0xC0 0x4C 2 8 6 -22 0))

; *115 33 s
    (115 (list 2 8 20 24 1 12 -9 2 12 3 10 12 -27 -91 100 8 110 -53 12 -22 -95 -100 12 -110
 20 -18 4 10 2 8 22 -4 0))

; *116 19 t
    (116 (list 2 8 10 2 1 8 0 36 2 8 -4 -12 1 0xC0 2 8 6 -26 0))

; *117 20 u
    (117 (list 2 8 6 26 1 8 0 -17 10 7 0x42 0x90 8 0 24 2 8 6 -26 0))

; *118 16 v
    (118 (list 2 8 6 26 1 8 8 -24 8 8 24 2 8 6 -26 0))

; *119 21 w
    (119 (list 2 8 6 26 1 9 6 -24 6 16 6 -16 6 24 0 0 2 8 6 -26 0))

; *120 21 x
    (120 (list 2 8 6 2 1 8 16 24 2 8 -16 0 1 8 16 -24 2 8 6 -2 0))

; *121 22 y
    (121 (list 2 8 6 -10 1 0x40 8 12 36 2 8 -16 0 1 8 8 -24 2 8 14 -2 0))

; *122 19 z
    (122 (list 2 8 6 26 1 9 16 0 -16 -24 16 0 0 0 2 8 6 -2 0))

; *123 26 { LEFT CURLY BRACKET = OPENING CURLY BRACKET
    (123 (list 2 8 14 -2 1 12 -4 5 -45 0xD4 10 4 0x02 10 4 0x62 0xD4 12 4 5 -45 2 8 6 -42 0))

; *124 13 | VERTICAL LINE = VERTICAL BAR
    (124 (list 2 8 6 60 1 8 0 -76 2 8 6 16 0))

; *125 26 } RIGHT CURLY BRACKET = CLOSING CURLY BRACKET
    (125 (list 2 8 6 -2 1 12 4 5 45 0xD4 10 4 -0x42 10 4 -0x62 0xD4 12 -4 5 45 2 8 14 -42 0))

; *126 18 ~ TILDE
    (126 (list 2 8 6 20 1 12 8 0 -63 12 8 0 63 2 8 6 -20 0))

; *168 4  CYRILLIC CAPITAL LETTER IO
    (168 (list 7 0x45 5 2 8 -20 48 1 0x24 2 0xC0 1 0x2C 6 0))

; *192 24  CYRILLIC CAPITAL LETTER A
    (192 (list 2 8 6 2 1 8 12 36 8 12 -36 2 8 -20 10 1 8 16 0 2 8 10 -12 0))

; *0411 27  CYRILLIC CAPITAL LETTER BE
    (193 (list 2 8 6 2 5 1 8 0 36 8 16 0 6 8 10 0 10 10 0x64 8 -10 0 2 8 26 -22 0))

; *0412 32  CYRILLIC CAPITAL LETTER VE
    (194 (list 2 5 8 6 2 1 8 0 36 8 10 0 10 8 -0x24 5 8 -10 0 6 10 10 -0x24 8 -10 0 6 2 8 32 0 0))

; *0413 16  CYRILLIC CAPITAL LETTER GHE
    (195 (list 2 8 6 2 1 8 0 36 8 16 0 2 8 6 -38 0))

; *0414 33  CYRILLIC CAPITAL LETTER DE
    (196 (list 2 8 6 -2 1 8 0 4 8 24 0 8 0 -4 2 8 -20 4 1 8 4 36 8 12 0 8 0 -36 2 8 10 -2 0))

; *0415 29  CYRILLIC CAPITAL LETTER IE
    (197 (list 2 8 6 2 5 1 8 0 36 8 16 0 2 8 -16 -16 1 8 12 0 6 8 16 0 2 8 6 -2 0))

; *0416 37  CYRILLIC CAPITAL LETTER ZHE
    (198 (list 2 8 6 2 1 8 10 20 5 8 -10 16 6 8 8 0 5 8 10 16 6 8 10 -20 2 8 -14 0 1 8 0 36 2
 8 20 -38 0))

; *0417 34  CYRILLIC CAPITAL LETTER ZE
    (199 (list 2 5 8 6 4 1 12 8 -2 15 10 10 0x64 2 8 -2 0 1 8 4 0 10 8 0x64 12 -10 -2 15 2 6
 8 30 0 0))

; *0418 19  CYRILLIC CAPITAL LETTER I
    (200 (list 2 8 6 38 1 8 0 -36 8 20 36 8 0 -36 2 8 6 -2 0))

; *0419 15  CYRILLIC CAPITAL LETTER SHORT I
    (201 (list 7 200 5 2 8 -20 46 1 8 8 0 2 6 0))

; *041A 4  CYRILLIC CAPITAL LETTER KA
    (202 (list 7 0x4B 0))

; *041B 19  CYRILLIC CAPITAL LETTER EL
    (203 (list 2 8 6 2 1 8 10 36 8 10 0 8 0 -36 2 8 6 -2 0))

; *041C 4  CYRILLIC CAPITAL LETTER EM
    (204 (list 7 0x4D 0))

; *041D 4  CYRILLIC CAPITAL LETTER EN
    (205 (list 7 0x48 0))

; *041E 4  CYRILLIC CAPITAL LETTER O
    (206 (list 7 0x4F 0))

; *041F 4  CYRILLIC CAPITAL LETTER PE
    (207 (list 2 8 6 2 1 8 0 36 8 20 0 8 0 -36 2 8 6 -2 0)) 

; *0420 4  CYRILLIC CAPITAL LETTER ER
    (208 (list 7 0x50 0))

; *0421 4  CYRILLIC CAPITAL LETTER ES
    (209 (list 7 0x43 0))

; *0422 4  CYRILLIC CAPITAL LETTER TE
    (210 (list 7 0x54 0))

; *0423 35  CYRILLIC CAPITAL LETTER U
    (211 (list 2 5 8 8 2 1 8 12 0 10 6 0x62 8 0 30 2 8 0 -20 1 8 -10 0 10 10 -0x62 8 0 10 6
 2 8 32 0 0))

; *0424 32  CYRILLIC CAPITAL LETTER EF
    (212 (list 2 8 20 2 5 1 8 0 36 2 8 -3 -6 1 10 11 0x24 8 6 0 10 11 0x64 8 -6 0 2 6 8 20 -2 0))

; *0425 4  CYRILLIC CAPITAL LETTER HA
    (213 (list 7 0x58 0))

; *0426 27  CYRILLIC CAPTIAL LETTER TSE
    (214 (list 2 8 6 38 1 8 0 -36 8 24 0 8 0 -8 2 8 -4 8 1 8 0 36 2 8 10 -38 0))

; *0427 29  CYRILLIC CAPITAL LETTER CHE
    (215 (list 2 8 26 2 5 1 8 0 36 2 8 0 -20 1 8 -10 0 10 10 -0x62 8 0 10 6 2 8 6 -2 0))

; *0428 27  CYRILLIC CAPITAL LETTER SHA
    (216 (list 2 8 6 38 1 8 0 -36 8 28 0 8 0 36 2 8 -14 0 1 8 0 -36 2 8 20 -2 0))

; *0429 19  CYRILLIC CAPITAL LETTER SHCHA
    (217 (list 7 216 2 8 -6 2 1 8 4 0 8 0 -8 2 8 6 6 0))

; *042A 16  CYRILLIC CAPITAL LETTER HARD SIGN
    (218 (list 2 8 6 38 1 8 8 0 2 8 -6 -38 7 220 0))

; *042B 30  CYRILLIC CAPITAL LETTER YERU
    (219 (list 2 8 6 38 1 8 0 -36 8 6 0 10 10 0x64 8 -6 0 2 8 24 -20 1 8 0 36 2 8 6 -38 0))

; *042C 22  CYRILLIC CAPITAL LETTER SOFT SIGN
    (220 (list 2 8 6 38 1 8 0 -36 8 10 0 10 10 0x64 8 -10 0 2 8 26 -22 0))

; *042D 35  CYRILLIC CAPITAL LETTER E
    (221 (list 2 5 8 6 2 1 8 10 0 10 10 0x62 8 0 16 10 10 0x02 8 -10 0 2 8 8 -16 1 8 12 0 6 2
 8 32 0 0))

; *042E 40  CYRILLIC CAPITAL LETTER YU
    (222 (list 2 5 8 6 2 1 8 0 36 2 8 0 -16 1 8 12 0 2 8 0 8 1 8 0 -20 10 8 0x44 8 0 20 10 8
 0x04 2 6 8 40 0 0))

; *042F 32  CYRILLIC CAPITAL LETTER YA
    (223 (list 2 5 8 6 2 1 8 10 16 10 10 -0x64 8 10 0 8 0 -36 2 8 0 16 1 8 -10 0 6 2 8 32 0 0))

; *0430 36  CYRILLIC SMALL LETTER A
    (224 (list 2 5 8 28 2 1 10 6 -0x62 8 0 18 8 -10 0 10 6 0x22 8 0 -12 10 6 0x42 8 4 0 10 6
 0x62 6 2 8 34 0 0))

; *0431 18  CYRILLIC SMALL LETTER BE
    (225 (list 7 0x6F 5 2 8 -6 38 1 8 -16 0 8 12 -13 2 6 0))

; *0432 21  CYRILLIC SMALL LETTER VE
    (226 (list 7 0x6F 5 2 8 -22 18 1 8 0 15 10 5 -0x45 8 -5 -5 2 6 0))

; *0433 31  CYRILLIC SMALL LETTER GHE
    (227 (list 2 5 8 7 24 1 12 8 2 -20 12 2 -8 -100 8 -9 -6 12 4 -10 100 12 8 2 15 6 2 8 26 0 0))

; *0434 21  CYRILLIC SMALL LETTER DE
    (228 (list 7 0x6F 5 2 8 -18 38 1 8 6 0 10 6 -0x22 8 0 -14 2 6 0))

; *0435 4  CYRILLIC SMALL LETTER IE
    (229 (list 7 0x65 0))

; *0436 37  CYRILLIC SMALL LETTER ZHE
    (230 (list 2 8 6 2 1 8 8 12 5 8 -8 12 6 8 8 0 5 8 8 12 6 8 8 -12 2 8 -12 0 1 8 0 24 2 8
 18 -26 0))

; *0437 31  CYRILLIC SMALL LETTER ZE
    (231 (list 2 5 8 6 4 1 12 8 -2 20 10 6 0x64 5 10 6 0x64 12 -8 -2 20 6 8 -4 0 2 6 8 26 0 0))

; *0438 22  CYRILLIC SMALL LETTER I
    (232 (list 2 8 6 26 1 8 0 -18 10 6 0x42 8 10 0 8 0 24 2 8 6 -26 0))

; *0439 14  CYRILLIC SMALL LETTER SHORT I
    (233 (list 7 232 5 2 8 -18 38 1 8 8 0 6 0))

; *043A 29  CYRILLIC SMALL LETTER KA
    (234 (list 2 8 6 2 1 8 0 24 2 8 0 -16 1 8 16 16 2 8 -10 -10 1 8 10 -14 2 8 6 -2 0))

; *043B 19  CYRILLIC SMALL LETTER EL
    (235 (list 2 8 6 2 1 8 8 24 8 8 0 8 0 -24 2 8 6 -2 0))

; *043C 22  CYRILLIC SMALL LETTER EM
    (236 (list 2 8 6 2 1 8 0 24 8 10 -12 8 10 12 8 0 -24 2 8 6 -2 0))

; *043D 29  CYRILLIC SMALL LETTER EN
    (237 (list 2 8 6 2 1 8 0 24 2 8 0 -12 1 8 16 0 2 8 0 12 1 8 0 -24 2 8 6 -2 0))

; *043E 4  CYRILLIC SMALL LETTER O
    (238 (list 7 0x6F 0))

; *043F 22  CYRILLIC SMALL LETTER PE
    (239 (list 2 8 6 2 1 8 0 24 8 10 0 10 6 -0x22 8 0 -18 2 8 6 -2 0))

; *0440 28  CYRILLIC SMALL LETTER ER
    (240 (list 2 8 6 -10 1 8 0 36 8 10 0 10 6 -0x22 8 0 -12 10 6 -0x02 8 -10 0 2 8 22 -2 0))

; *0441 25  CYRILLIC SMALL LETTER ES
    (241 (list 2 8 18 26 1 8 -6 0 10 6 0x22 8 0 -12 10 6 0x42 8 6 0 2 8 6 -2 0))

; *0442 30  CYRILLIC SMALL LETTER TE
    (242 (list 2 8 6 2 1 8 0 24 8 18 0 10 6 -0x22 8 0 -18 2 8 -12 0 1 8 0 24 2 8 18 -26 0))

; *0443 33  CYRILLIC SMALL LETTER U
    (243 (list 2 8 6 26 1 8 0 -18 10 6 0x42 8 10 0 2 8 0 24 1 8 0 -30 10 6 -0x02 8 -8 0 2 8
 20 10 0))

; *0444 21  CYRILLIC SMALL LETTER EF
    (244 (list 2 8 18 -10 1 8 0 44 2 8 0 -8 1 10 12 0x20 2 8 18 -26 0))

; *0445 21  CYRILLIC SMALL LETTER HA
    (245 (list 2 8 6 2 1 8 16 24 2 8 -16 0 1 8 16 -24 2 8 6 -2 0))

; *0446 19  CYRILLIC SMALL LETTER TSE
    (246 (list 7 232 2 8 -6 2 1 8 4 0 8 0 -6 2 8 6 4 0))

; *0447 27  CYRILLIC SMALL LETTER CHE
    (247 (list 2 8 6 26 1 8 0 -6 10 6 0x42 8 10 0 2 8 0 12 1 8 0 -24 2 8 6 -2 0))

; *0448 30  CYRILLIC SMALL LETTER SHA
    (248 (list 2 8 6 26 1 8 0 -18 10 6 0x42 8 18 0 8 0 24 2 8 -12 0 1 8 0 -24 2 8 18 -2 0))

; *0449 19  CYRILLIC SMALL LETTER SHCHA
    (249 (list 7 248 2 8 -6 2 1 8 4 0 8 0 -6 2 8 6 4 0))

; *044A 16  CYRILLIC SMALL LETTER HARD SIGN
    (250 (list 2 8 6 26 1 8 4 0 2 8 -6 -26 7 252 0))

; *044B 30  CYRILLIC SMALL LETTER YERU
    (251 (list 2 8 6 26 1 8 0 -24 8 6 0 10 6 0x64 8 -6 0 2 8 20 -12 1 8 0 24 2 8 6 -26 0))

; *044C 22  CYRILLIC SMALL LETTER SOFT SIGN
    (252 (list 2 8 6 26 1 8 0 -24 8 10 0 10 6 0x64 8 -10 0 2 8 22 -14 0))

; *044D 33  CYRILLIC SMALL LETTER E
    (253 (list 2 8 6 2 1 8 10 0 10 6 0x62 8 0 12 10 6 0x02 8 -10 0 2 8 8 -12 1 8 8 0 2 8 6 -14 0))

; *044E 38  CYRILLIC SMALL LETTER YU
    (254 (list 2 8 6 2 1 8 0 24 2 8 0 -12 1 8 10 0 2 8 0 6 1 8 0 -12 10 6 0x44 8 0 12 10 6
 0x04 2 8 18 -20 0))

; *255 30  CYRILLIC SMALL LETTER YA
    (255 (list 2 8 6 2 1 8 8 12 2 8 8 -12 1 8 0 24 8 -10 0 10 6 0x24 8 10 0 2 8 6 -14 0))

; *184 4  CYRILLIC SMALL LETTER IO
    (184 (list 7 0x65 5 2 8 -20 36 1 0x24 2 0xC0 1 0x2C 6 0))

; *185 4  CYRILLIC NUMBER (No)
     (185 (list 2 8 6 2 1 9 0 36 20 -36 0 36 0 0 2 8 6 -38  2 8 2 33 1 10 5 -0x44 8 0 -8 10 5 -0x04 8 0 8 2 8 16 -33 0))

; 2,8,(6,2),1,024,2,0A4,1,8,(0,24),2,8,(6,-38),0
;    (33 (list 2 8 6 2  1 8 0 2  2 8 0 10  1 8 0 24  2 8 6 -38 0))
;    (33 (list (list 6:2 0:2) (list 0:10 0:24)  (list 6:-28)) )	; the last element is where to move in the end
;    (34 (list (list 155:93 156:94) (list 156:93 157:94) ) )
;    (34 (list 2 8 6 30 1 8 2 8 2 8 10 0 1 8 -2 -8 2 8 8 -30 0))
; *36,39,$ DOLLAR SIGN
; 2,8,(14,2),1,8,(0,36),2,8,(8,-6),1,12,(-8,2,16),028,12,(-3,-11,98),8,(10,-6),12,(-3,-11,-98),
; 028,12,(-8,2,-16),2,8,(22,-8),0
;    (36 (list 2 8 14 2 1 8 0 36 2 8 8 -6 1 12 -8 2 16 0x28 12 -3 -11 98 8 10 -6 12 -3 -11 -98  0x28 12 -8 2 -16 2 8 22 -8 0))
; *48,25,0 DIGIT ZERO
; 2,8,(10,4),1,13,(0,32,-32),(8,0,-64),(0,-32,-32),(-8,0,-64),(0,0),2,8,(18,-4),0
;    (48 (list 2 8 10 4 1 13 0 32 -32 8 0 -64 0 -32 -32 -8 0 -64 0 0 2 8 18 -4 0))
; *69,25,E LATIN CAPITAL LETTER E
; 2,8,(22,2),1,9,(-16,0),(0,36),(16,0),(0,0),2,8,(-4,-16),1,0C8,2,8,(22,-22),0
;    (69 (list 2 8 22 2 1 9 -16 0 0 36 16 0 0 0 2 8 -4 -16 1 8 -12 0 2 8 22 -22 0))
; *56,24,8 DIGIT EIGHT
; 2,8,(14,22),1,10,8,060,2,08A,1,10,8,-044,04C,10,8,-004,044,2,8,(22,-14),0
;    (56 (list 2 8 14 22 1 10 8 0x60 2 0x8A 1 10 8 -0x44 0x4C 10 8 -0x04 0x44 2 8 22 -14 0))
; *57,25,9 DIGIT NINE
; 2,8,(10,2),1,11,(108,0,0,18,062),0B4,10,8,004,04C,10,8,042,080,2,8,(6,-18),0
;    (57 (list 2 8 10 2 1 11 108 0 0 18 0x62 0xB4 10 8 0x04 0x4C 10 8 0x42 0x80 2 8 6 -18 0))
; Example with negative code for command 11. Check - in which side the shift goes?
; *167,28 
; 2,8,(6,6),1,11,(108,0,0,6,046),10,6,060,2,0C4,1,11,(0,147,0,6,-066),2,8,(6,-34),0
;    (244 (list 2 8 18 -10 1 8 0 44 2 8 0 -8 1 10 12 0x20 2 8 18 -26 0))	; ф 

))

/*******************************************/
/***	    FORM SUBROUTINES		 ***/
/*******************************************/
defun( numberToString (n)
  cond(
    (integerp(n), sprintf(nil, "%d", n))
    (numberp(n), sprintf(nil, "%g", n))
    (t, n)
  )
)

defun( AFn_getDesignUnits ()
 let((unitsInfo, units, precision)
  unitsInfo = axlDBGetDesignUnits()
  precision = cadr(unitsInfo)
  units = car(unitsInfo), when(units == "millimeters", units = "mm")
  list(units, precision)
))

defun( AFn_newTempFile (@optional id, name)
 let((tempFolder)
  id = id || "TEMP"
  name = name || gensym("allegroTemp")
  tempFolder = AFn_getTempDir()
  axlDMOpenFile(id, if(tempFolder && isDir(tempFolder), strcat(tempFolder "\\", name), name), "w")
))

defun( AFn_getTempDir ()
  cond(
    (axlGetVariable("TEMP") && !index(axlGetVariable("TEMP"), "~"), axlGetVariable("TEMP"))
    (getTempDir() && !index(getTempDir(), "~"), getTempDir())
    (isDir("c:\\temp"), "c:\\temp")
    (createDir("c:\\temp"), "c:\\temp")
    (t, ".")
  )
)

defun( AFn_formOpenFile (@optional name)
	AFn_newTempFile("FORM", name)
)

defun( AFn_formHeader (port @optional (formWidth 36), (title "My Form"))
  fprintf(port, "FILE_TYPE=FORM_DEFN VERSION=2\nFORM\nFIXED\nPORT %d 10\n", formWidth)
  fprintf(port, "HEADER \"%s\"\n", title)
  fprintf(port, "TILE\n")
)

defun( AFn_formEnd (port), fprintf(port, "ENDTILE\nENDFORM\n"))

defun( AFn_formPopupDefine (port, popupName @optional (popPairs '("")))
 let((pair, (popPairsStr ""), tdisplay, tdispatch)
  while(popPairs
    pair = car(popPairs), popPairs = cdr(popPairs)
    if(listp(pair) then tdisplay = car(pair), tdispatch = cadr(pair) else tdisplay = tdispatch = pair)
    when(numberp(tdisplay), tdisplay = numberToString(tdisplay))
    when(numberp(tdispatch), tdispatch = numberToString(tdispatch))
    sprintf(popPairsStr, "%s \"%s\" \"%s\"%s", popPairsStr, tdisplay, tdispatch, if(popPairs, ",", ""))
  )
  fprintf(port, "POPUP <%s>%s.\n", popupName, popPairsStr)
))

defun( AFn_formText (port, txt, x, lineNo @key info, fsize, options (label ""))
  info = AFn_formOptionalString("INFO", info)
  fsize = AFn_formSizeString(fsize)
  options = AFn_formOptionsString(options)
  fprintf(port, "TEXT \"%s\" %s\n\tTLOC %d %d\n%s%s%sENDTEXT\n", txt, label, x, lineNo, info, fsize, options)
)

defun( AFn_formPop (port, label, txt, x1, lineNo, enumset @key, title, x2, (titleLabel "") options)
  if(title then x2 = x2 || strlen(title) + x1 - 2, AFn_formText(port, title, x1, lineNo ?label titleLabel) else x2 = x1)
  options = AFn_formOptionsString(options)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tENUMSET %d\n\tPOP \"%s\"\n%sENDFIELD\n", label, x2, lineNo, enumset, txt, options)
)

defun( AFn_formColor (port, label, x, lineNo, w, h)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tCOLOR %d %d\nENDFIELD\n", label, x, lineNo, w, h)
)

defun( AFn_formChecklistItem (port, label, x, lineNo, displayTxt @key (radioLabel ""))
  unless(radioLabel == "", radioLabel = strcat(" \"", radioLabel, "\""))
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tCHECKLIST \"%s\"%s\nENDFIELD\n", label, x, lineNo, displayTxt, radioLabel)
)

defun( AFn_formRealFillin (port, label, fillinWidth, fillinLength, x1, lineNo
  @key title, fillInX, (titleLabel ""), minVal, maxVal, value, decimalPlaces, pop, units, options)
  if(title then
    fillInX = fillInX || strlen(title) + x1 - 2
    AFn_formText(port, title, x1, lineNo, ?label titleLabel)
   else fillInX = x1
  )
  if(minVal then sprintf(minVal, "\tMIN %L\n", minVal) else minVal = "")
  if(maxVal then sprintf(maxVal, "\tMAX %L\n", maxVal) else maxVal = "")
  if(value then sprintf(value, "\tVALUE %L\n", value) else value = "")
  sprintf(decimalPlaces, "\tDECIMAL %d\n", decimalPlaces || cadr(axlDBGetDesignUnits()))
  pop = AFn_formOptionalString("POP", pop)
  options = AFn_formOptionsString(options)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tREALFILLIN %d %d\n%s%s%s%s%s%sENDFIELD\n",
    label, fillInX, lineNo, fillinWidth, fillinLength, options, minVal, maxVal, value, decimalPlaces, pop)
  when(units
    AFn_formText(port, units, fillInX + fillinWidth + if(pop == "", 2, 5), lineNo, ?label strcat(label, "Units"))
  )
)

defun( AFn_formIntSlideBar (port, label, fillinWidth, fillinLength, x1, lineNo, minVal, maxVal
    @key title, fillInX, (titleLabel ""), value)
  if(title then
    fillInX = fillInX || strlen(title) + x1 - 2
    AFn_formText(port, title, x1, lineNo ?label titleLabel)
   else fillInX = x1
  )
  if(value then sprintf(value, "\tVALUE %L\n", value) else value = "")
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tINTSLIDEBAR %d %d\n\tMIN %d\n\tMAX %d\n%sENDFIELD\n"
    label, fillInX, lineNo, fillinWidth, fillinLength, minVal, maxVal, value)
)

defun( AFn_formStrFillin (port, label, fillinWidth, fillinLength, x1, lineNo
  @key, title, x2, (titleLabel "") pop, fsize, options)
  if(title then x2 = x2 || strlen(title) + x1 - 2, AFn_formText(port, title, x1, lineNo ?label titleLabel) else x2 = x1)
  pop = AFn_formOptionalString("POP", pop)
  fsize = AFn_formSizeString(fsize)
  options = AFn_formOptionsString(options)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tSTRFILLIN %d %d\n%s%s%sENDFIELD\n", label, x2, lineNo, fillinWidth, fillinLength, fsize, options, pop)
)

defun( AFn_formSetLayerFields (form, classField, subclassField, subcolourField @optional class, subclass)
 let((activeLayer, activeClass, n)
  activeLayer = parseString(axlDBControl('activeLayer), "/")
  activeClass = car(activeLayer)
  unless(class, class = activeClass)
  n = listnindex(axlGetParam("paramLayerGroup") ->groupMembers, upperCase(class)) + 1
  when(n, axlFormSetField(form, classField, sprintf(nil, "%d", n)))
  unless(subclass, subclass = cadr(activeLayer))
  axlBuildSubclassPopup(form, subclassField, class)
  axlFormSetField(form, subclassField, subclass)
  AFn_formSetLayerSubColour(form, subcolourField, strcat(class, "/", subclass))
))

defun( AFn_formLayerSubColour (form, classField, subclassField, subcolourField @optional toggle)
 let((class, subclass, layer)
  class = AFn_formInterpretClassPopField(axlFormGetField(form, classField))
  subclass = axlFormGetField(form, subclassField)
  layer = strcat(class, "/", subclass)
  when(toggle, axlVisibleLayer(layer, !axlIsVisibleLayer(layer)), axlVisibleUpdate(t))
  AFn_formSetLayerSubColour(form, subcolourField, layer)
))

defun( AFn_formInterpretClassPopField (class)
 let((n)
  n = readstring(class)
  when(numberp(n), class = nth(n - 1, axlGetParam("paramLayerGroup") ->groupMembers))
  class
))

defun( AFn_formSetLayerSubColour (form, field, layer)
  axlFormSetField(form, field, if(axlIsLayer(layer) && axlIsVisibleLayer(layer), axlLayerGet(layer) ->color, 'black))
)

;Create a Thumbnail on a form:
defun( AFn_formThumbnail (port, label, x, lineNo, w, h @key (bitmap "") options)
 let(((fieldName "THUMBNAIL"))
  unless(bitmap == "", sprintf(fieldName, "THUMBNAIL %s", bitmap))
  options = AFn_formOptionsString(options)
  fprintf(port, "FIELD %s\n\t%s\n\tFLOC %d %d\n\tFSIZE %d %d\n%sENDFIELD\n", label, fieldName, x, lineNo, w, h, options)
; FIELD label
;	THUMBNAIL [bitmapFile]
;	FLOC x lineNo
;	FSIZE w h
;	[OPTIONS STRETCH]
; ENDFIELD 
))

/****************************************************************/
/*		Form String creation functions			*/
/****************************************************************/

defun( AFn_formOptionsString (options)
  when(listp(options), options = buildString(options, " "))
  unless(options == "", options = strcat("\tOPTIONS ", options, "\n"))
  options
)

defun( AFn_formSizeString (fsize)
  cond(
    ((fsize == "") || !fsize, "")
    (listp(fsize), sprintf(nil, "\tFSIZE %d %d\n", car(fsize), cadr(fsize)))
    (t, sprintf(nil, "\tFSIZE %s\n", fsize))
  )
)

defun( AFn_formOptionalString (fieldName, value)
  case(value, ("", ""), (nil, ""), (t, sprintf(nil, "\t%s %s\n", fieldName, value)))
)

