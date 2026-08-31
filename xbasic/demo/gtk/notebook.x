'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "notebook"
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
DECLARE CFUNCTION rotate_book (XLONG button, XLONG notebook)
DECLARE CFUNCTION tabsborder_book (XLONG   button, XLONG notebook)
DECLARE CFUNCTION remove_book (XLONG button, XLONG notebook)
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()
		SHARED tval, bval
    tval = $$FALSE
    bval = $$FALSE

    gtk_init (argc, argv)

    window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)

    g_signal_connect_data (window, &"delete_event", &gtk_main_quit (), NULL, NULL, 0)

    gtk_container_set_border_width (window, 10)

    table = gtk_table_new (3, 6, $$FALSE)
    gtk_container_add (window, table)

'Create a new notebook, place the position of the tabs
    notebook = gtk_notebook_new ()
    gtk_notebook_set_tab_pos (notebook, $$GTK_POS_TOP)
    gtk_table_attach_defaults (table, notebook, 0, 6, 0, 1)
    gtk_widget_show (notebook)

'Let's append a bunch of pages to the notebook
    FOR i = 0 TO 4
			bufferf$ = "Append Frame " + STRING$(i + 1)
			bufferl$ = "Page " + STRING$(i + 1)

			frame = gtk_frame_new (&bufferf$)
			gtk_container_set_border_width (frame, 10)
			gtk_widget_set_size_request (frame, 100, 75)
			gtk_widget_show (frame)

			label = gtk_label_new (&bufferf$)
			gtk_container_add (frame, label)
			gtk_widget_show (label)

			label = gtk_label_new (&bufferl$)
			gtk_notebook_append_page (notebook, frame, label)
    NEXT i

'Now let's add a page to a specific spot
    checkbutton = gtk_check_button_new_with_label (&"Check me please!")
    gtk_widget_set_size_request (checkbutton, 100, 75)
    gtk_widget_show (checkbutton)

    label = gtk_label_new (&"Add page")
    gtk_notebook_insert_page (notebook, checkbutton, label, 2)

'Now finally let's prepend pages to the notebook
    FOR i = 0 TO 4
			bufferf$ = "Prepend Frame " + STRING$(i + 1)
			bufferl$ = "Page " + STRING$(i + 1)

			frame = gtk_frame_new (&bufferf$)
			gtk_container_set_border_width (frame, 10)
			gtk_widget_set_size_request (frame, 100, 75)
			gtk_widget_show (frame)

			label = gtk_label_new (&bufferf$)
			gtk_container_add (frame, label)
			gtk_widget_show (label)

			label = gtk_label_new (&bufferl$)
			gtk_notebook_prepend_page (notebook, frame, label)
    NEXT i

'Set what page to start at (page 4)
    gtk_notebook_set_current_page (notebook, 3)

'Create a bunch of buttons
    button = gtk_button_new_with_label (&"close")
    g_signal_connect_data (button, &"clicked", &gtk_main_quit (), NULL, NULL, $$G_CONNECT_SWAPPED)
    gtk_table_attach_defaults (table, button, 0, 1, 1, 2)
    gtk_widget_show (button)

    button = gtk_button_new_with_label (&"next page")
    g_signal_connect_data (button, &"clicked", &gtk_notebook_next_page(), notebook, NULL, $$G_CONNECT_SWAPPED)
    gtk_table_attach_defaults (table, button, 1, 2, 1, 2)
    gtk_widget_show (button)

    button = gtk_button_new_with_label (&"prev page")
    g_signal_connect_data (button, &"clicked", &gtk_notebook_prev_page(), notebook, NULL, $$G_CONNECT_SWAPPED)
    gtk_table_attach_defaults (table, button, 2, 3, 1, 2)
    gtk_widget_show (button)

    button = gtk_button_new_with_label (&"tab position")
    g_signal_connect_data (button, &"clicked", &rotate_book(), notebook, NULL, 0)
    gtk_table_attach_defaults (table, button, 3, 4, 1, 2)
    gtk_widget_show (button)

    button = gtk_button_new_with_label (&"&tabs/border on/off")
    g_signal_connect_data (button, &"clicked", &tabsborder_book(), notebook, NULL, 0)
    gtk_table_attach_defaults (table, button, 4, 5, 1, 2)
    gtk_widget_show (button)

    button = gtk_button_new_with_label (&"remove page")
    g_signal_connect_data (button, &"clicked", &remove_book(), notebook, NULL, 0)
    gtk_table_attach_defaults (table, button, 5, 6, 1, 2)
    gtk_widget_show (button)

    gtk_widget_show (table)
    gtk_widget_show (window)

    gtk_main ()

	a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' #########################
' #####  rotate_book  #####
' #########################
'
'This function rotates the position of the tabs
'
CFUNCTION rotate_book ( XLONG button, XLONG notebook)
    GTKNOTEBOOK nnotebook
		XstCopyMemory(notebook, &nnotebook, SIZE(GTKNOTEBOOK))
		tab_pos = nnotebook.flags{2,3}
		newpos = (tab_pos + 1) MOD 4
		gtk_notebook_set_tab_pos (notebook, newpos)
END FUNCTION
'
' #############################
' #####  tabsborder_book  #####
' #############################
'
'Add/Remove the page tabs and the borders
'
CFUNCTION tabsborder_book (XLONG button, XLONG notebook)
    GTKNOTEBOOK nnotebook
		SHARED tval, bval

		XstCopyMemory(notebook, &nnotebook, SIZE(GTKNOTEBOOK))
		show_tabs = nnotebook.flags{1,0}
    IFZ show_tabs THEN
			tval = $$TRUE
			ELSE
			tval = $$FALSE
		END IF
		show_border = nnotebook.flags{1,2}
    IFZ show_border THEN
			bval = $$TRUE
			ELSE
			bval = $$FALSE
		END IF
    gtk_notebook_set_show_tabs (notebook, tval)
    gtk_notebook_set_show_border (notebook, bval)

END FUNCTION
'
' #########################
' #####  remove_book  #####
' #########################
'
'
'
CFUNCTION remove_book (XLONG button, XLONG notebook)
    page = gtk_notebook_get_current_page (notebook)
    gtk_notebook_remove_page (notebook, page)
'Need to refresh the widget -- This forces the widget to redraw itself.
    gtk_widget_queue_draw (notebook)


END FUNCTION
END PROGRAM
