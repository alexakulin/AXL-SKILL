; SET_TARGET
; Set the selected net as a target in the first matchgroup in which it exists
; Other matchgroups are not changed
; Script wasn't checked for more than 1 matchgroup
; Author: akulin@pcbsoftware.com
;
; To load the script in Allegro Command line:
; skill load("set_target.il")
; funckey t tar
;
; To run the script:
; tar
;
; During use of the script, the CM window should be opened.
; First time running can switch the focus to the CM window, because of switching to "Relative Propagation" worksheet.
; Then the next runs will not switch to CM.

axlCmdRegister("tar" 'set_target_start)

procedure( set_target_start(  )
let( (tmp_file id string mg DesignName MGName NetName)
   DesignName = upperCase(axlCurrentDesign())
   axlMsgPut(list("TAR - Open CM window, go to PCB and Pick the net to set as a target ---------------------------------------------->" 3))
   id = ashOne("nets")	; the user selects one net
   axlClearSelSet()	; clear the net selected by ashOne
   NetName = id->name
   mg=car(car(id->rpd))	; take the first match group to which this net belongs (change car to cadr if you need 2nd mg)
;   MGName = strcat( mg->name, "_", sprintf( string, "%d", length(mg->groupMembers)) , "_")
   MGName = sprintf( string, "%s_%d_", mg->name, length(mg->groupMembers) )
   tmp_file = axlDMOpenFile("ALLEGRO_SCRIPT", "tmp", "w")
   fprintf(tmp_file "QtSignal m_domainSelector WS_Electrical itemSelectionChanged Net Routing \"Relative Propagation Delay\"\n")
   fprintf(tmp_file "QtSignal m_domainSelector WS_Electrical itemClicked Net Routing \"Relative Propagation Delay\"\n")
   fprintf(tmp_file "QtSignal CCMViewHost30 Relative_Propagation_Delay_WorksheetView30 ContextMenu (%s.%s.%s,RELATIVE_PROPAGATION_DELAY_CNS)\n", DesignName, MGName, NetName)
   fprintf(tmp_file "QtSignal superMenu RMBMenu Triggered \"Set as target\"\n")
   axlDMClose(tmp_file)
   axlShellPost("replay tmp")
   printf("Set as target: %s, %s, %s\n", DesignName, MGName, NetName)
;   if( isFile( "tmp.scr") then deleteFile("tmp.scr"))		; this doesn't work because of delay with ShellPost.
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

(defun ashShow () (ashSelect 'axlShowObject))
(defun _ashSelectDebug () (ashSelect '_axlDebugObjList))


; --------  arg1 = spacing Cset name, arg2 = Netclassname, arg3 = Physical Cset name
procedure( ns_map_cset2netclass( arg1 arg2 arg3)
let((nc_domains)
  nc_domains = '(spacing physical)
  axlNetClassCreate(arg2 nc_domains)

  fprintf(tmp_file "cm startTransaction ( Design \"%s\" ) ( \"Net Class\" \"%s\" ) TS_DEFER\n" axlCurrentDesign() arg2)
  fprintf(tmp_file "cm add ( \"Net Class\" \"%s\" ) to ( \"Spacing CSet\" \"%s\" )\n" arg2 arg1)
  fprintf(tmp_file "cm commitTransaction ( Design \"%s\" ) ( \"Net Class\" \"%s\" ) TS_DEFER\n" axlCurrentDesign() arg2)

  fprintf(tmp_file "cm startTransaction ( Design \"%s\" ) ( \"Net Class\" \"%s\" ) TS_DEFER\n" axlCurrentDesign() arg2)
  fprintf(tmp_file "cm add ( \"Net Class\" \"%s\" ) to ( \"Physical CSet\" \"%s\" )\n" arg2 arg3)
  fprintf(tmp_file "cm commitTransaction ( Design \"%s\" ) ( \"Net Class\" \"%s\" ) TS_DEFER\n" axlCurrentDesign() arg2)

 )
); end procedure

;  --------  arg1 = col_name, arg2 = row_name, arg3 = Spacing Cset name
procedure( ns_netclass2netclass( arg1 arg2 arg3)
let((nc_domains)
  nc_domains = '(spacing physical)
  axlNetClassCreate(arg2 nc_domains)
  fprintf(tmp_file "cm create \"Net Class-Class\" ( Design \"%s\" ) \"%s:%s\" \"%s\" \"%s\"\n" axlCurrentDesign() arg1 arg2 arg2 arg1)
  fprintf(tmp_file "cm startTransaction ( Design \"%s\" ) ( \"Net Class-Class\" \"%s:%s\" ) TS_DEFER\n" axlCurrentDesign() arg1 arg2)
  fprintf(tmp_file "cm add ( \"Net Class-Class\" \"%s:%s\" ) to ( \"Spacing CSet\" \"%s\" )\n" arg1 arg2 arg3)
  fprintf(tmp_file "cm commitTransaction ( Design \"%s\" ) ( \"Net Class-Class\" \"%s:%s\" ) TS_DEFER\n" axlCurrentDesign() arg1 arg2)
 )
); end procedure