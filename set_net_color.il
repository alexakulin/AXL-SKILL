; SET_NET_COLOR
; Set the color of the selected net
; Author: akulin@pcbsoftware.com
;
; To load the script in Allegro Command line:
; skill load("set_net_color.il")
; funckey n set_net_color
;
; To run the script:
; set_net_color
;
; Recommendation:
; Check-off the Capture setting: 
; 	Options - Preferences - More preferences - Design and Libraries - Enable Global Net ITC
; to avoid the multiple opened Capture pages with net selection
;
; Advantages of the script:
; - compact dialog box with convenient color selection
;
; History
; - remove the "general" cmdType from axlCmdRegister to avoid the problems with finishing the command

axlCmdRegister("set_net_color" 'set_net_color_start)

;; 
(defun snc_ashSelect (procFunc @optional _types _tprompt)
    "Select Allegro objects and call user provided function"
    (let (oldPopup objs)
	oldPopup  =
	      (axlUIPopupSet (axlUIPopupDefine nil 
				'(("Cancel" axlCancelEnterFun))))
	axlClearSelSet()
	(axlSetFindFilter ?enabled '("NOALL" "ALLTYPES" "AUTOFORM" "NAMEFORM") 
			  ?onButtons _types )
	if(procFunc then
	    (while (axlSelect)
	        (apply procFunc (list (axlGetSelSet))))
	else
	    (axlSelect ?prompt _tprompt)
	    obs = axlGetSelSet()
	)
	(axlUIPopupSet oldPopup)
	obs
))

;;
procedure( set_net_color_start(  )
let( (id NetName color_idx oldSetting mypath (CurSize 0.5) objects obj)
	oldSetting = axlGetVariable("allegro_no_xprobe")
	when( (oldSetting == nil)	oldSetting = " ")
	axlSetVariable("allegro_no_xprobe" "yes")		; set off the crossprobe to Capture
	mypath = axlPathStart(  list( -CurSize:0 0:CurSize CurSize:0 0:-CurSize -CurSize:0))
	axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)	
	objects = snc_ashSelect(nil '("clines" "pins" "shapes") "Pick the net or create the temp group")	; the user selects one or many objects (via the Temp group)
	when( objects
		when( (color_idx = axlCVFColorChooserDlg(0))
			color_idx = car( color_idx)
			foreach( obj objects
				id = obj->net		; take the net of the object
				when( id
					NetName = id->name
					axlCustomColorObject(id color_idx)		
					printf("Set net %s to color %d\n", NetName, color_idx )
				)
			)
		)
	)
	axlShell(sprintf(nil "scriptmode +i;enved;setwindow form.prfedit;FORM prfedit treelist  Xprobe Ui;FORM prfedit allegro_no_xprobe '%s';FORM prfedit done;scriptmode -i;setwindow pcb" oldSetting))
	axlClearSelSet()		; clear the object selected by ashOne
	axlClearDynamics()		; reset the cursor
  )
)


