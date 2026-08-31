'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "fixed"
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
DECLARE CFUNCTION move_button (XLONG widget, XLONG fixed )

'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()
SHARED x, y

  gtk_init (argc, argv)

'Create a new window
  window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)
  gtk_window_set_title (window, &"Fixed Container")

'Here we connect the "destroy" event to a signal handler
  g_signal_connect_data (window, &"destroy", &gtk_main_quit(), NULL, NULL, 0)

'Sets the border width of the window.
  gtk_container_set_border_width (window, 10)

'Create a Fixed Container
  fixed = gtk_fixed_new ()
  gtk_container_add (window, fixed)
  gtk_widget_show (fixed)

  FOR i = 1 TO  3
'Creates a new button with the label "Press me"
    button = gtk_button_new_with_label (&"Press me")

'When the button receives the "clicked" signal, it will call the
'function move_button() passing it the Fixed Container as its argument.
    g_signal_connect_data (button, &"clicked", &move_button(), fixed, NULL, 0)

'This packs the button into the fixed containers window.
    gtk_fixed_put (fixed, button, i*50, i*50)

'The final step is to display this newly created widget.
    gtk_widget_show (button)
  NEXT i

'Display the window
  gtk_widget_show (window)

'Enter the event loop
  gtk_main ()

	a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' #########################
' #####  move_button  #####
' #########################
'
'This callback function moves the button to a new position in the Fixed container.
'
CFUNCTION move_button (XLONG widget, XLONG fixed )
SHARED x, y
  x = (x + 30) MOD 300
  y = (y + 50) MOD 300
  gtk_fixed_move (fixed, widget, x, y)


END FUNCTION
END PROGRAM
