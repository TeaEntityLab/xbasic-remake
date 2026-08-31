'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "menu"
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
DECLARE CFUNCTION button_press (XLONG widget, XLONG event)
DECLARE CFUNCTION menuitem_response (XLONG widget, XLONG string)
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()
    SHARED button, menu

		DIM buf$[3]
		gtk_init (argc, argv)

'create a new window
    window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)
    gtk_widget_set_size_request (window, 200, 100)
    gtk_window_set_title (window, &"GTK Menu Test")
    g_signal_connect_data (window, &"delete_event", &gtk_main_quit(), NULL, NULL, 0)

'Init the menu-widget, and remember -- never gtk_show_widget() the menu widget!!
'This is the menu that holds the menu items, the one that
'will pop up when you click on the "Root Menu" in the app
    menu = gtk_menu_new ()
'Next we make a little loop that makes three menu-entries for "test-menu".
'Notice the call to gtk_menu_shell_append.  Here we are adding a list of
'menu items to our menu.  Normally, we'd also catch the "clicked"
'signal on each of the menu items and setup a callback for it,
'but it's omitted here to save space.
    FOR i = 0 TO 2
'Copy the names to the buf.
      buf$[i] = "Test-undermenu - " + STRING$(i)
'Create a new menu-item with a name...
      menu_items = gtk_menu_item_new_with_label (&buf$[i])
'...and add it to the menu.
      gtk_menu_shell_append (menu, menu_items)
'Do something interesting when the menuitem is selected
	    g_signal_connect_data (menu_items, &"activate", &menuitem_response(), &buf$[i], NULL, 0)
'Show the widget
      gtk_widget_show (menu_items)
    NEXT i

'This is the root menu, and will be the label
'displayed on the menu bar.  There won't be a signal handler attached,
'as it only pops up the rest of the menu when pressed.
    root_menu = gtk_menu_item_new_with_label (&"Root Menu")
    gtk_widget_show (root_menu)
'Now we specify that we want our newly created "menu" to be the menu
'for the "root menu"
    gtk_menu_item_set_submenu (root_menu, menu)

'A vbox to put a menu and a button in:
    vbox = gtk_vbox_new ($$FALSE, 0)
    gtk_container_add (window, vbox)
    gtk_widget_show (vbox)

'Create a menu-bar to hold the menus and add it to our main window
    menu_bar = gtk_menu_bar_new ()
    gtk_box_pack_start (vbox, menu_bar, $$FALSE, $$FALSE, 2)
    gtk_widget_show (menu_bar)

'Create a button to which to attach menu as a popup
    button = gtk_button_new_with_label (&"press or right click me")
    g_signal_connect_data (button, &"event", &button_press(), menu, NULL, $$G_CONNECT_SWAPPED)
    gtk_box_pack_end (vbox, button, $$TRUE, $$TRUE, 2)
    gtk_widget_show (button)

'And finally we append the menu-item to the menu-bar -- this is the
'"root" menu-item I have been raving about =)
    gtk_menu_shell_append (menu_bar, root_menu)

'always display the window as the last step so it all splashes on
'the screen at once.
    gtk_widget_show (window)

    gtk_main ()

	a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' ##########################
' #####  button_press  #####
' ##########################
'
'Respond to a button-press by posting a menu passed in as widget.
'Note that the "widget" argument is the menu being posted, NOT
'the button that was pressed.
'
CFUNCTION button_press ( XLONG widget, XLONG event)
	SHARED button, menu
	GDKEVENT eevent
	GDKEVENTBUTTON bevent

	XstCopyMemory(event, &eevent, SIZE(GDKEVENT))
PRINT "Event type no "	+ STRING$(eevent.type)
    IF (eevent.type = $$GDK_BUTTON_PRESS) THEN
      XstCopyMemory(event, &bevent, SIZE(GDKEVENTBUTTON))
      gtk_menu_popup (menu, NULL, NULL, NULL, NULL, &bevent.button, &bevent.time)
'Tell calling code that we have handled this event; the buck stops here.
      RETURN $$TRUE
    END IF

'Tell calling code that we have not handled this event; pass it on.
END FUNCTION $$FALSE
'
' ###############################
' #####  menuitem_response  #####
' ###############################
'
'Print a string when a menu item is selected
'
CFUNCTION menuitem_response (XLONG widget, XLONG string)
	PRINT CSTRING$(string)

END FUNCTION
END PROGRAM
