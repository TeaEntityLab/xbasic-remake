'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "arrow"
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
DECLARE FUNCTION XLONG create_arrow_button (XLONG arrow_type, XLONG shadow_type)

'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()

  gtk_init (argc, &argv)

'Create a new window
  window = gtk_window_new (GTK_WINDOW_TOPLEVEL)

  text$ = "Arrow Buttons"
	gtk_window_set_title (window, &text$)

'It's a good idea to do this for all windows.
  detailed_signal$ = "destroy"
	g_signal_connect_data (window, &detailed_signal$, &gtk_main_quit(), NULL, NULL, 0)

'Sets the border width of the window.
  gtk_container_set_border_width (window, 10)

'Create a box to hold the arrows/buttons
  box = gtk_hbox_new ($$FALSE, 0)
  gtk_container_set_border_width (box, 2)
  gtk_container_add (window, box)

'Pack and show all our widgets
  gtk_widget_show (box)

  button = create_arrow_button ($$GTK_ARROW_UP, $$GTK_SHADOW_IN)
  gtk_box_pack_start (box, button, $$FALSE, $$FALSE, 3)

  button = create_arrow_button ($$GTK_ARROW_DOWN, $$GTK_SHADOW_OUT)
  gtk_box_pack_start (box, button, $$FALSE, $$FALSE, 3)

  button = create_arrow_button ($$GTK_ARROW_LEFT, $$GTK_SHADOW_ETCHED_IN)
  gtk_box_pack_start (box, button, $$FALSE, $$FALSE, 3)

  button = create_arrow_button ($$GTK_ARROW_RIGHT, $$GTK_SHADOW_ETCHED_OUT)
  gtk_box_pack_start (box, button, $$FALSE, $$FALSE, 3)

  gtk_widget_show (window)

'Rest in gtk_main and wait for the fun to begin!
  gtk_main ()

	a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' #################################
' #####  create_arrow_button  #####
' #################################
'
'
'
FUNCTION create_arrow_button (XLONG arrow_type, XLONG shadow_type)
  button = gtk_button_new ()
  arrow = gtk_arrow_new (arrow_type, shadow_type)

  gtk_container_add (button, arrow)

  gtk_widget_show (button)
  gtk_widget_show (arrow)



END FUNCTION button
END PROGRAM
