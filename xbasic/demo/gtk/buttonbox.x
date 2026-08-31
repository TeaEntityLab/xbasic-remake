'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged version of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "buttonbox"
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
DECLARE FUNCTION XLONG create_bbox (XLONG  horizontal, XLONG title, XLONG  spacing, XLONG  child_w, XLONG  child_h, XLONG  layout )
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()

'Initialize GTK
  gtk_init (argc, argv)

  window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)
  gtk_window_set_title (window, &"Button Boxes")

  g_signal_connect_data (window, &"destroy", &gtk_main_quit(), NULL, NULL, 0)

  gtk_container_set_border_width (window, 10)

  main_vbox = gtk_vbox_new ($$FALSE, 0)
  gtk_container_add (window, main_vbox)

  frame_horz = gtk_frame_new (&"Horizontal Button Boxes")
  gtk_box_pack_start (main_vbox, frame_horz, $$TRUE, $$TRUE, 10)

  vbox = gtk_vbox_new ($$FALSE, 0)
  gtk_container_set_border_width (vbox, 10)
  gtk_container_add (frame_horz, vbox)

  temp = create_bbox ($$TRUE, &"Spread (spacing 40)", 40, 85, 20, $$GTK_BUTTONBOX_SPREAD)
	gtk_box_pack_start (vbox, temp, $$TRUE, $$TRUE, 0)

  temp = create_bbox ($$TRUE, &"Edge (spacing 30)", 30, 85, 20, $$GTK_BUTTONBOX_EDGE)
	gtk_box_pack_start (vbox, temp, $$TRUE, $$TRUE, 5)

  temp = create_bbox ($$TRUE, &"Start (spacing 20)", 20, 85, 20, $$GTK_BUTTONBOX_START)
	gtk_box_pack_start (vbox, temp, $$TRUE, $$TRUE, 5)

  temp = create_bbox ($$TRUE, &"End (spacing 10)", 10, 85, 20, $$GTK_BUTTONBOX_END)
	gtk_box_pack_start (vbox, temp, $$TRUE, $$TRUE, 5)

  frame_vert = gtk_frame_new (&"Vertical Button Boxes")
  gtk_box_pack_start (main_vbox, frame_vert, $$TRUE, $$TRUE, 10)

  hbox = gtk_hbox_new ($$FALSE, 0)
  gtk_container_set_border_width (hbox, 10)
  gtk_container_add (frame_vert, hbox)

  temp = create_bbox ($$FALSE, &"Spread (spacing 5)", 5, 85, 20, $$GTK_BUTTONBOX_SPREAD)
	gtk_box_pack_start (hbox, temp, $$TRUE, $$TRUE, 0)

	temp = create_bbox ($$FALSE, &"Edge (spacing 30)", 30, 85, 20, $$GTK_BUTTONBOX_EDGE)
  gtk_box_pack_start (hbox, temp, $$TRUE, $$TRUE, 5)

	temp = create_bbox ($$FALSE, &"Start (spacing 20)", 20, 85, 20, $$GTK_BUTTONBOX_START)
  gtk_box_pack_start (hbox, temp, $$TRUE, $$TRUE, 5)

  temp = create_bbox ($$FALSE, &"End (spacing 20)", 20, 85, 20, $$GTK_BUTTONBOX_END)
	gtk_box_pack_start (hbox, temp, $$TRUE, $$TRUE, 5)

  gtk_widget_show_all (window)

'Enter the event loop
  gtk_main ()

	a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' #########################
' #####  create_bbox  #####
' #########################
'
'
'
FUNCTION create_bbox (XLONG  horizontal, XLONG title, XLONG  spacing, XLONG  child_w, XLONG  child_h, XLONG  layout )
  frame = gtk_frame_new (title)

  IF (horizontal) THEN
    bbox = gtk_hbutton_box_new ()
  ELSE
    bbox = gtk_vbutton_box_new ()
	END IF

  gtk_container_set_border_width (bbox, 5)
  gtk_container_add (frame, bbox)

'Set the appearance of the Button Box
  gtk_button_box_set_layout (bbox, layout)
  gtk_box_set_spacing (bbox, spacing)
'gtk_button_box_set_child_size (GTK_BUTTON_BOX (bbox), child_w, child_h);

  button = gtk_button_new_from_stock (&"gtk-ok")
  gtk_container_add (bbox, button)

  button = gtk_button_new_from_stock (&"gtk-cancel")
  gtk_container_add (bbox, button)

  button = gtk_button_new_from_stock (&"gtk-help")
  gtk_container_add (bbox, button)


END FUNCTION frame
END PROGRAM
