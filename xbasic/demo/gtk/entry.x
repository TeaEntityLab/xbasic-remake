'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "entry"
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
'
DECLARE FUNCTION Entry ()
DECLARE CFUNCTION entry_toggle_visibility (XLONG widget, XLONG entry)
DECLARE CFUNCTION enter_callback (XLONG widget, XLONG entry)
DECLARE CFUNCTION entry_toggle_editable (XLONG widget, XLONG entry)

'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()
	'SHARED

	GTKENTRY eentry

    gtk_init (argc, argv)

'create a new window
    window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)
    gtk_widget_set_size_request (window, 200, 100)
		gtk_window_set_title (window, &"GTK Entry")

		detailed_signal$ = "destroy"
		g_signal_connect_data (window, &detailed_signal$, &gtk_main_quit(), NULL, NULL, 0)
    detailed_signal$ = "delete_event"
		g_signal_connect_data (window, &detailed_signal$, &gtk_widget_destroy(), window, NULL, $$G_CONNECT_SWAPPED)

    vbox = gtk_vbox_new ($$FALSE, 0)
    gtk_container_add (window, vbox)
    gtk_widget_show (vbox)

    entry = gtk_entry_new ()
    gtk_entry_set_max_length (entry, 50)
    detailed_signal$ = "destroy"
		g_signal_connect_data (entry, &detailed_signal$, &enter_callback(), entry, NULL, 0)
		gtk_entry_set_text (entry, &"hello")

		XstCopyMemory(entry, &eentry, SIZE(GTKENTRY))
    tmp_pos = eentry.text_length
		gtk_editable_insert_text (entry, &" world", -1, &tmp_pos)
    gtk_editable_select_region (entry,	0, eentry.text_length)
    gtk_box_pack_start (vbox, entry, $$TRUE, $$TRUE, 0)
    gtk_widget_show (entry)

    hbox = gtk_hbox_new ($$FALSE, 0)
    gtk_container_add (vbox, hbox)
    gtk_widget_show (hbox)

		check1 = gtk_check_button_new_with_label (&"Editable")
    gtk_box_pack_start (hbox, check1, $$TRUE, $$TRUE, 0)

		detailed_signal$ = "toggled"
		g_signal_connect_data (check1, &detailed_signal$,	&entry_toggle_editable(), entry, NULL, 0)
    gtk_toggle_button_set_active (check1, $$TRUE)
    gtk_widget_show (check1)

		check2 = gtk_check_button_new_with_label (&"Visible")
    gtk_box_pack_start (hbox, check2, $$TRUE, $$TRUE, 0)
    detailed_signal$ = "toggled"
		g_signal_connect_data (check2, &detailed_signal$, &entry_toggle_visibility(), entry, NULL, 0)
    gtk_toggle_button_set_active (check2, $$TRUE)
    gtk_widget_show (check2)

    button = gtk_button_new_from_stock (&"gtk-close")

		detailed_signal$ = "clicked"
		g_signal_connect_data (button, &detailed_signal$, &gtk_main_quit(), window, NULL, $$G_CONNECT_SWAPPED)
    gtk_box_pack_start (vbox, button, $$TRUE, $$TRUE, 0)
    gtk_widget_show (button)

    gtk_widget_show (window)

    gtk_main()

	a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' #####################################
' #####  entry_toggle_visibility  #####
' #####################################
'
'
'
CFUNCTION entry_toggle_visibility (XLONG widget, XLONG entry)

	state = gtk_toggle_button_get_active(widget)
	gtk_entry_set_visibility (entry, state)


END FUNCTION
'
' ############################
' #####  enter_callback  #####
' ############################
'
'
'
CFUNCTION enter_callback (XLONG widget, XLONG entry)

	entry_text = gtk_entry_get_text (entry)
  PRINT "Entry contents: " + CSTRING$(entry_text)

END FUNCTION

'
' ###################################
' #####  entry_toggle_editable  #####
' ###################################
'
'
'
CFUNCTION entry_toggle_editable (XLONG widget, XLONG entry)

	state = gtk_toggle_button_get_active(widget)
	gtk_editable_set_editable (entry, state)

END FUNCTION
END PROGRAM
