'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "radiobuttons"
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
DECLARE FUNCTION Entry ()
DECLARE FUNCTION radiobuttons ()
DECLARE CFUNCTION XLONG close_application (XLONG widget, XLONG event, XLONG data)
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()
    radiobuttons()
		a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' ###########################
' #####  xpm_label_box  #####
' ###########################
'
'
'
FUNCTION radiobuttons ()

GTKOBJECT buttonobj
GTKWIDGET buttonwidget
'button = XLONGAT(&buttonobj)

    gtk_init (argc, argv)

    window = gtk_window_new (GTK_WINDOW_TOPLEVEL)

		detailed_signal$ = "delete_event"
    g_signal_connect_data (window, &detailed_signal$, &close_application(), NULL, NULL, 0)

		text$ = "radio buttons"
    gtk_window_set_title (window, &text$)
    gtk_container_set_border_width (window, 0)

    box1 = gtk_vbox_new (0, 0)
    gtk_container_add (window, box1)
    gtk_widget_show (box1)

    box2 = gtk_vbox_new (0, 10)
    gtk_container_set_border_width (box2, 10)
    gtk_box_pack_start (box1, box2, 1, 1, 0)
    gtk_widget_show (box2)

    text$ = "button1"
		button = gtk_radio_button_new_with_label (NULL, &text$)
    gtk_box_pack_start (box2, button, 1, 1, 0)
    gtk_widget_show (button)

    group = gtk_radio_button_get_group (button)
		text$ = "button2"
    button = gtk_radio_button_new_with_label (group, &text$)
    gtk_toggle_button_set_active (button, 1)
    gtk_box_pack_start (box2, button, 1, 1, 0)
    gtk_widget_show (button)

    text$ = "button3"
		button = gtk_radio_button_new_with_label_from_widget (button, &text$)
    gtk_box_pack_start (box2, button, 1, 1, 0)
    gtk_widget_show (button)

    separator = gtk_hseparator_new ()
    gtk_box_pack_start (box1, separator, 0, 1, 0)
    gtk_widget_show (separator)

    box2 = gtk_vbox_new (1, 10)
    gtk_container_set_border_width (box2, 10)
    gtk_box_pack_start (box1, box2, 0, 1, 0)
    gtk_widget_show (box2)

    text$ = "close"
		button = gtk_button_new_with_label (&text$)
    detailed_signal$ = "clicked"
		g_signal_connect_data (button, &detailed_signal$, &close_application(), window, NULL, $$G_CONNECT_SWAPPED)
    gtk_box_pack_start (box2, button, 1, 1, 0)

    gtk_widget_show (button)
    gtk_widget_show (window)

    gtk_main ()


END FUNCTION
'
' ###################
' #####  callback
' ###################
'
'
'
CFUNCTION close_application (widget, event, data)
	gtk_main_quit ()
END FUNCTION $$TRUE
END PROGRAM
