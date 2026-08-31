'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'Contributor David Szanfranski
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "spinbutton"
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
DECLARE FUNCTION delete_event ()
DECLARE CFUNCTION get_value (XLONG widget,XLONG data)
DECLARE CFUNCTION toggle_snap (XLONG widget, XLONG spin)
DECLARE CFUNCTION toggle_numeric (XLONG widget, XLONG spin)
DECLARE CFUNCTION change_digits (XLONG widget, XLONG spin)

'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()
	SHARED spinner1

  gtk_init (argc, argv)

  window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)

  detailed_signal$ = "destroy"
	g_signal_connect_data (window, &detailed_signal$ , &gtk_main_quit(), NULL, NULL, 0)

  text$ = "Spin Button"
	gtk_window_set_title (window, &text$)

  main_vbox = gtk_vbox_new ($$FALSE, 5)
  gtk_container_set_border_width (main_vbox, 10)
  gtk_container_add (window, main_vbox)

  text$ = "Not accelerated"
	frame = gtk_frame_new (&text$)
  gtk_box_pack_start (main_vbox, frame, $$TRUE, $$TRUE, 0)

  vbox = gtk_vbox_new ($$FALSE, 0)
  gtk_container_set_border_width (vbox, 5)
  gtk_container_add (frame, vbox)

'Day, month, year spinners

  hbox = gtk_hbox_new ($$FALSE, 0)
  gtk_box_pack_start (vbox, hbox, $$TRUE, $$TRUE, 5)

  vbox2 = gtk_vbox_new ($$FALSE, 0)
  gtk_box_pack_start (hbox, vbox2, $$TRUE, $$TRUE, 5)

  text$ = "Day :"
	label = gtk_label_new (&text$)
  gtk_misc_set_alignment (label, 0, 0.5)
  gtk_box_pack_start (vbox2, label, $$FALSE, $$TRUE, 0)

  adj = gtk_adjustment_new (1.0, 1.0, 31.0, 1.0, 5.0, 0.0)
  spinner = gtk_spin_button_new (adj, 0, 0)
  gtk_spin_button_set_wrap (spinner, $$TRUE)
  gtk_box_pack_start (vbox2, spinner, $$FALSE, $$TRUE, 0)

  vbox2 = gtk_vbox_new ($$FALSE, 0)
  gtk_box_pack_start (hbox, vbox2, $$TRUE, $$TRUE, 5)

  text$ = "Month :"
	label = gtk_label_new (&text$)
  gtk_misc_set_alignment (label, 0, 0.5)
  gtk_box_pack_start (vbox2, label, $$FALSE, $$TRUE, 0)

  adj = gtk_adjustment_new (1.0, 1.0, 12.0, 1.0, 5.0, 0.0)
  spinner = gtk_spin_button_new (adj, 0, 0)
  gtk_spin_button_set_wrap (spinner, $$TRUE)
  gtk_box_pack_start (vbox2, spinner, $$FALSE, $$TRUE, 0)

  vbox2 = gtk_vbox_new ($$FALSE, 0)
  gtk_box_pack_start (hbox, vbox2, $$TRUE, $$TRUE, 5)

  text$ = "Year :"
	label = gtk_label_new (&text$)
  gtk_misc_set_alignment (label, 0, 0.5)
  gtk_box_pack_start (vbox2, label, $$FALSE, $$TRUE, 0)

  adj = gtk_adjustment_new (1998.0, 0.0, 2100.0,	1.0, 100.0, 0.0)
  spinner = gtk_spin_button_new (adj, 0, 0)
  gtk_spin_button_set_wrap (spinner, $$FALSE)
  gtk_widget_set_size_request (spinner, 55, -1)
  gtk_box_pack_start (vbox2, spinner, $$FALSE, $$TRUE, 0)

  text$ = "Accelerated"
	frame = gtk_frame_new (&text$)
  gtk_box_pack_start (main_vbox, frame, $$TRUE, $$TRUE, 0)

  vbox = gtk_vbox_new ($$FALSE, 0)
  gtk_container_set_border_width (vbox, 5)
  gtk_container_add (frame, vbox)

  hbox = gtk_hbox_new ($$FALSE, 0)
  gtk_box_pack_start (vbox, hbox, $$FALSE, $$TRUE, 5)

  vbox2 = gtk_vbox_new ($$FALSE, 0)
  gtk_box_pack_start (hbox, vbox2, $$TRUE, $$TRUE, 5)

  text$ = "Value :"
	label = gtk_label_new (&text$)
  gtk_misc_set_alignment (label, 0, 0.5)
  gtk_box_pack_start (vbox2, label, $$FALSE, $$TRUE, 0)

  adj = gtk_adjustment_new (0.0, -10000.0, 10000.0,	0.5, 100.0, 0.0)
  spinner1 = gtk_spin_button_new (adj, 1.0, 2)
  gtk_spin_button_set_wrap (spinner1, $$TRUE)
  gtk_widget_set_size_request (spinner1, 100, -1)
  gtk_box_pack_start (vbox2, spinner1, $$FALSE, $$TRUE, 0)

  vbox2 = gtk_vbox_new ($$FALSE, 0)
  gtk_box_pack_start (hbox, vbox2, $$TRUE, $$TRUE, 5)

  text$ = "Digits :"
	label = gtk_label_new (&text$)
  gtk_misc_set_alignment (label, 0, 0.5)
  gtk_box_pack_start (vbox2, label, $$FALSE, $$TRUE, 0)

  adj = gtk_adjustment_new (2, 1, 5, 1, 1, 0)
  spinner2 = gtk_spin_button_new (adj, 0.0, 0)
  gtk_spin_button_set_wrap (spinner2, $$TRUE)
  detailed_signal$ = "value_changed"
	g_signal_connect_data (adj, &detailed_signal$, &change_digits(), spinner2, NULL, 0)
  gtk_box_pack_start (vbox2, spinner2, $$FALSE, $$TRUE, 0)

  hbox = gtk_hbox_new ($$FALSE, 0)
  gtk_box_pack_start (vbox, hbox, $$FALSE, $$TRUE, 5)

  text$ = "Snap to 0.5-ticks"
	button = gtk_check_button_new_with_label (&text$)
  detailed_signal$ = "clicked"
	g_signal_connect_data (button, &detailed_signal$, &toggle_snap(), spinner1, NULL, 0)
  gtk_box_pack_start (vbox, button, $$TRUE, $$TRUE, 0)
  gtk_toggle_button_set_active (button, 1)

  text$ = "Numeric only input mode"
	button = gtk_check_button_new_with_label (&text$)
  detailed_signal$ = "clicked"
	g_signal_connect_data (button, &detailed_signal$, &toggle_numeric(), spinner1, NULL, 0)
  gtk_box_pack_start (vbox, button, $$TRUE, $$TRUE, 0)
  gtk_toggle_button_set_active (button, 1)

  text$ = ""
	val_label = gtk_label_new (&text$)

  hbox = gtk_hbox_new ($$FALSE, 0)
  gtk_box_pack_start (vbox, hbox, $$FALSE, $$TRUE, 5)
	text$ = "Value as Int"
  button1 = gtk_button_new_with_label (&text$)
  text$ = "user_data"
	g_object_set_data (button1, &text$, val_label)
	detailed_signal$ = "clicked"
	value = 1
	g_signal_connect_data (button1, &detailed_signal$, &get_value(), 1, NULL, 0)
  gtk_box_pack_start (hbox, button1, $$TRUE, $$TRUE, 5)

	text$ = "Value as Float"
  button2 = gtk_button_new_with_label (&text$)
  text$ = "user_data"
	g_object_set_data (button2, &text$, val_label)

	detailed_signal$ = "clicked"
	'value = 2
	g_signal_connect_data (button2, &detailed_signal$, &get_value(), 2, NULL, 0)
  gtk_box_pack_start (hbox, button2, $$TRUE, $$TRUE, 5)

  gtk_box_pack_start (vbox, val_label, $$TRUE, $$TRUE, 0)

	text$ = "0"
	gtk_label_set_text (val_label, &text$)

  hbox = gtk_hbox_new ($$FALSE, 0)
  gtk_box_pack_start (main_vbox, hbox, $$FALSE, $$TRUE, 0)

  text$ = "Close"
	button = gtk_button_new_with_label (&text$)
  detailed_signal$ = "clicked"
	g_signal_connect_data (button, &detailed_signal$, &gtk_widget_destroy(), window, NULL, $$G_CONNECT_SWAPPED)
  gtk_box_pack_start (hbox, button, $$TRUE, $$TRUE, 5)

  gtk_widget_show_all (window)

'Enter the event loop
  gtk_main ()

	a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' ##########################
' #####  delete_event  #####
' ##########################
'
'
'
FUNCTION delete_event ()


END FUNCTION
'
' #######################
' #####  get_value  #####
' #######################
'
'
'
CFUNCTION get_value (XLONG widget,XLONG data)
	SHARED spinner1
	GTKSPINBUTTON spin

	buf$ = ""

	XstCopyMemory	(spinner1, &spin, SIZE(GTKSPINBUTTON))
	label = g_object_get_data (widget, &"user_data")
	IF (data = 1) THEN
    buf$ = buf$ + STRING$(gtk_spin_button_get_value_as_int (spinner1))
  ELSE
		buf$ = buf$ + STRING$(gtk_spin_button_get_digits(spinner1)) + "---" + STRING$(gtk_spin_button_get_value (spinner1))
	END IF
  gtk_label_set_text (label, &buf$)

END FUNCTION
'
' #########################
' #####  toggle_snap  #####
' #########################
'
'
'
CFUNCTION toggle_snap (XLONG widget, XLONG spin)
	active = gtk_toggle_button_get_active	(widget)
	gtk_spin_button_set_snap_to_ticks (spin, active)

END FUNCTION

'
' ############################
' #####  toggle_numeric  #####
' ############################
'
'
'
CFUNCTION toggle_numeric (XLONG widget, XLONG spin)
  GTKTOGGLEBUTTON tbwidget
	ULONG flagss

	XstCopyMemory	(spin, &tbwidget, SIZE(GTKTOGGLEBUTTON))

	flagss = tbwidget.flags
	active = tbwidget.flags{1,0}  ' extract bitfield

  gtk_spin_button_set_numeric (spin, active)

END FUNCTION
'
' ###########################
' #####  change_digits  #####
' ###########################
'
'
'
CFUNCTION change_digits (XLONG widget, XLONG spin)
	SHARED spinner1
  gtk_spin_button_set_digits (spinner1, gtk_spin_button_get_value_as_int (spin))


END FUNCTION
END PROGRAM
