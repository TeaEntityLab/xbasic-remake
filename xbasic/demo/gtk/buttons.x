'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'and
'Source: "PyGTK 2.0 Tutorial" authors John Finlay
'(www.andrew.cmu.edu/user/skey/research_prev/checker/working%20now/gui/pygtk2tutorial/pygtk2tutorial/sec-Images.html)
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "buttons"
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
DECLARE CFUNCTION XLONG xpm_label_box (XLONG xpm_filename, XLONG label_text)
DECLARE CFUNCTION callback (XLONG widget, XLONG data)
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()
    gtk_init (argc, argv)

'Create a new window
    window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)

    text$ = "Pixmap'd Buttons!"
		gtk_window_set_title (window, &text$)

'It's a good idea to do this for all windows.
    detailed_signal$ = "destroy"
		g_signal_connect_data (window, &detailed_signal$, &gtk_main_quit(), NULL, NULL, 0)

    detailed_signal$ = "delete_event"
		g_signal_connect_data (window, &detailed_signal$, &gtk_main_quit(), NULL, NULL, 0)

'Sets the border width of the window.
    gtk_container_set_border_width (window, 10)

'Create a new button
    button = gtk_button_new ()

'Connect the "clicked" signal of the button to our callback
		detailed_signal$ = "clicked"
		data1$ = "cool button"
    g_signal_connect_data (button, &detailed_signal$, &callback(), &data1$, NULL, 0)

'This calls our box creating function
    filename$ = "info.xpm"
		filename$ = "soccerball.gif"
		filename$ = "important.tiff"
		filename$ = "goalie.gif"
		filename$ = "apple-red.png"
		text$ = "cool button"
		box = xpm_label_box (&filename$, &text$)

'Pack and show all our widgets
    gtk_widget_show (box)

    gtk_container_add (button, box)

    gtk_widget_show (button)

    gtk_container_add (window, button)

    gtk_widget_show (window)

'All GTK applications must have a gtk_main(). Control ends here
'and waits for an event to occur (like a key press or mouse event).
    gtk_main ()
		a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' ###########################
' #####  xpm_label_box  #####
' ###########################
'
'
'
CFUNCTION XLONG xpm_label_box (XLONG xpm_filename, XLONG label_text)
'Create box for image and label
    box = gtk_hbox_new (0, 0)
    gtk_container_set_border_width (box, 2)

'Now on to the image stuff
    image = gtk_image_new_from_file (xpm_filename)

'Create a label for the button
    label = gtk_label_new (label_text)

'Pack the image and label into the box
    gtk_box_pack_start (box, image, 0, 0, 3)
    gtk_box_pack_start (box, label, 0, 0, 3)

    gtk_widget_show (image)
    gtk_widget_show (label)


END FUNCTION box
'
' ###################
' #####  callback
' ###################
'
'
'
CFUNCTION callback (widget, data)
text$ = "Hello again - " + CSTRING$(data) + " was pressed"
'g_print(&text$)
PRINT text$
END FUNCTION
END PROGRAM
