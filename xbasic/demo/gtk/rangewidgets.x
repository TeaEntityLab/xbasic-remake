'Example adapted for XBLite by Liviu Armeanu. Updated versions are available at
'http:\\homepages.ihug.co.nz\~armeanu
'Source: "GTK+ Tutorial" authors Tony Gale, Ian Main & the GTK team
'A packaged verion of the tutorial is available from ftp.gtk.org/pub/gtk/tutorial2
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "rangewidgets"
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
DECLARE CFUNCTION cb_pos_menu_select (XLONG item,XLONG pos)
DECLARE CFUNCTION cb_update_menu_select (XLONG item,XLONG  policy)
DECLARE CFUNCTION cb_digits_scale (XLONG adj)
DECLARE CFUNCTION cb_page_size ( XLONG get, XLONG set )
DECLARE CFUNCTION cb_draw_value (XLONG button)
DECLARE FUNCTION XLONG make_menu_item (XLONG name, XLONG callback, XLONG data)
DECLARE FUNCTION scale_set_default_values (XLONG scale )
DECLARE FUNCTION create_range_controls ()
DECLARE FUNCTION XLONG clamp (XLONG x, XLONG low, XLONG high)

SHARED hscale
SHARED vscale

'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION Entry ()

    gtk_init (argc, argv)
    create_range_controls ()
    gtk_main ()

		a$ = INLINE$("Press ENTER to exit")
END FUNCTION
'
' ################################
' #####  cb_pos_menu_select  #####
' ################################
'
'
'
CFUNCTION cb_pos_menu_select (XLONG item,XLONG pos)
SHARED hscale
SHARED vscale

'Set the value position on both scale widgets
    gtk_scale_set_value_pos (hscale, pos)
    gtk_scale_set_value_pos (vscale, pos)

END FUNCTION
'
' ###################################
' #####  cb_update_menu_select  #####
' ###################################
'
'
'
CFUNCTION cb_update_menu_select (XLONG item,XLONG  policy)
SHARED hscale
SHARED vscale

'Set the update policy for both scale widgets
    gtk_range_set_update_policy (hscale, policy)
    gtk_range_set_update_policy (vscale, policy)

END FUNCTION
'
' #############################
' #####  cb_digits_scale  #####
' #############################
'
'
'
CFUNCTION cb_digits_scale (XLONG adj)
SHARED hscale
SHARED vscale

'Set the number of decimal places to which adj->value is rounded
    GTKADJUSTMENT adjust

		XstCopyMemory(adj, &adjust, SIZE(GTKADJUSTMENT))
		gtk_scale_set_digits (hscale, adjust.value)
    gtk_scale_set_digits (vscale, adjust.value)
END FUNCTION
'
' ##########################
' #####  cb_page_size  #####
' ##########################
'
'
'
CFUNCTION cb_page_size ( XLONG get, XLONG set )
    GTKADJUSTMENT getadjust
    GTKADJUSTMENT setadjust
'Set the page size and page increment size of the sample
'adjustment to the value specified by the "Page Size" scale
		XstCopyMemory(get, &getadjust, SIZE(GTKADJUSTMENT))
		XstCopyMemory(set, &setadjust, SIZE(GTKADJUSTMENT))
    setadjust.page_size = getadjust.value
    setadjust.page_increment = getadjust.value

'This sets the adjustment and makes it emit the "changed" signal to
'reconfigure all the widgets that are attached to this signal.
		x = setadjust.value
		low = setadjust.lower
		high = setadjust.upper - setadjust.page_size
    gtk_adjustment_set_value (set, clamp(x, low, high))

END FUNCTION
'
' ###########################
' #####  cb_draw_value  #####
' ###########################
'
'
'
CFUNCTION cb_draw_value (XLONG button )
SHARED hscale
SHARED vscale

GTKTOGGLEBUTTON togglebutton

		XstCopyMemory(button, &togglebutton, SIZE(GTKTOGGLEBUTTON))
'Turn the value display on the scale widgets off or on depending
'on the state of the checkbutton
		IF (gtk_toggle_button_get_active (button)) THEN
				gtk_scale_set_draw_value (hscale, $$TRUE)
				gtk_scale_set_draw_value (vscale, $$TRUE)
		ELSE
				gtk_scale_set_draw_value (hscale, $$FALSE)
				gtk_scale_set_draw_value (vscale, $$FALSE)
		END IF
END FUNCTION
'
' ############################
' #####  make_menu_item  #####
' ############################
'
'
'
FUNCTION make_menu_item (XLONG name, XLONG callback, XLONG data)
    item = gtk_menu_item_new_with_label (name)
    detailed_signal$ = "activate"
		g_signal_connect_data (item, &detailed_signal$, callback, data, NULL, 0)
    gtk_widget_show (item)

END FUNCTION item
'
' ######################################
' #####  scale_set_default_values  #####
' ######################################
'
'
'
FUNCTION scale_set_default_values (XLONG scale )
    gtk_range_set_update_policy (scale, $$GTK_UPDATE_CONTINUOUS)
    gtk_scale_set_digits (scale, 1)
    gtk_scale_set_value_pos (scale, $$GTK_POS_TOP)
    gtk_scale_set_draw_value (scale, 1)
END FUNCTION
'
' ###################################
' #####  create_range_controls  #####
' ###################################
'
'
'
FUNCTION create_range_controls ()
SHARED hscale
SHARED vscale

'Standard window-creating stuff
    window = gtk_window_new ($$GTK_WINDOW_TOPLEVEL)

		detailed_signal$ = "destroy"
		g_signal_connect_data (window, &detailed_signal$, &gtk_main_quit(), NULL, NULL, 0)

		text$ = "range controls"
		gtk_window_set_title (window, &text$)

    box1 = gtk_vbox_new (0, 0)
    gtk_container_add (window, box1)
    gtk_widget_show (box1)

    box2 = gtk_hbox_new (0, 10)
    gtk_container_set_border_width (box2, 10)
    gtk_box_pack_start (box1, box2, 1, 1, 0)
    gtk_widget_show (box2)

'value, lower, upper, step_increment, page_increment, page_size
'Note that the page_size value only makes a difference for
'scrollbar widgets, and the highest value you'll get is actually (upper - page_size).
    adj1 = gtk_adjustment_new (0.0, 0.0, 101.0, 0.1, 1.0, 1.0)

    vscale = gtk_vscale_new (adj1)
    scale_set_default_values (vscale)
    gtk_box_pack_start (box2, vscale, 1, 1, 0)
    gtk_widget_show (vscale)

    box3 = gtk_vbox_new (1, 10)
    gtk_box_pack_start (box2, box3, 0, 0, 0)
    gtk_widget_show (box3)

'Reuse the same adjustment
    hscale = gtk_hscale_new (adj1)
    gtk_widget_set_size_request (hscale, 200, -1)
    scale_set_default_values (hscale)
    gtk_box_pack_start (box3, hscale, 1, 1, 0)
    gtk_widget_show (hscale)

'Reuse the same adjustment again
    scrollbar = gtk_hscrollbar_new (adj1)
'Notice how this causes the scales to always be updated
'continuously when the scrollbar is moved
    gtk_range_set_update_policy (scrollbar, $$GTK_UPDATE_CONTINUOUS)
    gtk_box_pack_start (box3, scrollbar, 1, 1, 0)
    gtk_widget_show (scrollbar)

    box2 = gtk_hbox_new (0, 10)
    gtk_container_set_border_width (box2, 10)
    gtk_box_pack_start (box1, box2, 0, 0, 0)
    gtk_widget_show (box2)

'A checkbutton to control whether the value is displayed or not
    text$ = "Display value on scale widgets"
		button = gtk_check_button_new_with_label(&text$)
    gtk_toggle_button_set_active (button, 1)
    detailed_signal$ = "toggled"
		g_signal_connect_data (button, &detailed_signal$, &cb_draw_value(), NULL, NULL, 0)
    gtk_box_pack_start (box2, button, 1, 1, 0)
    gtk_widget_show (button)

    box2 = gtk_hbox_new (0, 10)
    gtk_container_set_border_width (box2, 10)

'An option menu to change the position of the value
    text$ = "Scale Value Position:"
		label = gtk_label_new (&text$)
    gtk_box_pack_start (box2, label, 1, 1, 0)
    gtk_widget_show (label)

    opt = gtk_option_menu_new ()
    menu = gtk_menu_new ()

    text$ = "Top"
		item = make_menu_item (&text$, &cb_pos_menu_select(), $$GTK_POS_TOP)
    gtk_menu_shell_append (menu, item)

		text$ = "Bottom"
    item = make_menu_item (&text$, &cb_pos_menu_select(), $$GTK_POS_BOTTOM)
    gtk_menu_shell_append (menu, item)

    text$ = "Left"
		item = make_menu_item (&text$, &cb_pos_menu_select(), $$GTK_POS_LEFT)
    gtk_menu_shell_append (menu, item)

    text$ = "Right"
		item = make_menu_item (&text$, &cb_pos_menu_select(), $$GTK_POS_RIGHT)
    gtk_menu_shell_append (menu, item)

    gtk_option_menu_set_menu (opt, menu)
    gtk_box_pack_start (box2, opt, 1, 1, 0)
    gtk_widget_show (opt)

    gtk_box_pack_start (box1, box2, 1, 1, 0)
    gtk_widget_show (box2)

    box2 = gtk_hbox_new (0, 10)
    gtk_container_set_border_width (box2, 10)

'Yet another option menu, this time for the update policy of the scale widgets
		text$ = "Scale Update Policy:"
    label = gtk_label_new (&text$)
    gtk_box_pack_start (box2, label, 0, 0, 0)
    gtk_widget_show (label)

    opt = gtk_option_menu_new ()
    menu = gtk_menu_new ()

    text$ = "Continuous"
		item = make_menu_item (&text$, &cb_update_menu_select(), $$GTK_UPDATE_CONTINUOUS)
    gtk_menu_shell_append (menu, item)

		text$ = "Discontinuous"
    item = make_menu_item (&text$, &cb_update_menu_select(), $$GTK_UPDATE_DISCONTINUOUS)
    gtk_menu_shell_append (menu, item)

		text$ = "Delayed"
    item = make_menu_item (&text$, &cb_update_menu_select(), $$GTK_UPDATE_DELAYED)
    gtk_menu_shell_append (menu, item)

    gtk_option_menu_set_menu (opt, menu)
    gtk_box_pack_start (box2, opt, 1, 1, 0)
    gtk_widget_show (opt)

    gtk_box_pack_start (box1, box2, 1, 1, 0)
    gtk_widget_show (box2)

    box2 = gtk_hbox_new (0, 10)
    gtk_container_set_border_width (box2, 10)

'An HScale widget for adjusting the number of digits on the sample scales.
    text$ = "Scale Digits:"
		label = gtk_label_new (&text$)
    gtk_box_pack_start (box2, label, 0, 0, 0)
    gtk_widget_show (label)

    adj2 = gtk_adjustment_new (1.0, 0.0, 5.0, 1.0, 1.0, 0.0)

		detailed_signal$ = "value_changed"
		g_signal_connect_data (adj2, &detailed_signal$, &cb_digits_scale(), NULL, NULL, 0)
    scale = gtk_hscale_new (adj2)
    gtk_scale_set_digits (scale, 0)
    gtk_box_pack_start (box2, scale, 1, 1, 0)
    gtk_widget_show (scale)

    gtk_box_pack_start (box1, box2, 1, 1, 0)
    gtk_widget_show (box2)

    box2 = gtk_hbox_new (0, 10)
    gtk_container_set_border_width (box2, 10)

'And, one last HScale widget for adjusting the page size of the scrollbar.
		text$ = "Scrollbar Page Size:"
    label = gtk_label_new (&text$)
    gtk_box_pack_start (box2, label, 0, 0, 0)
    gtk_widget_show (label)

    adj2 = gtk_adjustment_new (1.0, 1.0, 101.0, 1.0, 1.0, 0.0)
    detailed_signal$ = "value_changed"
		g_signal_connect_data (adj2, &detailed_signal$, &cb_page_size(), adj1, NULL, 0)
    scale = gtk_hscale_new (adj2)
    gtk_scale_set_digits (scale, 0)
    gtk_box_pack_start (box2, scale, 1, 1, 0)
    gtk_widget_show (scale)

    gtk_box_pack_start (box1, box2, 1, 1, 0)
    gtk_widget_show (box2)

    separator = gtk_hseparator_new ()
    gtk_box_pack_start (box1, separator, 0, 1, 0)
    gtk_widget_show (separator)

    box2 = gtk_vbox_new (0, 10)
    gtk_container_set_border_width (box2, 10)
    gtk_box_pack_start (box1, box2, 0, 1, 0)
    gtk_widget_show (box2)

    text$ = "Quit"
		button = gtk_button_new_with_label (&text$)
    detailed_signal$ = "clicked"
		g_signal_connect_data (button, &detailed_signal$, &gtk_main_quit(), NULL, NULL, $$G_CONNECT_SWAPPED)
    gtk_box_pack_start (box2, button, 1, 1, 0)
'    GTK_WIDGET_SET_FLAGS (button, GTK_CAN_DEFAULT)
'    gtk_widget_grab_default (button)
    gtk_widget_show (button)

    gtk_widget_show (window)

END FUNCTION
'
' ###################
' #####  clamp  #####
' ###################
'
'
'
FUNCTION clamp (XLONG x, XLONG low, XLONG high)
	SELECT CASE TRUE
	CASE x > high : x = high
	CASE x < low : x = low
	END SELECT



END FUNCTION x
END PROGRAM
