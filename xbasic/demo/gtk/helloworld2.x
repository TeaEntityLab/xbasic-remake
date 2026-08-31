'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "helloworld2"
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
DECLARE FUNCTION HelloWorldGTK2()
DECLARE CFUNCTION callback (XLONG widget, XLONG data)
DECLARE CFUNCTION XLONG delete_event ()
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()
	HelloWorldGTK2()
	a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' ######################
' #####  HelloGTK  #####
' ######################
'
'
'
FUNCTION HelloWorldGTK2()

'This is called in all GTK applications. Arguments are parsed
'from the command line and are returned to the application.
    gtk_init(argc, argv)

'create a new window
    window = gtk_window_new (GTK_WINDOW_TOPLEVEL)

'This is a new call, which just sets the title of our new window to "Hello Buttons!" */
text$ = "Hello Buttons!"
    gtk_window_set_title (window, &text$)

'When the window is given the "delete_event" signal (this is given
'by the window manager, usually by the "close" option, or on the
'titlebar), we ask it to call the delete_event () function
'as defined above. The data passed to the callback
'function is NULL and is ignored in the callback function.
detailed_signal$ = "delete_event"
    g_signal_connect_data (window, &detailed_signal$, &delete_event(), NULL, NULL, 0)

'Sets the border width of the window.
    gtk_container_set_border_width (window, 10)

'We create a box to pack widgets into.  This is described in detail
'in the "packing" section. The box is not really visible, it
'is just used as a tool to arrange widgets.
    box1 = gtk_hbox_new (0, 0)

'Put the box into the main window.
    gtk_container_add (window, box1)

'Creates a new button with the label "Button 1". */
text$ = "Button 1"
    button = gtk_button_new_with_label (&text$)

'Now when the button is clicked, we call the "callback" function with a pointer to "button 1" as its argument
detailed_signal$ = "clicked"
data1$ = "button 1"
		g_signal_connect_data (button, &detailed_signal$, &callback(), &data1$, NULL, 0)

'Instead of gtk_container_add, we pack this button into the invisible
'box, which has been packed into the window.
    gtk_box_pack_start (box1, button, 1, 1, 0)

'The final step is to display this newly created widget, this tells GTK that our
' preparation for this button is complete, and it can now be displayed.
    gtk_widget_show (button)

'Creates a new button with the label "Button 2". */
text$ = "Button 2"
    button = gtk_button_new_with_label (&text$)

'Now when the button is clicked, we call the "callback" function with a pointer to "button 1" as its argument
detailed_signal$ = "clicked"
data2$ = "button 2"
		g_signal_connect_data (button, &detailed_signal$, &callback(), &data2$, NULL, 0)

'Instead of gtk_container_add, we pack this button into the invisible
'box, which has been packed into the window.
    gtk_box_pack_start (box1, button, 1, 1, 0)

'The final step is to display this newly created widget, this tells GTK that our
' preparation for this button is complete, and it can now be displayed.
    gtk_widget_show (button)

    gtk_widget_show (box1)

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


END FUNCTION $$FALSE
END PROGRAM
