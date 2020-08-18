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

axlCmdRegister("set_net_color" 'set_net_color_start ?cmdType "general")

procedure( set_net_color_start(  )
let( (id NetName color_idx)
	axlMsgPut(list("Set net color - Select color and then pick the net -------------->" 0))
	color_idx = axlCVFColorChooserDlg(0)
	when( color_idx
	   color_idx = car( color_idx)
	   id = ashOne("clines")	; the user selects one cline
	   axlClearSelSet()	; clear the object selected by ashOne
	   id = id->net		; take the net of the cline
		when( id
		   NetName = id->name
		   axlCustomColorObject(id color_idx)		;; BUG - when we call this function, the Capture opens the page with this net and selects the wire!
													; Check-off the Capture setting: Options - Preferences - More preferences - Design and Libraries - Enable Global Net ITC
													; to avoid the multiple opened Capture pages
		   printf("Set net %s to color %d\n", NetName, color_idx )
		)
	)
  )
)


;----------------------------------------------------------
; allow user to single object and return it
;	p = ashOne()

(defun ashOne (@optional types)
    "Select Allegro objects and call user provided function"
    (let (oldPopup)
	axlClearSelSet()
	(setq oldPopup 
	      (axlUIPopupSet (axlUIPopupDefine nil 
				'(("Cancel" axlCancelEnterFun)))))
	unless( types
	     types = "NOALLTYPES"
	)
	(axlSetFindFilter ?enabled '("NOALL" "ALLTYPES" "AUTOFORM" "NAMEFORM") 
			  ?onButtons types)
	(axlSelect)
	    (axlUIPopupSet oldPopup)
	car(axlGetSelSet())
	)
)

