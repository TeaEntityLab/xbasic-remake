'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "eventbox"
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
'
DECLARE FUNCTION Entry ()

'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()
    GTKWIDGET eevent_box

		gtk_init (argc, argv)

    window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)

    gtk_window_set_title (window, &"Event Box")

    g_signal_connect_data (window, &"destroy", &gtk_main_quit(), NULL, NULL, 0)

    gtk_container_set_border_width (window, 10)

'Create an EventBox and add it to our toplevel window

    event_box = gtk_event_box_new ()
    gtk_container_add (window, event_box)
    gtk_widget_show (event_box)

'Create a long label

    label = gtk_label_new (&"Click here to quit, quit, quit, quit, quit")
    gtk_container_add (event_box, label)
    gtk_widget_show (label)

'Clip it short.
    gtk_widget_set_size_request (label, 110, 20)

'And bind an action to it
    gtk_widget_set_events (event_box, $$GDK_BUTTON_PRESS_MASK)
    g_signal_connect_data (event_box, &"button_press_event", &gtk_main_quit(), NULL, NULL, 0)

'Yet one more thing you need an X window for ...

    gtk_widget_realize (event_box)

		XstCopyMemory(event_box, &eevent_box, SIZE(GTKWIDGET))
    gdk_window_set_cursor (eevent_box.window, gdk_cursor_new ($$GDK_HAND1))

    gtk_widget_show (window)

    gtk_main ()

	a$ = INLINE$("Press ENTER to exit")

END FUNCTION
END PROGRAM
