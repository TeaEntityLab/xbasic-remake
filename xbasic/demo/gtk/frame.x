'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "frame"
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
'Initialise GTK
  gtk_init (argc, argv)

'Create a new window
  window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)
  gtk_window_set_title (window, &"Frame Example")

'Here we connect the "destroy" event to a signal handler
  g_signal_connect_data (window, &"destroy", &gtk_main_quit(), NULL, NULL, 0)

  gtk_widget_set_size_request (window, 300, 300)
'Sets the border width of the window.
  gtk_container_set_border_width (window, 10)

'Create a Frame
  frame = gtk_frame_new (NULL)
  gtk_container_add (window, frame)

'Set the frame's label
  gtk_frame_set_label (frame, &"GTK Frame Widget")

'Align the label at the right of the frame
  gtk_frame_set_label_align (frame, 1.0, 0.0)

'Set the style of the frame
  gtk_frame_set_shadow_type (frame, $$GTK_SHADOW_ETCHED_OUT)

  gtk_widget_show (frame)

'Display the window
  gtk_widget_show (window)

'Enter the event loop
  gtk_main ()

	a$ = INLINE$("Press ENTER to exit")

END FUNCTION
END PROGRAM
