'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "helloworld"
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
DECLARE FUNCTION HelloWorldGTK ()
DECLARE CFUNCTION hello ()
DECLARE CFUNCTION XLONG delete_event ()
DECLARE CFUNCTION destroy ()
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()
' Parse the file
	HelloWorldGTK()
	a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' ######################
' #####  HelloGTK  #####
' ######################
'
'
'
FUNCTION HelloWorldGTK ()

'This is called in all GTK applications. Arguments are parsed
'from the command line and are returned to the application.
    gtk_init(argc, argv)

'create a new window
    window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)

'When the window is given the "delete_event" signal (this is given
'by the window manager, usually by the "close" option, or on the
'titlebar), we ask it to call the delete_event () function
'as defined above. The data passed to the callback
'function is NULL and is ignored in the callback function.
detailed_signal$ = "delete_event"
    g_signal_connect_data (window, &detailed_signal$, &delete_event(), NULL, NULL, 0)

'Here we connect the "destroy" event to a signal handler.
'This event occurs when we call gtk_widget_destroy() on the window,
'or if we return FALSE in the "delete_event" callback. */
detailed_signal$ = "destroy"
		g_signal_connect_data (window, &detailed_signal$, &destroy(), NULL, NULL, 0)

'Sets the border width of the window.
    gtk_container_set_border_width (window, 10)

'Creates a new button with the label "Hello World". */
text$ = "Hello World"
    button = gtk_button_new_with_label (&text$)

'    /* When the button receives the "clicked" signal, it will call the
'     * function hello() passing it NULL as its argument.  The hello()
'     * function is defined above. */
detailed_signal$ = "clicked"
    g_signal_connect_data (button, &detailed_signal$, &hello(), NULL, NULL, 0)

'    /* This will cause the window to be destroyed by calling
'     * gtk_widget_destroy(window) when "clicked".  Again, the destroy
'     * signal could come from here, or the window manager. */
detailed_signal$ = "clicked"
		g_signal_connect_data (button, &detailed_signal$, &gtk_widget_destroy(), window, NULL, $$G_CONNECT_SWAPPED)

'    /* This packs the button into the window (a gtk container). */
    gtk_container_add (window, button)

'    /* The final step is to display this newly created widget. */
    gtk_widget_show (button)

'    /* and the window */
    gtk_widget_show (window)

'    /* All GTK applications must have a gtk_main(). Control ends here
'     * and waits for an event to occur (like a key press or
'     * mouse event). */
    gtk_main ()

END FUNCTION
'
' ###################
' #####  hello  #####
' ###################
'
'
'
CFUNCTION hello ()

text$ = "Hello World"
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

'If you return FALSE in the "delete_event" signal handler,
'GTK will emit the "destroy" signal. Returning TRUE means
'you don't want the window to be destroyed.
'This is useful for popping up 'are you sure you want to quit?'
'type dialogs.
text$ = "delete event occurred"
'    g_print (&text$)
	PRINT text$
'Change TRUE to FALSE and the main window will be destroyed with a "delete_event".
    RETURN $$FALSE
END FUNCTION
'
' #####################
' #####  destroy  #####
' #####################
'
'
'
CFUNCTION destroy ()
    gtk_main_quit ()

END FUNCTION
END PROGRAM
