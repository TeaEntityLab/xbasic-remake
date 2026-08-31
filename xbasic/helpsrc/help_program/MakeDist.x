'
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "MakeDist"
VERSION "6.3.16"
'
	IMPORT  "xst"
	IMPORT  "xui"
'
'
DECLARE FUNCTION  Entry ()
DECLARE FUNCTION  BuildDirectories ()
DECLARE FUNCTION  CopyBase ()
DECLARE FUNCTION  CopyDemo ()
DECLARE FUNCTION  CopyFile (s$)
DECLARE FUNCTION  CopyHelp ()
DECLARE FUNCTION  CopyHelpSrc ()
DECLARE FUNCTION  CopyImages ()
DECLARE FUNCTION  CopyImagesWin32 ()
DECLARE FUNCTION  CopyInclude ()
DECLARE FUNCTION  CopyLib ()
DECLARE FUNCTION  CopyShared ()
DECLARE FUNCTION  CopySrc ()
DECLARE FUNCTION  CopySrcBin ()
DECLARE FUNCTION  CopySrcLinux ()
DECLARE FUNCTION  CopyTemplates ()
DECLARE FUNCTION  CopyDemoGTK ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
'
FUNCTION  Entry ()
	SHARED failCount
	SHARED fileCount
	SHARED newBase$
	SHARED oldBase$

	XstClearConsole ()
	failCount = 0
	fileCount = 0

	error = XstGetCurrentDirectory (@directory$)
'
	IF (RIGHT$(directory$, 4) == $$PathSlash$ + "src") THEN
		error = XstChangeDirectory ("..")
		error = XstGetCurrentDirectory (@directory$)
	END IF
'
' An XBasic source directory should contain a 'makefile'
'
	filename$ = directory$ + $$PathSlash$ + "makefile"         ' win32
	error = XstGetFileAttributes (filename$, @attributes)
	IFZ attributes THEN
		filename$ = directory$ + $$PathSlash$ + "Makefile"       ' Linux
		error = XstGetFileAttributes (filename$, @attributes)
		IFZ attributes THEN
			GOSUB ErrorMessage
			RETURN
		END IF
	END IF
'
' An XBasic source directory will have a 'src' directory
'
	dirSrc$  = directory$ + $$PathSlash$ + "src"  + $$PathSlash$
	error = XstGetFileAttributes (dirSrc$, @attributes)
	IFZ (attributes AND $$FileDirectory) THEN
		GOSUB ErrorMessage
		RETURN
	END IF

	oldBase$ = directory$
	newBase$ = "/tmp/xbasic-6.3.16"

	error = BuildDirectories ()
	IF error THEN RETURN

	error = CopyBase ()
	IF error THEN RETURN
	error = CopySrcBin ()
	IF error THEN RETURN
	error = CopyDemo ()
	IF error THEN RETURN
	error = CopyHelp ()
	IF error THEN RETURN
	error = CopyHelpSrc ()
	IF error THEN RETURN
	error = CopyImages ()
	IF error THEN RETURN
	error = CopyImagesWin32 ()
	IF error THEN RETURN
	error = CopyInclude ()
	IF error THEN RETURN
	error = CopyLib ()
	IF error THEN RETURN
	error = CopyShared ()
	IF error THEN RETURN
	error = CopySrc ()
	IF error THEN RETURN
	error = CopySrcLinux ()
	IF error THEN RETURN
	error = CopyTemplates ()
	IF error THEN RETURN

	PRINT "Number of files    = "; fileCount
	PRINT "Number of failures = "; failCount

'-----------------------------------------------------------
'
'
' *****  ErrorMessage  *****
'
SUB ErrorMessage
	message$ = "[CreateHelp Error]\n"
	message$ = message$ + "The current directory:\n"
	message$ = message$ + directory$ + "\n"
	message$ = message$ + "is not a valid XBasic source directory.\n"
	message$ = message$ + "To run this program, XBasic should be started from a\n"
	message$ = message$ + "terminal session while in an XBasic source directory.\n"
	XuiMessage (message$)
END SUB

END FUNCTION
'
'
' #################################
' #####  BuildDirectories ()  #####
' #################################
'
FUNCTION  BuildDirectories ()
	SHARED oldBase$
	SHARED newBase$

	directory$ = newBase$
	error = XstGetFileAttributes (directory$, @attributes)
	IF (attributes == $$FileDirectory) THEN
		PRINT directory$
		string$ = INLINE$("Erase directory? (y/n)")
		IF (string$ != "y") THEN RETURN
		error = XstDeleteFile (directory$)
	END IF
	error = XstGetFileAttributes (directory$, @attributes)
	IF attributes THEN
		PRINT directory$
		PRINT "Directory already exists."
		RETURN $$TRUE
	END IF
	err = XstMakeDirectory (directory$)
	err = err OR XstGetFileAttributes (directory$, @attributes)

	err = err OR XstMakeDirectory (directory$ + "/demo")
	err = err OR XstMakeDirectory (directory$ + "/help")
	err = err OR XstMakeDirectory (directory$ + "/images")
	err = err OR XstMakeDirectory (directory$ + "/images/win32")
	err = err OR XstMakeDirectory (directory$ + "/include")
	err = err OR XstMakeDirectory (directory$ + "/include/win32")
	err = err OR XstMakeDirectory (directory$ + "/lib")
	err = err OR XstMakeDirectory (directory$ + "/templates")
	err = err OR XstMakeDirectory (directory$ + "/templates/win32")

	err = err OR XstMakeDirectory (directory$ + "/src")
	err = err OR XstMakeDirectory (directory$ + "/src/bin")
	err = err OR XstMakeDirectory (directory$ + "/src/bin/win32")
	err = err OR XstMakeDirectory (directory$ + "/src/shared")
	err = err OR XstMakeDirectory (directory$ + "/src/win32")
	err = err OR XstMakeDirectory (directory$ + "/src/win32/lib")

	err = err OR XstMakeDirectory (directory$ + "/src/helpsrc")
	err = err OR XstMakeDirectory (directory$ + "/src/helpsrc/help_text")
	err = err OR XstMakeDirectory (directory$ + "/src/helpsrc/help_program")

	IF err THEN
		PRINT "Error occured while making directories"
	END IF
	RETURN err

END FUNCTION
'
'
' #########################
' #####  CopyBase ()  #####
' #########################
'
FUNCTION  CopyBase ()
	SHARED subDir$

	subDir$ = ""

	CopyFile ("CHANGES")
	CopyFile ("COPYING")
	CopyFile ("COPYING_LIB")
	CopyFile ("INSTALL")
	CopyFile ("Makefile")
	CopyFile ("README.Linux")
	CopyFile ("xbasic.spec")

END FUNCTION
'
'
' #########################
' #####  CopyDemo ()  #####
' #########################
'
FUNCTION  CopyDemo ()
	SHARED subDir$

	subDir$ = "demo"

	CopyFile ("DrawScaled.x")
	CopyFile ("Kittedy.x")
	CopyFile ("aarray.x")
	CopyFile ("aback.x")
	CopyFile ("abuffer.x")
	CopyFile ("acgibin.x")
	CopyFile ("acharmap.x")
	CopyFile ("acircle.x")
	CopyFile ("aclear.x")
	CopyFile ("aclient.x")
	CopyFile ("acolors.win")
	CopyFile ("acolors.x")
	CopyFile ("acolumns.x")
	CopyFile ("acommand.x")
	CopyFile ("aconsole.x")
	CopyFile ("aconvert.x")
	CopyFile ("acrc32.x")
	CopyFile ("adata.x")
	CopyFile ("adatadim.x")
	CopyFile ("ademo.x")
	CopyFile ("adialog.x")
	CopyFile ("adrawing.x")
	CopyFile ("aeasy.x")
	CopyFile ("aedit.x")
	CopyFile ("aeditors.x")
	CopyFile ("afile.x")
	CopyFile ("afindall.x")
	CopyFile ("afirst.x")
	CopyFile ("aformat.x")
	CopyFile ("afuntype.x")
	CopyFile ("agraphic.x")
	CopyFile ("agrids.x")
	CopyFile ("ahello.x")
	CopyFile ("ahowdy.dec")
	CopyFile ("ahowdy.x")
	CopyFile ("ahtml.x")
	CopyFile ("aloha.x")
	CopyFile ("amakemap.x")
	CopyFile ("amath.x")
	CopyFile ("amemory.x")
	CopyFile ("amerge.x")
	CopyFile ("amodal.x")
	CopyFile ("anewlook.x")
	CopyFile ("api.x")
	CopyFile ("aprofile.x")
	CopyFile ("aquick.x")
	CopyFile ("arecord.x")
	CopyFile ("arecurse.x")
	CopyFile ("aredrawn.x")
	CopyFile ("arotate.x")
	CopyFile ("ascroll.x")
	CopyFile ("aserver.x")
	CopyFile ("ashell.x")
	CopyFile ("asortie.x")
	CopyFile ("asound.x")
	CopyFile ("aspread.x")
	CopyFile ("astring.x")
	CopyFile ("asystem.x")
	CopyFile ("asystime.x")
	CopyFile ("atask.x")
	CopyFile ("atcursor.x")
	CopyFile ("atimer.x")
	CopyFile ("atools.x")
	CopyFile ("atrim.x")
	CopyFile ("aunicode.x")
	CopyFile ("aviewbmp.x")
	CopyFile ("awarn.x")
	CopyFile ("awheel.x")
	CopyFile ("awindow.x")
	CopyFile ("awrite.x")
	CopyFile ("edit.x")
	CopyFile ("editors.x")
	CopyFile ("employee.dat")
	CopyFile ("employee.win")
	CopyFile ("gif.x")
	CopyFile ("gifview.x")
	CopyFile ("hello.x")
	CopyFile ("luigi.win")
	CopyFile ("qbtoxb.x")
	CopyFile ("query.win")
	CopyFile ("simple.win")
	CopyFile ("tcheckbx.x")
	CopyFile ("tcolor.x")
	CopyFile ("tcolors.x")
	CopyFile ("tdial2.x")
	CopyFile ("tdial3.x")
	CopyFile ("tdial4.x")
	CopyFile ("tdropbox.x")
	CopyFile ("tdropbut.x")
	CopyFile ("tfile.x")
	CopyFile ("tfont.x")
	CopyFile ("tlabel.x")
	CopyFile ("tlist.x")
	CopyFile ("tlist2.x")
	CopyFile ("tlistbox.x")
	CopyFile ("tlistbut.x")
	CopyFile ("tmenu.x")
	CopyFile ("tmenubar.x")
	CopyFile ("tmess1.x")
	CopyFile ("tmess2.x")
	CopyFile ("tmess3.x")
	CopyFile ("tmess4.x")
	CopyFile ("tpress.x")
	CopyFile ("tprog.x")
	CopyFile ("tpulldn.x")
	CopyFile ("tpush.x")
	CopyFile ("tradio.x")
	CopyFile ("tradiobx.x")
	CopyFile ("trange.x")
	CopyFile ("tscrollh.x")
	CopyFile ("tscrollv.x")
	CopyFile ("ttoggle.x")
	CopyFile ("ttxtarea.x")
	CopyFile ("ttxtline.x")
	CopyFile ("warning.x")
	CopyFile ("wviewbmp.x")
	CopyFile ("xgrids.x")
	CopyFile ("xitmain.win")
	CopyFile ("zap.x")

END FUNCTION
'
'
' #########################
' #####  CopyFile ()  #####
' #########################
'
FUNCTION  CopyFile (s$)
	SHARED failCount
	SHARED fileCount
	SHARED newBase$
	SHARED oldBase$
	SHARED subDir$

	INC fileCount

	IFZ s$ THEN
		PRINT "Failure copying, no file name: ", subDir$;"/"
		INC failCount
		RETURN
	END IF

	IF subDir$ THEN
		oldFilename$ = oldBase$ + "/" + subDir$ + "/" + s$
		newFilename$ = newBase$ + "/" + subDir$ + "/" + s$
	ELSE
		oldFilename$ = oldBase$ + "/" + s$
		newFilename$ = newBase$ + "/" + s$
	END IF
	error = XstCopyFile (oldFilename$, newFilename$)
	IF error THEN
		PRINT "Failure copying: ", subDir$, s$
		INC failCount
	END IF
	RETURN (error)

END FUNCTION
'
'
' #########################
' #####  CopyHelp ()  #####
' #########################
'
FUNCTION  CopyHelp ()
	SHARED subDir$

	subDir$ = "help"

	CopyFile ("amath.hlp")
	CopyFile ("changelog.hlp")
	CopyFile ("command.hlp")
	CopyFile ("index.hlp")
	CopyFile ("lang.hlp")
	CopyFile ("languagelist.hlp")
	CopyFile ("messagelist.hlp")
	CopyFile ("messages.hlp")
	CopyFile ("misc.hlp")
	CopyFile ("notes.hlp")
	CopyFile ("operator.hlp")
	CopyFile ("pde.hlp")
	CopyFile ("support.hlp")
	CopyFile ("xgr.hlp")
	CopyFile ("xst.hlp")
	CopyFile ("xui.hlp")

END FUNCTION
'
'
' ############################
' #####  CopyHelpSrc ()  #####
' ############################
'
FUNCTION  CopyHelpSrc ()
	SHARED subDir$

	subDir$ = "src/helpsrc"

	CopyFile ("help_text/lang.txt")
	CopyFile ("help_text/messages.txt")
	CopyFile ("help_text/misc.txt")

	CopyFile ("help_program/CreateHelp.x")
	CopyFile ("help_program/MakeDist.x")

END FUNCTION
'
'
' ###########################
' #####  CopyImages ()  #####
' ###########################
'
FUNCTION  CopyImages ()
	SHARED subDir$

	subDir$ = "images"

	CopyFile ("abort2.bmp")
	CopyFile ("all.cur")
	CopyFile ("all.msk")
	CopyFile ("apo00.gif")
	CopyFile ("arrow.cur")
	CopyFile ("arrow.msk")
	CopyFile ("assembly2.bmp")
	CopyFile ("call.bmp")
	CopyFile ("carrow.bmp")
	CopyFile ("cat0006s.gif")
	CopyFile ("ccross.bmp")
	CopyFile ("cew.bmp")
	CopyFile ("cinsert.bmp")
	CopyFile ("clearbp2.bmp")
	CopyFile ("cnesw.bmp")
	CopyFile ("cns.bmp")
	CopyFile ("cnsew.bmp")
	CopyFile ("cnwse.bmp")
	CopyFile ("continue2.bmp")
	CopyFile ("copy2.bmp")
	CopyFile ("cuparrow.bmp")
	CopyFile ("cut2.bmp")
	CopyFile ("cwait.bmp")
	CopyFile ("default.cur")
	CopyFile ("default.msk")
	CopyFile ("dn5x5.bmp")
	CopyFile ("dn7x7.bmp")
	CopyFile ("e.msk")
	CopyFile ("ew.cur")
	CopyFile ("ew.msk")
	CopyFile ("ewfat.cur")
	CopyFile ("ewfat.msk")
	CopyFile ("f8514oem.map")
	CopyFile ("find2.bmp")
	CopyFile ("fool.bmp")
	CopyFile ("frames2.bmp")
	CopyFile ("gifoid.gif")
	CopyFile ("icon_arrowdown.bmp")
	CopyFile ("icon_arrowup.bmp")
	CopyFile ("icon_assembly.bmp")
	CopyFile ("icon_breakpoint.bmp")
	CopyFile ("icon_breakpoints_clear.bmp")
	CopyFile ("icon_continue.bmp")
	CopyFile ("icon_copy.bmp")
	CopyFile ("icon_cut.bmp")
	CopyFile ("icon_cut_off.bmp")
	CopyFile ("icon_find.bmp")
	CopyFile ("icon_function_back.bmp")
	CopyFile ("icon_function_next.bmp")
	CopyFile ("icon_function_previous.bmp")
	CopyFile ("icon_function_prolog.bmp")
	CopyFile ("icon_help.bmp")
	CopyFile ("icon_kill.bmp")
	CopyFile ("icon_memory.bmp")
	CopyFile ("icon_new.bmp")
	CopyFile ("icon_open.bmp")
	CopyFile ("icon_paste.bmp")
	CopyFile ("icon_pause.bmp")
	CopyFile ("icon_registers.bmp")
	CopyFile ("icon_replace.bmp")
	CopyFile ("icon_save.bmp")
	CopyFile ("icon_saveplus.bmp")
	CopyFile ("icon_stack.bmp")
	CopyFile ("icon_start.bmp")
	CopyFile ("icon_step_cursor.bmp")
	CopyFile ("icon_step_global.bmp")
	CopyFile ("icon_step_local.bmp")
	CopyFile ("icon_step_out.bmp")
	CopyFile ("icon_stop.bmp")
	CopyFile ("icon_toolkit.bmp")
	CopyFile ("icon_variables.bmp")
	CopyFile ("icon_xred.bmp")
	CopyFile ("images.txt")
	CopyFile ("insert.cur")
	CopyFile ("insert.msk")
	CopyFile ("kill2.bmp")
	CopyFile ("load2.bmp")
	CopyFile ("mall.bmp")
	CopyFile ("marrow.bmp")
	CopyFile ("maxbox.bmp")
	CopyFile ("mcross.bmp")
	CopyFile ("mew.bmp")
	CopyFile ("minbox.bmp")
	CopyFile ("minsert.bmp")
	CopyFile ("mnesw.bmp")
	CopyFile ("mns.bmp")
	CopyFile ("mnsew.bmp")
	CopyFile ("mnwse.bmp")
	CopyFile ("muparrow.bmp")
	CopyFile ("mwait.bmp")
	CopyFile ("n.msk")
	CopyFile ("nesw.cur")
	CopyFile ("nesw.msk")
	CopyFile ("new2.bmp")
	CopyFile ("no.cur")
	CopyFile ("ns.cur")
	CopyFile ("ns.msk")
	CopyFile ("nsfat.cur")
	CopyFile ("nsfat.msk")
	CopyFile ("nwse.cur")
	CopyFile ("nwse.msk")
	CopyFile ("open2.bmp")
	CopyFile ("paste2.bmp")
	CopyFile ("pause2.bmp")
	CopyFile ("plus.cur")
	CopyFile ("plus.msk")
	CopyFile ("runtocurser2.bmp")
	CopyFile ("s.msk")
	CopyFile ("save2.bmp")
	CopyFile ("start2.bmp")
	CopyFile ("stepglobal2.bmp")
	CopyFile ("steplocal2.bmp")
	CopyFile ("sysbox.bmp")
	CopyFile ("t8514oem.map")
	CopyFile ("togglebp2.bmp")
	CopyFile ("toolkit2.bmp")
	CopyFile ("undo2.bmp")
	CopyFile ("variables2.bmp")
	CopyFile ("w.msk")
	CopyFile ("wait.cur")
	CopyFile ("wait.msk")
	CopyFile ("we.cur")
	CopyFile ("we.msk")
	CopyFile ("window.bmp")
	CopyFile ("window.px")
	CopyFile ("xabort.bmp")
	CopyFile ("xasm.bmp")
	CopyFile ("xcheckbx.bmp")
	CopyFile ("xclrbpts.bmp")
	CopyFile ("xcolor.bmp")
	CopyFile ("xcombo.bmp")
	CopyFile ("xcontin.bmp")
	CopyFile ("xdialog2.bmp")
	CopyFile ("xdialog3.bmp")
	CopyFile ("xdialog4.bmp")
	CopyFile ("xdropbox.bmp")
	CopyFile ("xdropbut.bmp")
	CopyFile ("xfile.bmp")
	CopyFile ("xfind.bmp")
	CopyFile ("xfont.bmp")
	CopyFile ("xframe.bmp")
	CopyFile ("xkill.bmp")
	CopyFile ("xlabel.bmp")
	CopyFile ("xlist2b.bmp")
	CopyFile ("xlistbox.bmp")
	CopyFile ("xlistbut.bmp")
	CopyFile ("xmenu.bmp")
	CopyFile ("xmenubar.bmp")
	CopyFile ("xmess1.bmp")
	CopyFile ("xmess2.bmp")
	CopyFile ("xmess3.bmp")
	CopyFile ("xmess4.bmp")
	CopyFile ("xpause.bmp")
	CopyFile ("xpress.bmp")
	CopyFile ("xprogres.bmp")
	CopyFile ("xpullist.bmp")
	CopyFile ("xpush.bmp")
	CopyFile ("xradio.bmp")
	CopyFile ("xradiobx.bmp")
	CopyFile ("xrange.bmp")
	CopyFile ("xreplace.bmp")
	CopyFile ("xsclist.bmp")
	CopyFile ("xscrollh.bmp")
	CopyFile ("xscrollv.bmp")
	CopyFile ("xstart.bmp")
	CopyFile ("xstepglo.bmp")
	CopyFile ("xsteploc.bmp")
	CopyFile ("xstop.bmp")
	CopyFile ("xtocurs.bmp")
	CopyFile ("xtogbpt.bmp")
	CopyFile ("xtogbptx.bmp")
	CopyFile ("xtoggle.bmp")
	CopyFile ("xtool.bmp")
	CopyFile ("xtoolkit.bmp")
	CopyFile ("xtxta3.bmp")
	CopyFile ("xtxta4.bmp")
	CopyFile ("xtxtarea.bmp")
	CopyFile ("xtxtline.bmp")
	CopyFile ("xvar.bmp")

END FUNCTION
'
'
' ################################
' #####  CopyImagesWin32 ()  #####
' ################################
'
FUNCTION  CopyImagesWin32 ()
	SHARED subDir$

	subDir$ = "images/win32"

 CopyFile ("alignlc.bmp")
 CopyFile ("alignll.bmp")
 CopyFile ("alignlr.bmp")
 CopyFile ("alignmc.bmp")
 CopyFile ("alignml.bmp")
 CopyFile ("alignmr.bmp")
 CopyFile ("alignuc.bmp")
 CopyFile ("alignul.bmp")
 CopyFile ("alignur.bmp")
 CopyFile ("e.cur")
 CopyFile ("indentb.bmp")
 CopyFile ("indentl.bmp")
 CopyFile ("indentr.bmp")
 CopyFile ("indentt.bmp")
 CopyFile ("justb.bmp")
 CopyFile ("justc.bmp")
 CopyFile ("justl.bmp")
 CopyFile ("justr.bmp")
 CopyFile ("n.cur")
 CopyFile ("s.cur")
 CopyFile ("timer.bmp")
 CopyFile ("w.cur")
 CopyFile ("window.ico")

END FUNCTION
'
'
' ############################
' #####  CopyInclude ()  #####
' ############################
'
FUNCTION  CopyInclude ()
	SHARED subDir$

	subDir$ = "include"

	CopyFile ("clib.dec")
	CopyFile ("elf32.dec")
	CopyFile ("gdi32.dec")
	CopyFile ("gdk-x11-2.0.dec")
	CopyFile ("gdk_pixbuf-2.0.dec")
	CopyFile ("gio-2.0.dec")
	CopyFile ("glib-2.0.dec")
	CopyFile ("gmodule-2.0.dec")
	CopyFile ("gobject-2.0.dec")
	CopyFile ("gtk-x11-2.0.dec")
	CopyFile ("kernel32.dec")
	CopyFile ("shell32.dec")
	CopyFile ("user32.dec")
	CopyFile ("winmm.dec")
	CopyFile ("wsock32.dec")
	CopyFile ("xbasic.dec")
	CopyFile ("xcm.dec")
	CopyFile ("xgr.dec")
	CopyFile ("xin.dec")
	CopyFile ("xlib.dec")
	CopyFile ("xma.dec")
	CopyFile ("xst.dec")
	CopyFile ("xui.dec")
	CopyFile ("xut.dec")
	CopyFile ("xutpde.dec")
	CopyFile ("xwin.dec")

END FUNCTION
'
'
' ########################
' #####  CopyLib ()  #####
' ########################
'
FUNCTION  CopyLib ()
	SHARED subDir$

	subDir$ = "lib"

	CopyFile ("advapi32.lib")
	CopyFile ("comdlg32.lib")
	CopyFile ("gdi32.lib")
	CopyFile ("kernel32.lib")
	CopyFile ("msvcrt.lib")
	CopyFile ("shell32.lib")
	CopyFile ("user32.lib")
	CopyFile ("winmm.lib")
	CopyFile ("winspool.lib")
	CopyFile ("wsock32.lib")
	CopyFile ("wst.lib")

END FUNCTION
'
'
' ###########################
' #####  CopyShared ()  #####
' ###########################
'
FUNCTION  CopyShared ()
	SHARED subDir$

	subDir$ = "src/shared"

	CopyFile ("xcm.dec")
	CopyFile ("xcm.x")
	CopyFile ("xdis.x")
	CopyFile ("xma.dec")
	CopyFile ("xma.x")
	CopyFile ("xui.dec")
	CopyFile ("xui.x")
	CopyFile ("xut.dec")
	CopyFile ("xut.x")
	CopyFile ("xutpde.dec")
	CopyFile ("xutpde.x")

END FUNCTION
'
'
' ########################
' #####  CopySrc ()  #####
' ########################
'
FUNCTION  CopySrc ()
	SHARED subDir$

	subDir$ = "src"

	CopyFile ("CHANGES")
	CopyFile ("Makefile")
	CopyFile ("xlabs")

END FUNCTION
'
'
' ###########################
' #####  CopySrcBin ()  #####
' ###########################
'
FUNCTION  CopySrcBin ()
	SHARED subDir$

	subDir$ = "src/bin"

	CopyFile ("libxb.a")
	CopyFile ("xb")

END FUNCTION
'
'
' #############################
' #####  CopySrcLinux ()  #####
' #############################
'
FUNCTION  CopySrcLinux ()
	SHARED subDir$

	subDir$ = "src/linux"

	CopyFile ("chkmem.c")
	CopyFile ("gdi32.dec")
	CopyFile ("gdi32.x")
	CopyFile ("kernel32.dec")
	CopyFile ("kernel32.x")
	CopyFile ("user32.dec")
	CopyFile ("user32.x")
	CopyFile ("xbiface.c")
	CopyFile ("xcol.x")
	CopyFile ("xgr.dec")
	CopyFile ("xgr.x")
	CopyFile ("xin.dec")
	CopyFile ("xin.x")
	CopyFile ("xit.x")
	CopyFile ("xrun.x")
	CopyFile ("xst.dec")
	CopyFile ("xst.x")

	CopyFile ("lib/appstart.s")
	CopyFile ("lib/xlib.s")
	CopyFile ("lib/xstart.s")
	CopyFile ("lib/xzzz.s")

END FUNCTION
'
'
' ###########################
' #####  CopyImages ()  #####
' ###########################
'
FUNCTION  CopyTemplates ()
	SHARED subDir$

	subDir$ = "templates"

	CopyFile ("code.xxx")
	CopyFile ("copx.bin")
	CopyFile ("create.xxx")
	CopyFile ("entry.xxx")
	CopyFile ("expire.xxx")
	CopyFile ("fonts.xxx")
	CopyFile ("gentry.xxx")
	CopyFile ("gprolog.xxx")
	CopyFile ("initgui.xxx")
	CopyFile ("initprog.xxx")
	CopyFile ("initwins.xxx")
	CopyFile ("intro.xxx")
	CopyFile ("message.xxx")
	CopyFile ("name.xxx")
	CopyFile ("prolog.bak")
	CopyFile ("prolog.xxx")
	CopyFile ("property.xxx")
	CopyFile ("templates.txt")
	CopyFile ("version.xxx")
	CopyFile ("xtool0.xxx")
	CopyFile ("xtool1.xxx")
	CopyFile ("xtool2.xxx")
	CopyFile ("xtoolkit.xxx")
	CopyFile ("zcharmap.bin")

	subDir$ = "templates/win32"

 CopyFile ("first.xxx")
 CopyFile ("xapp.xxx")
 CopyFile ("fonts.xxx")
 CopyFile ("xstart.xxx")
 CopyFile ("syslib.xxx")
 CopyFile ("win32api.xxx")
 CopyFile ("font.xxx")
 CopyFile ("title.xxx")
 CopyFile ("xdll.xxx")
 CopyFile ("start.xxx")

END FUNCTION
'
'
' ############################
' #####  CopyDemoGTK ()  #####
' ############################
'
FUNCTION  CopyDemoGTK ()
	SHARED subDir$

	subDir$ = "demo/gtk"

	CopyFile ("apple-red.png")
	CopyFile ("eventbox.x")
	CopyFile ("helloworld.x")
	CopyFile ("notebook.x")
	CopyFile ("rulers.x")
	CopyFile ("arrow.x")
	CopyFile ("fixed.x")
	CopyFile ("icon.png")
	CopyFile ("packbox.x")
	CopyFile ("soccerball.gif")
	CopyFile ("buttonbox.x")
	CopyFile ("frame.x")
	CopyFile ("important.tiff")
	CopyFile ("progressbar.x")
	CopyFile ("spinbutton.x")
	CopyFile ("buttons.x")
	CopyFile ("goalie.gif")
	CopyFile ("info.xpm")
	CopyFile ("radiobuttons.x")
	CopyFile ("statusbar.x")
	CopyFile ("entry.x")
	CopyFile ("helloworld2.x")
	CopyFile ("menu.x")
	CopyFile ("rangewidgets.x")
	CopyFile ("table.x")

END FUNCTION
END PROGRAM
