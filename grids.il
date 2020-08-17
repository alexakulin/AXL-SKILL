;============================================================================
;
; Program Name: grids.il
;
; Author:	Uri Chaplin, PCB Design Manager
;		chaplin_u@email.com
;		Modified by R. Haynie - 9/21/04
;		Modified by Ole Ejlersen - 06/09/10
;		Modified by Alexander Akulin - 15/08/20
;
; Tested on:	Allegro v15.1 RJH - V14.2 and 15.2
; Purpose:	This routine is a very simple utility that will change your current grids.
;           I have change
; Usage:	To run the routine within Allegro type: "grids".
; Of course you can change definitions for grids that you use.
; Size of this form to small, so you can place this form on not used toolbars.
;
; History:
;
;  1.0  01-March-04 UC	Created.
;  2.0  17-March-04 UC  Added feature to enable using different db units
;  2.1  21-March-04 UC  Improvements
;  2.2  21-Sept -04 RH  Modified the code to allow the user to add input specifically entering "1 1 1 1 1" for the etch layer.
;  2.3  09-june -10 OE reads current grid settings and adds radio button with this figure
;  2.4	15-Aug  -20 AA  Allowed to switch to "current" grid, and some cosmetic improvements
;============================================================================

defun( grids ()

; creates conversion factors for different db units
; -------------------------------------------------
;
units = car(axlDBGetDesignUnits())
	cond(
		(equal(units "microns") 	(conv_factor = 1000.00) );
		(equal(units "mils") 		(conv_factor = 100.00)  );
		(equal(units "inches") 		(conv_factor = 0.10)  );
		(equal(units "millimeters")   (conv_factor = 1.0) );
		(equal(units "centimeters")   (conv_factor = 0.1));
	) ; end of cond

	drain()
      _createForm_grids()
	gridsform = axlFormCreate( (gensym) gridsform_file nil 'grids_Action t nil)
	if(vers_ok then
		axlFormSetField(gridsform "ae7" t)
		axlFormSetField(gridsform "ne6" t)
;		axlFormSetFieldEditable(gridsform "ae7" nil)
;		axlFormSetFieldEditable(gridsform "ne6" nil)
	)
	axlUIWPerm(gridsform t)
	axlFormDisplay(gridsform)
;	axlUIWPrint(gridsform axlPPrint(units))
	deleteFile(gridsform_file)
); end of grids
;--------------------------------------------------------
; what to do on form actions
; --------------------------
defun( grids_Action (gridsform)
	cond(
		(equal(gridsform->curField "ne1") 	UC_grids_script_create(conv_factor/200) )
		(equal(gridsform->curField "ne2") 	UC_grids_script_create(conv_factor/100) )
		(equal(gridsform->curField "ne3") 	UC_grids_script_create(conv_factor/20) )
		(equal(gridsform->curField "ne4")   UC_grids_script_create(conv_factor/10) )
		(equal(gridsform->curField "ne5")	UC_grids_script_create(conv_factor/5) )
		(equal(gridsform->curField "ne6")	UC_grids_script_create(_grids_current_ne_grid) )
		(equal(gridsform->curField "ae1") 	UC_grids_script_create1(conv_factor/200) 	axlFormSetField(gridsform "ae6" nil) )
		(equal(gridsform->curField "ae2") 	UC_grids_script_create1(conv_factor/100) 	axlFormSetField(gridsform "ae6" nil) )
		(equal(gridsform->curField "ae3") 	UC_grids_script_create1(conv_factor/20) 	axlFormSetField(gridsform "ae6" nil) )
		(equal(gridsform->curField "ae4")   UC_grids_script_create1(conv_factor/10) 	axlFormSetField(gridsform "ae6" nil) )
		(equal(gridsform->curField "ae5")	UC_grids_script_create1(conv_factor/5) 		axlFormSetField(gridsform "ae6" nil) )
		(equal(gridsform->curField "ae7")	UC_grids_script_create1(_grids_current_ae_grid) axlFormSetField(gridsform "ae6" nil) )
		(equal(gridsform->curField "ae6")	UC_grids_script_create1(gridsform->curValue)
			axlFormSetField(gridsform "ae1" nil)
			axlFormSetField(gridsform "ae2" nil)
			axlFormSetField(gridsform "ae3" nil)
			axlFormSetField(gridsform "ae4" nil)
			axlFormSetField(gridsform "ae5" nil)
			axlFormSetField(gridsform "ae7" nil)
		)
	) ; end of cond
	deleteFile("grids.scr")
); end grids_Action
;--------------------------------------------------------



defun( UC_grids_script_create ( cur_grid )
	Script_File=outfile("grids.scr" "w")
      fprintf(Script_File "scriptmode +i\n")
      fprintf(Script_File "define grid \nsetwindow form.grid\n")
	fprintf(Script_File "FORM grid non_etch non_etch_x_grids %n \n" cur_grid)
	fprintf(Script_File "FORM grid non_etch non_etch_y_grids %n \n" cur_grid)
	fprintf(Script_File "FORM grid done\n")
	close(Script_File)
	axlShell("replay grids.scr")
); end UC_grids_script_create

defun( UC_grids_script_create1 ( cur_grid )
	printf("%L" cur_grid)

	Script_File=outfile("grids.scr" "w")
      fprintf(Script_File "scriptmode +i\n")
      fprintf(Script_File "define grid \nsetwindow form.grid\n")

	cond(
		(equal(symbolToString(type(cur_grid)) "string")
			fprintf(Script_File "FORM grid all_etch all_etch_x_grids %s \n" cur_grid)
			fprintf(Script_File "FORM grid all_etch all_etch_y_grids %s \n" cur_grid)

		)
		(t
			fprintf(Script_File "FORM grid all_etch all_etch_x_grids %n \n" cur_grid)
			fprintf(Script_File "FORM grid all_etch all_etch_y_grids %n \n" cur_grid)
		)
	)
		fprintf(Script_File "FORM grid done\n")
	close(Script_File)
	axlShell("replay grids.scr")
); end UC_grids_script_create

(defun _createForm_grids ()
	prog( ()
		vers = axlVersion('fullVersion)
		major = atof(nth(0 parseString(vers)))
		minor = atof(substring(nth(1 parseString(vers)) 2 strlen(nth(1 parseString(vers)))))
		vers_ok = nil
		if(major > 16.3 || (major > 16.2 && minor >= 9.0) then vers_ok=t)
		gridsform_file = "grids.form"
		gridsformp = outfile(gridsform_file "w")
   		fprintf(gridsformp "FILE_TYPE=FORM_DEFN VERSION=2\n")
   		fprintf(gridsformp "FORM\nFIXED\nPORT 64 3\nHEADER \"Grids\"\n\n")

		
   		fprintf(gridsformp "TILE\n")
		;-------------------------------------------------------------------------------------------------------
   		fprintf( gridsformp "FIELD ne1 \nFLOC  3 5 \nFGROUP \"Non-Etch Grid\"\nCHECKLIST \"%g\" \"radioLabel\"\nENDFIELD\n\n" conv_factor/200); conv_factor/200
   		fprintf( gridsformp "FIELD ne2 \nFLOC 13 5 \nFGROUP \"Non-Etch Grid\"\nCHECKLIST \"%g\" \"radioLabel\"\nENDFIELD\n\n" conv_factor/100); conv_factor/100
   		fprintf( gridsformp "FIELD ne3 \nFLOC 23 5 \nFGROUP \"Non-Etch Grid\"\nCHECKLIST \"%g\" \"radioLabel\"\nENDFIELD\n\n" conv_factor/20);  conv_factor/20
   		fprintf( gridsformp "FIELD ne4 \nFLOC 33 5 \nFGROUP \"Non-Etch Grid\"\nCHECKLIST \"%g\" \"radioLabel\"\nENDFIELD\n\n" conv_factor/10);  conv_factor/10
   		fprintf( gridsformp "FIELD ne5 \nFLOC 43 5 \nFGROUP \"Non-Etch Grid\"\nCHECKLIST \"%g\" \"radioLabel\"\nENDFIELD\n\n" conv_factor/5);   conv_factor/5
		if(vers_ok then
			_grids_current_ne_grid = axlDBGridGet("non-etch")->xMajor
			fprintf(gridsformp "TEXT \"Current\"\nTLOC 53 3\nENDTEXT\n")
			fprintf( gridsformp "FIELD ne6 \nFLOC 53 5 \nFGROUP \"Non-Etch Grid\"\nCHECKLIST \"%g\" \"radioLabel\"\nENDFIELD\n\n" _grids_current_ne_grid)
		else
			fprintf(gridsformp "TEXT \"Update to\"\nTLOC 53 3\nENDTEXT\n")
			fprintf( gridsformp "TEXT \"16.3s009+\"\nTLOC 53 5\nENDTEXT\n")
		)
		fprintf( gridsformp "GROUP \"Non-Etch Grid\"\nGLOC 1 1\nGSIZE 62 7\nENDGROUP\n")

		;-------------------------------------------------------------------------------------------------------
     	fprintf(gridsformp "\n")

		;-------------------------------------------------------------------------------------------------------
     	fprintf( gridsformp "FIELD ae1 \nFLOC  3 13 \nCHECKLIST \"%g\" \"radioLabel1\"\nENDFIELD\n\n" conv_factor/200 )
     	fprintf( gridsformp "FIELD ae2 \nFLOC 13 13 \nCHECKLIST \"%g\" \"radioLabel1\"\nENDFIELD\n\n" conv_factor/100 )
     	fprintf( gridsformp "FIELD ae3 \nFLOC 23 13 \nCHECKLIST \"%g\" \"radioLabel1\"\nENDFIELD\n\n" conv_factor/20  )
     	fprintf( gridsformp "FIELD ae4 \nFLOC 33 13 \nCHECKLIST \"%g\" \"radioLabel1\"\nENDFIELD\n\n" conv_factor/10  )
     	fprintf( gridsformp "FIELD ae5 \nFLOC 43 13 \nCHECKLIST \"%g\" \"radioLabel1\"\nENDFIELD\n\n" conv_factor/5   )
		if(vers_ok then
			_grids_current_ae_grid = axlDBGridGet("TOP")->xMajor
			fprintf(gridsformp "TEXT \"Current\"\nTLOC 53 11\nENDTEXT\n")
			fprintf( gridsformp "FIELD ae7 \nFLOC 53 13 \nCHECKLIST \"%g\" \"radioLabel1\"\nENDFIELD\n\n" _grids_current_ae_grid   )
		else
			fprintf(gridsformp "TEXT \"Update to\"\nTLOC 53 11\nENDTEXT\n")
			fprintf( gridsformp "TEXT \"16.3s009+\"\nTLOC 53 13\nENDTEXT\n")
		)
		fprintf( gridsformp "GROUP \"All Etch Grid\"\nGLOC 1 9\nGSIZE 62 8\nENDGROUP\n")
		;-------------------------------------------------------------------------------------------------------

		fprintf(gridsformp "TEXT \"Manual Input:\"\nTLOC 3 15\nENDTEXT\n")
		fprintf(gridsformp "FIELD ae6 \nFLOC 13 15 \nSTRFILLIN 33 20\nENDFIELD\n\n")
		fprintf( gridsformp "TEXT \"%s\"\nTLOC 50 15\nENDTEXT\n" axlPPrint(units))

		fprintf(gridsformp "\n")
     		fprintf(gridsformp "ENDTILE\n")
     		fprintf(gridsformp "\n")
     		fprintf(gridsformp "ENDFORM\n")
		close(gridsformp)
	); prog
); defun

;--------------------------------------------------------
; Registers grids as an 'Allegro' command
; --------------------------------------
axlCmdRegister( "grids" `grids)
