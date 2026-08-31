'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "table"
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
DECLARE CFUNCTION callback (XLONG widget, XLONG data)
DECLARE CFUNCTION delete_event ()
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()
    gtk_init (argc, argv)

'Create a new window
    window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)

'Set the window title
    text$ = "Table"
		gtk_window_set_title (window, &text$)

'Set a handler for delete_event that immediately exits GTK.
    detailed_signal$ = "delete_event"
		g_signal_connect_data (window, &detailed_signal$, &delete_event(), NULL, NULL, 0)

'Sets the border width of the window.
    gtk_container_set_border_width (window, 20)

'Create a 2x2 table
    table = gtk_table_new (2, 2, 0)

'Put the table in the main window
    gtk_container_add (window, table)

'Create first button
    text$ = "button 1"
		button = gtk_button_new_with_label (&text$)

'When the button is clicked, we call the "callback" function
'with a pointer to "button 1" as its argument
detailed_signal$ = "clicked"
data1$ = "button 1"
    g_signal_connect_data (button, &detailed_signal$, &callback(), &data1$, NULL, 0)

'Insert button 1 into the upper left quadrant of the table
    gtk_table_attach_defaults (table, button, 0, 1, 0, 1)

    gtk_widget_show (button)

'Create second button
		text$ = "button 2"
    button = gtk_button_new_with_label (&text$)

'When the button is clicked, we call the "callback" function
'with a pointer to "button 2" as its argument
detailed_signal$ = "clicked"
data2$ = "button 2"
		g_signal_connect_data (button, &detailed_signal$, &callback(), &data2$, NULL, 0)

'Insert button 2 into the upper right quadrant of the table
    gtk_table_attach_defaults (table, button, 1, 2, 0, 1)

    gtk_widget_show (button)

'Create "Quit" button
		text$ = "Quit"
    button = gtk_button_new_with_label (&text$)

'When the button is clicked, we call the "delete_event" function and the program exits
detailed_signal$ = "clicked"
		g_signal_connect_data (button, &detailed_signal$, &delete_event(), NULL, NULL, 0)

'Insert the quit button into the both lower quadrants of the table
    gtk_table_attach_defaults (table, button, 0, 2, 1, 2)

    gtk_widget_show (button)

    gtk_widget_show (table)
    gtk_widget_show (window)

'All GTK applications must have a gtk_main(). Control ends here
'and waits for an event to occur (like a key press or mouse event).
    gtk_main ()
		a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' ###################
' #####  callback  #####
' ###################
'
'
'
CFUNCTION callback (widget, data)
text$ = "Hello again - " + CSTRING$(data) + " was pressed"
'g_print(&text$)
PRINT text$

END FUNCTION
'
' ##########################
' #####  delete_event  #####
' ##########################
'
'
'
CFUNCTION delete_event ()
	gtk_main_quit ()

END FUNCTION
END PROGRAM
