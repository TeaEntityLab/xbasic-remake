'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "rulers"
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
'$$XSIZE = 600
'$$YSIZE = 400
'
DECLARE FUNCTION Entry ()
DECLARE CFUNCTION motion_notify_event (XLONG ruler, XLONG event, XLONG data)
DECLARE CFUNCTION XLONG close_application (XLONG widget, XLONG event, XLONG data)

'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()

'Initialize GTK and create the main window
    gtk_init (argc, argv)

    window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)

		detailed_signal$ = "delete_event"
		g_signal_connect_data (window, &detailed_signal$, &close_application(), NULL, NULL, 0)
    gtk_container_set_border_width (window, 10)

'Create a table for placing the ruler and the drawing area
    table = gtk_table_new (3, 2, $$FALSE)
    gtk_container_add (window, table)

    area = gtk_drawing_area_new ()
    gtk_widget_set_size_request (area, 600, 400)
    gtk_table_attach (table, area, 1, 2, 1, 2, $$GTK_EXPAND || $$GTK_FILL, $$GTK_FILL, 0, 0)
    gtk_widget_set_events (area, $$GDK_POINTER_MOTION_MASK || $$GDK_POINTER_MOTION_HINT_MASK)

'The horizontal ruler goes on top. As the mouse moves across the
'drawing area, a motion_notify_event is passed to the
'appropriate event handler for the ruler.
    hrule = gtk_hruler_new ()
    gtk_ruler_set_metric (hrule, $$GTK_PIXELS)
    gtk_ruler_set_range (hrule, 7, 13, 0, 20)

		detailed_signal$ = "motion_notify_event"
		g_signal_connect_data (area, &detailed_signal$, &motion_notify_event(), hrule, NULL, $$G_CONNECT_SWAPPED)
'		g_signal_connect_data (area, &detailed_signal$, &motion_notify_event(), hrule, NULL, 0)
    gtk_table_attach (table, hrule, 1, 2, 0, 1, $$GTK_EXPAND || $$GTK_SHRINK || $$GTK_FILL, $$GTK_FILL, 0, 0)

'The vertical ruler goes on the left. As the mouse moves across
'the drawing area, a motion_notify_event is passed to the
'appropriate event handler for the ruler.
    vrule = gtk_vruler_new ()
    gtk_ruler_set_metric (vrule, $$GTK_PIXELS)
    gtk_ruler_set_range (vrule, 0, 400, 10, 400)
    detailed_signal$ = "motion_notify_event"
		g_signal_connect_data (area, &detailed_signal$, &motion_notify_event(), vrule, NULL, $$G_CONNECT_SWAPPED)
'		g_signal_connect_data (area, &detailed_signal$, &motion_notify_event(), vrule, NULL, 0)
    gtk_table_attach (table, vrule, 0, 1, 1, 2, $$GTK_FILL, $$GTK_EXPAND || $$GTK_SHRINK || $$GTK_FILL, 0, 0)

'Now show everything
'    gtk_widget_show (area)
'    gtk_widget_show (hrule)
'    gtk_widget_show (vrule)
'    gtk_widget_show (table)
    gtk_widget_show_all (window)
    gtk_main ()

	a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' #######################################
' #####  motion_notify_event  #####
' #######################################
'
'
'
CFUNCTION motion_notify_event (XLONG ruler, XLONG event, XLONG data)
PRINT "HERE"


END FUNCTION
'
' #################################
' #####  close_application    #####
' #################################
'
'This routine gets control when the close button is clicked
'
CFUNCTION close_application (XLONG widget, XLONG event, XLONG data)
    gtk_main_quit ()
END FUNCTION $$FALSE
END PROGRAM
