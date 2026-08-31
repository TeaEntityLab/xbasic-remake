'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged verion of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "packbox"
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
DECLARE FUNCTION XLONG make_box (XLONG homogeneous, XLONG spacing, XLONG expand, XLONG fill, XLONG padding)
DECLARE FUNCTION delete_event ()
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()

'usage: packbox num, where num is "which" 1, 2, or 3.
which = 1

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

'Sets the border width of the window.
    gtk_container_set_border_width (window, 10)

'We create a box to pack widgets into.  This is described in detail
'in the "packing" section. The box is not really visible, it
'is just used as a tool to arrange widgets.
'We create a vertical box (vbox) to pack the horizontal boxes into.
'This allows us to stack the horizontal boxes filled with buttons one
'on top of the other in this vbox.
    box1 = gtk_vbox_new ($$FALSE, 0)

'which example to show. These correspond to the pictures above. */

    SELECT CASE which
			CASE 1	:
'create a new label.
				text$ = "gtk_hbox_new (FALSE, 0)"
				label = gtk_label_new (&text$)

'Align the label to the left side.  We'll discuss this function and
'others in the section on Widget Attributes.
				gtk_misc_set_alignment (label, 0, 0)

'Pack the label into the vertical box (vbox box1).  Remember that
'widgets added to a vbox will be packed one on top of the other in
'order.
				gtk_box_pack_start (box1, label, $$FALSE, $$FALSE, 0)

'Show the label
				gtk_widget_show (label)

'Call our make box function - homogeneous = FALSE, spacing = 0,
'expand = FALSE, fill = FALSE, padding = 0
				box2 = make_box ($$FALSE, 0, $$FALSE, $$FALSE, 0)
				gtk_box_pack_start (box1, box2, $$FALSE, $$FALSE, 0)
				gtk_widget_show (box2)

'Call our make box function - homogeneous = FALSE, spacing = 0,
'expand = TRUE, fill = FALSE, padding = 0
				box2 = make_box ($$FALSE, 0, 1, $$FALSE, 0)
				gtk_box_pack_start (box1, box2, 0, 0, 0)
				gtk_widget_show (box2)

'Args are: homogeneous, spacing, expand, fill, padding
				box2 = make_box ($$FALSE, 0, 1, 1, 0)
				gtk_box_pack_start (box1, box2, 0, 0, 0)
				gtk_widget_show (box2)

'Creates a separator, we'll learn more about these later, but they are quite simple.
				separator = gtk_hseparator_new ()

'Pack the separator into the vbox. Remember each of these
'widgets is being packed into a vbox, so they'll be stacked vertically.
				gtk_box_pack_start (box1, separator, 0, 1, 5)
				gtk_widget_show (separator)

'Create another new label, and show it.
				text$ = "gtk_hbox_new (TRUE, 0)"
				label = gtk_label_new (&text$)
				gtk_misc_set_alignment (label, 0, 0)
				gtk_box_pack_start (box1, label, 0, 0, 0)
				gtk_widget_show (label)

'Args are: homogeneous, spacing, expand, fill, padding
				box2 = make_box (1, 0, 1, 0, 0)
				gtk_box_pack_start (box1, box2, 0, 0, 0)
				gtk_widget_show (box2)

'Args are: homogeneous, spacing, expand, fill, padding
				box2 = make_box (1, 0, 1, 1, 0)
				gtk_box_pack_start (box1, box2, 0, 0, 0)
				gtk_widget_show (box2)

'Another new separator.
				separator = gtk_hseparator_new ()
'The last 3 arguments to gtk_box_pack_start are: expand, fill, padding.
				gtk_box_pack_start (box1, separator, 0, 1, 5)
				gtk_widget_show (separator)
			CASE 2	:

'Create a new label, remember box1 is a vbox as created near the beginning of main()
				text$ = "gtk_hbox_new (FALSE, 10)"
				label = gtk_label_new (&text$)
				gtk_misc_set_alignment (label, 0, 0)
				gtk_box_pack_start (box1, label, 0, 0, 0)
				gtk_widget_show (label)

'Args are: homogeneous, spacing, expand, fill, padding
				box2 = make_box (0, 10, 1, 0, 0)
				gtk_box_pack_start (box1, box2, 0, 0, 0)
				gtk_widget_show (box2)

'Args are: homogeneous, spacing, expand, fill, padding
				box2 = make_box (0, 10, 1, 1, 0)
				gtk_box_pack_start (box1, box2, 0, 0, 0)
				gtk_widget_show (box2)

				separator = gtk_hseparator_new ()
'The last 3 arguments to gtk_box_pack_start are: expand, fill, padding.
				gtk_box_pack_start (box1, separator, 0, 1, 5)
				gtk_widget_show (separator)

				text$ = "gtk_hbox_new (FALSE, 0)"
				label = gtk_label_new (&text$)
				gtk_misc_set_alignment (label, 0, 0)
				gtk_box_pack_start (box1, label, 0, 0, 0)
				gtk_widget_show (label)

'Args are: homogeneous, spacing, expand, fill, padding
				box2 = make_box (0, 0, 1, 0, 10)
				gtk_box_pack_start (box1, box2, 0, 0, 0)
				gtk_widget_show (box2)

'Args are: homogeneous, spacing, expand, fill, padding
				box2 = make_box (0, 0, 1, 1, 10)
				gtk_box_pack_start (box1, box2, 0, 0, 0)
				gtk_widget_show (box2)

				separator = gtk_hseparator_new ()
'The last 3 arguments to gtk_box_pack_start are: expand, fill, padding.
				gtk_box_pack_start (box1, separator, 0, 1, 5)
				gtk_widget_show (separator)

			CASE 3	:

'This demonstrates the ability to use gtk_box_pack_end() to
'right justify widgets. First, we create a new box as before.
				box2 = make_box (0, 0, 0, 0, 0)

'Create the label that will be put at the end.
				text$ = "end"
				label = gtk_label_new (&text$)
'Pack it using gtk_box_pack_end(), so it is put on the right
'side of the hbox created in the make_box() call.
				gtk_box_pack_end (box2, label, 0, 0, 0)
'Show the label.
				gtk_widget_show (label)

'Pack box2 into box1 (the vbox remember ? :)
				gtk_box_pack_start (box1, box2, 0, 0, 0)
				gtk_widget_show (box2)

'A separator for the bottom.
				separator = gtk_hseparator_new ()
'This explicitly sets the separator to 400 pixels wide by 5 pixels
'high. This is so the hbox we created will also be 400 pixels wide,
'and the "end" label will be separated from the other labels in the
'hbox. Otherwise, all the widgets in the hbox would be packed as
'close together as possible.
				gtk_widget_set_size_request (separator, 400, 5)
'pack the separator into the vbox (box1) created near the start of main()
				gtk_box_pack_start (box1, separator, 0, 1, 5)
				gtk_widget_show (separator)

		END SELECT

'Create another new hbox.. remember we can use as many as we need!
    quitbox = gtk_hbox_new (0, 0)

'Our quit button.
    text$ = "Quit"
		button = gtk_button_new_with_label (&text$)

'Setup the signal to terminate the program when the button is clicked
		detailed_signal$ = "clicked"
    g_signal_connect_data (button, &detailed_signal$, &gtk_main_quit(), window, NULL, $$G_CONNECT_SWAPPED)
'Pack the button into the quitbox. The last 3 arguments to gtk_box_pack_start are:
'expand, fill, padding.
    gtk_box_pack_start (quitbox, button, 1, 0, 0)
'pack the quitbox into the vbox (box1)
    gtk_box_pack_start (box1, quitbox, 0, 0, 0)

'Pack the vbox (box1) which now contains all our widgets, into the main window.
    gtk_container_add (window, box1)

'And show everything left
    gtk_widget_show (button)
    gtk_widget_show (quitbox)

    gtk_widget_show (box1)
'Showing the window last so everything pops up at once.
    gtk_widget_show (window)

'All GTK applications must have a gtk_main(). Control ends here
'and waits for an event to occur (like a key press or mouse event).
    gtk_main ()
		a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' ######################
' #####  HelloGTK  #####
' ######################
'
'
'
FUNCTION make_box(XLONG homogeneous, XLONG spacing, XLONG expand, XLONG fill, XLONG padding)

'Create a new hbox with the appropriate homogeneous and spacing settings
    box = gtk_hbox_new (homogeneous, spacing)

'Create a series of buttons with the appropriate settings
    text$ = "gtk_box_pack"
		button = gtk_button_new_with_label (&text$)
    gtk_box_pack_start (box, button, expand, fill, padding)
    gtk_widget_show (button)

		text$ = "(box,"
    button = gtk_button_new_with_label (&text$)
    gtk_box_pack_start (box, button, expand, fill, padding)
    gtk_widget_show (button)

    text$ = "button,"
		button = gtk_button_new_with_label (&text$)
    gtk_box_pack_start (box, button, expand, fill, padding)
    gtk_widget_show (button)

'Create a button with the label depending on the value of expand.
    IF (expand = 1) THEN
	    text$ = "TRUE,"
			button = gtk_button_new_with_label (&text$)
    ELSE
			text$ = "FALSE,"
	    button = gtk_button_new_with_label (&text$)
    END IF

    gtk_box_pack_start (box, button, expand, fill, padding)
    gtk_widget_show (button)

'This is the same as the button creation for "expand" above, but uses the shorthand form.
    IF fill THEN
			fill$ = "TRUE,"
		ELSE
			fill$ = "FALSE,"
		END IF

		button = gtk_button_new_with_label (&fill$)
    gtk_box_pack_start (box, button, expand, &fill$, padding)
    gtk_widget_show (button)

    padstr$ = STRING$(padding)

    button = gtk_button_new_with_label (&padstr$)
    gtk_box_pack_start (box, button, expand, fill, padding)
    gtk_widget_show (button)

END FUNCTION box
'
' ##########################
' #####  delete_event  #####
' ##########################
'
'
'
FUNCTION delete_event ()

'If you return FALSE in the "delete_event" signal handler,
'GTK will emit the "destroy" signal. Returning TRUE means
'you don't want the window to be destroyed.
'This is useful for popping up 'are you sure you want to quit?' type dialogs.
    gtk_main_quit ()
'Change TRUE to FALSE and the main window will be destroyed with a "delete_event".
'    RETURN TRUE

END FUNCTION
END PROGRAM
