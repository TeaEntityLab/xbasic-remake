'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "progressbar"
VERSION "0.0.7"
'
	IMPORT  "xst"						' Standard library : required by most programs

	IMPORT  "gobject-2.0"
  IMPORT  "gio-2.0"
  IMPORT  "gdk-x11-2.0"

  IMPORT  "gtk-x11-2.0"
  IMPORT  "glib-2.0"
  IMPORT  "gmodule-2.0"
  IMPORT  "gdk_pixbuf-2.0"
'
TYPE PROGRESSDATA
  XLONG .window
  XLONG .pbar
  XLONG .timer
  XLONG .activity_mode
END TYPE

'
DECLARE FUNCTION Entry ()
DECLARE CFUNCTION XLONG progress_timeout (XLONG data)
DECLARE CFUNCTION toggle_show_text (XLONG widget, XLONG pdata)
DECLARE CFUNCTION toggle_activity_mode ( XLONG widget, XLONG pdata)
DECLARE CFUNCTION toggle_orientation (XLONG widget, XLONG pdata)
DECLARE CFUNCTION destroy_progress (XLONG widget, XLONG pdata)

'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()

'Allocate memory for the data that is passed to the callbacks
    SHARED PROGRESSDATA pdata

    gtk_init (argc, argv)

    pdata.window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)
    gtk_window_set_resizable (pdata.window, $$TRUE)

    detailed_signal$ = "destroy"
		g_signal_connect_data (pdata.window, &detailed_signal$, &destroy_progress(), &pdata, NULL, 0)
    gtk_window_set_title (pdata.window, &"GtkProgressBar")
    gtk_container_set_border_width (pdata.window, 0)

    vbox = gtk_vbox_new ($$FALSE, 5)
    gtk_container_set_border_width (vbox, 10)
    gtk_container_add (pdata.window, vbox)
    gtk_widget_show (vbox)

'Create a centering alignment object
    align = gtk_alignment_new (0.5, 0.5, 0, 0)
    gtk_box_pack_start (vbox, align, $$FALSE, $$FALSE, 5)
    gtk_widget_show (align)

'Create the GtkProgressBar
    pdata.pbar = gtk_progress_bar_new ()

    gtk_container_add (align, pdata.pbar)
    gtk_widget_show (pdata.pbar)

'Add a timer callback to update the value of the progress bar
    pdata.timer = gtk_timeout_add (100, &progress_timeout(), &pdata)

    separator = gtk_hseparator_new ()
    gtk_box_pack_start (vbox, separator, $$FALSE, $$FALSE, 0)
    gtk_widget_show (separator)

'rows, columns, homogeneous
    table = gtk_table_new (2, 3, $$FALSE)
    gtk_box_pack_start (vbox, table, $$FALSE, $$TRUE, 0)
    gtk_widget_show (table)

'Add a check button to select displaying of the trough text
		check = gtk_check_button_new_with_label (&"Show text")
    gtk_table_attach (table, check, 0, 1, 0, 1, $$GTK_EXPAND | $$GTK_FILL, $$GTK_EXPAND | $$GTK_FILL, 5, 5)
    detailed_signal$ = "clicked"
		g_signal_connect_data (check, &detailed_signal$, &toggle_show_text(), &pdata, NULL, 0)
    gtk_widget_show (check)

'Add a check button to toggle activity mode
		check = gtk_check_button_new_with_label (&"Activity mode")
    gtk_table_attach (table, check, 0, 1, 1, 2, $$GTK_EXPAND | $$GTK_FILL, $$GTK_EXPAND | $$GTK_FILL, 5, 5)
    detailed_signal$ = "clicked"
		g_signal_connect_data (check, &detailed_signal$, &toggle_activity_mode(), &pdata, NULL, 0)
    gtk_widget_show (check)

'Add a check button to toggle orientation
		check = gtk_check_button_new_with_label (&"Right to Left")
    gtk_table_attach (table, check, 0, 1, 2, 3, $$GTK_EXPAND | $$GTK_FILL, $$GTK_EXPAND | $$GTK_FILL, 5, 5)
    detailed_signal$ = "clicked"
		g_signal_connect_data (check, &detailed_signal$, &toggle_orientation(), &pdata, NULL, 0)
    gtk_widget_show (check)

'Add a button to exit the program
		button = gtk_button_new_with_label (&"close")
    detailed_signal$ = "clicked"
		g_signal_connect_data (button, &detailed_signal$, &gtk_widget_destroy(), pdata.window, NULL, $$G_CONNECT_SWAPPED)
    gtk_box_pack_start (vbox, button, $$FALSE, $$FALSE, 0)

    gtk_widget_show (button)

    gtk_widget_show (pdata.window)

    gtk_main ()

	a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' #################################
' #####  progress_timeout     #####
' #################################
'
'Update the value of the progress bar so that we get some movement
'
CFUNCTION progress_timeout (XLONG data)
	SHARED PROGRESSDATA pdata
	DOUBLE new_val
	PROGRESSDATA ppdata

  IF pdata.activity_mode THEN
    gtk_progress_bar_pulse (pdata.pbar)
  ELSE
'Calculate the value of the progress bar using the value range set in the adjustment object
    new_val = gtk_progress_bar_get_fraction (pdata.pbar) + 0.01
      IF (new_val > 1.0) THEN
				new_val = 0.0
'Set the new value
				gtk_progress_bar_set_fraction (pdata.pbar, new_val)
			END IF
  END IF
'As this is a timeout function, return TRUE so that it continues to get called
END FUNCTION $$TRUE
'
' ##############################
' #####  toggle_show_text  #####
' ##############################
'
'Callback that toggles the text display within the progress bar trough
'
CFUNCTION toggle_show_text ( XLONG widget, XLONG data)
  SHARED PROGRESSDATA pdata

	text = gtk_progress_bar_get_text (pdata.pbar)
  IF text THEN
		gtk_progress_bar_set_text (pdata.pbar, NULL)
  ELSE
		gtk_progress_bar_set_text (pdata.pbar, &"some text")
	END IF
END FUNCTION
'
' ##################################
' #####  toggle_activity_mode  #####
' ##################################
'
'Callback that toggles the activity mode of the progress bar
'
CFUNCTION toggle_activity_mode ( XLONG widget, XLONG data)
  SHARED PROGRESSDATA pdata

  pdata.activity_mode = NOT pdata.activity_mode
  IF pdata.activity_mode THEN
      gtk_progress_bar_pulse (pdata.pbar)
  ELSE
      gtk_progress_bar_set_fraction (pdata.pbar, 0.0)
	END IF
END FUNCTION
'
' ################################
' #####  toggle_orientation  #####
' ################################
'
'Callback that toggles the orientation of the progress bar
'
CFUNCTION toggle_orientation (XLONG widget, XLONG data)
  SHARED PROGRESSDATA pdata

	'XstCopyMemory(pdata, &ppdata, SIZE(PROGRESSDATA))

	SELECT CASE (gtk_progress_bar_get_orientation (pdata.pbar))
		CASE $$GTK_PROGRESS_LEFT_TO_RIGHT :
			gtk_progress_bar_set_orientation (pdata.pbar, $$GTK_PROGRESS_RIGHT_TO_LEFT)
		CASE $$GTK_PROGRESS_RIGHT_TO_LEFT	:
			gtk_progress_bar_set_orientation (pdata.pbar, $$GTK_PROGRESS_LEFT_TO_RIGHT)
	END SELECT

END FUNCTION
'
' ##############################
' #####  destroy_progress  #####
' ##############################
'
'Clean up allocated memory and remove the timer
'
CFUNCTION destroy_progress (XLONG widget, XLONG data)
	SHARED PROGRESSDATA pdata

    gtk_timeout_remove (pdata.timer)
    gtk_main_quit ()


END FUNCTION
END PROGRAM
