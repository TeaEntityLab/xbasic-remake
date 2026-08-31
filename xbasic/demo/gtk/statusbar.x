'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "statusbar"
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
DECLARE CFUNCTION push_item (XLONG widget, XLONG data)
DECLARE CFUNCTION pop_item (XLONG widget, XLONG data)

'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()

SHARED status_bar
SHARED count
	count = 0

    gtk_init (argc, argv)

'create a new window
    window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)
    gtk_widget_set_size_request (window, 200, 100)

		text$ = "GTK Statusbar Example"
		gtk_window_set_title (window, &text$)

		detailed_signal$ = "delete_event"
		g_signal_connect_data (window, &detailed_signal$, &gtk_main_quit(), NULL, NULL, 0)

    vbox = gtk_vbox_new ($$FALSE, 1)
    gtk_container_add (window, vbox)
    gtk_widget_show (vbox)

    status_bar = gtk_statusbar_new ()
    gtk_box_pack_start (vbox, status_bar, $$TRUE, $$TRUE, 0)
    gtk_widget_show (status_bar)

    text$ = "Statusbar example"
		context_id = gtk_statusbar_get_context_id(status_bar, &text$)

    text$ = "push item"
		button = gtk_button_new_with_label (&text$)

		detailed_signal$ = "clicked"
		g_signal_connect_data (button, &detailed_signal$, &push_item(), context_id, NULL, 0)

		gtk_box_pack_start (vbox, button, $$TRUE, $$TRUE, 2)
    gtk_widget_show (button)

    text$ = "pop last item"
		button = gtk_button_new_with_label (&text$)

		detailed_signal$ = "clicked"
		g_signal_connect_data (button, &detailed_signal$, &pop_item(), context_id, NULL, 0)
    gtk_box_pack_start (vbox, button, $$TRUE, $$TRUE, 2)
    gtk_widget_show (button)

'always display the window as the last step so it all splashes on the screen at once.
    gtk_widget_show (window)

    gtk_main ()

	a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' #######################
' #####  push_item  #####
' #######################
'
'
'
CFUNCTION push_item (XLONG widget, XLONG data)
  SHARED status_bar
	SHARED count

  buff$ = ""

	INC count
	buff$ = buff$ + "Item  " + STRING$(count)
  gtk_statusbar_push (status_bar, data, &buff$)

END FUNCTION

'
' ######################
' #####  pop_item  #####
' ######################
'
'
'
CFUNCTION pop_item (XLONG widget, XLONG data)
  SHARED status_bar
	SHARED count
	DEC count
	gtk_statusbar_pop (status_bar, data)

END FUNCTION
END PROGRAM
