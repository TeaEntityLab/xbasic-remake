# xbasic/ — license manifest

This tree is a verbatim port of source material from the upstream
XBasic 6.4.5 release (Max Reason, 1988-2000+; C runtime ports 2000
Wade Maxfield). Files are unmodified — per-file headers govern where
present; files without headers are distributed as part of the upstream
release under its tree-level licenses (COPYING = GPL-2.0,
COPYING_LIB = LGPL-2.1; complete canonical texts in this directory).

Layout (reorganized from upstream — the shared/linux split is dropped
because the 6.5.0 Rust toolchain is cross-platform):

```
lib/       core library sources (.x) + their declaration files (.dec)
include/   shared declaration files (clib, xlib, xwin, elf*, gtk/glib)
demo/      demo programs + small data files
crtl/      upstream C ports of the runtime (LGPL, canonical location)
helpsrc/   help-build programs and help text sources
help/      built help text
templates/ GuiDesigner templates
tools/     small upstream utilities
doc/       upstream CHANGES and README.Linux
```

Excluded from the port: generated assembly (*.s), compiled binaries
(src/bin, *.o, *.a), legacy Makefiles/xbasic.spec (build system is
Rust), images/ artwork, and XBSourceLib (no explicit license —
remains local-only reference material).

## Provenance caveat (RR-11)

gdi32.x, kernel32.x, user32.x carry no copyright or license
statement. They ship here solely as part of the upstream release
under its tree-level distribution; do not redistribute them separately
until provenance is resolved (docs/17-open-work-roadmap.md RR-11).

## Per-file header scan

Classes: LGPL / GPL = explicit per-file header; COPYRIGHT-ONLY =
copyright line without license reference; NO-NOTICE = no header
(tree-level distribution license applies).

```
LGPL            ./crtl/xbxtrns.c
LGPL            ./crtl/xconst.h
LGPL            ./crtl/xlib.c
LGPL            ./crtl/xstart.c
LGPL            ./crtl/Xzzz.c
NO-NOTICE       ./demo/aarray_ISNODE.x
NO-NOTICE       ./demo/aarray.x
NO-NOTICE       ./demo/aback.x
NO-NOTICE       ./demo/abuffer.x
NO-NOTICE       ./demo/acgibin.x
NO-NOTICE       ./demo/acharmap.x
NO-NOTICE       ./demo/acircle.x
NO-NOTICE       ./demo/aclear.x
NO-NOTICE       ./demo/aclient.x
NO-NOTICE       ./demo/acolors.x
NO-NOTICE       ./demo/acolumns.x
NO-NOTICE       ./demo/acommand.x
NO-NOTICE       ./demo/aconsole.x
NO-NOTICE       ./demo/aconvert.x
NO-NOTICE       ./demo/acrc32.x
NO-NOTICE       ./demo/adatadim.x
NO-NOTICE       ./demo/adata.x
NO-NOTICE       ./demo/ademo.x
NO-NOTICE       ./demo/adialog.x
NO-NOTICE       ./demo/adrawing.x
NO-NOTICE       ./demo/aeasy.x
NO-NOTICE       ./demo/aeditors.x
NO-NOTICE       ./demo/aedit.x
NO-NOTICE       ./demo/afile.x
NO-NOTICE       ./demo/afindall.x
NO-NOTICE       ./demo/afirst.x
NO-NOTICE       ./demo/aformat.x
NO-NOTICE       ./demo/afuntype.x
NO-NOTICE       ./demo/agraphic.x
NO-NOTICE       ./demo/agrids.x
NO-NOTICE       ./demo/ahello.x
NO-NOTICE       ./demo/ahowdy.x
NO-NOTICE       ./demo/ahtml.x
NO-NOTICE       ./demo/aloha.x
NO-NOTICE       ./demo/amakemap.x
NO-NOTICE       ./demo/amath.x
NO-NOTICE       ./demo/amemory.x
NO-NOTICE       ./demo/amerge.x
NO-NOTICE       ./demo/amodal.x
NO-NOTICE       ./demo/anewlook.x
NO-NOTICE       ./demo/api.x
NO-NOTICE       ./demo/aprofile.x
NO-NOTICE       ./demo/aquick.x
NO-NOTICE       ./demo/arecord.x
NO-NOTICE       ./demo/arecurse.x
NO-NOTICE       ./demo/aredrawn.x
NO-NOTICE       ./demo/arotate.x
NO-NOTICE       ./demo/aserver.x
NO-NOTICE       ./demo/ashell.x
NO-NOTICE       ./demo/asortie.x
NO-NOTICE       ./demo/asound.x
NO-NOTICE       ./demo/aspread.x
NO-NOTICE       ./demo/astring.x
NO-NOTICE       ./demo/asystem.x
NO-NOTICE       ./demo/asystime.x
NO-NOTICE       ./demo/atask.x
NO-NOTICE       ./demo/atcursor.x
NO-NOTICE       ./demo/atimer.x
NO-NOTICE       ./demo/atools.x
NO-NOTICE       ./demo/atrim.x
NO-NOTICE       ./demo/aunicode.x
NO-NOTICE       ./demo/aviewbmp.x
NO-NOTICE       ./demo/awarn.x
NO-NOTICE       ./demo/awheel.x
NO-NOTICE       ./demo/awindow.x
NO-NOTICE       ./demo/awrite.x
LGPL            ./demo/CursorEdit.x
NO-NOTICE       ./demo/DrawScaled.x
NO-NOTICE       ./demo/editors.x
NO-NOTICE       ./demo/edit.x
NO-NOTICE       ./demo/gifview.x
NO-NOTICE       ./demo/gif.x
NO-NOTICE       ./demo/gtk/arrow.x
NO-NOTICE       ./demo/gtk/buttonbox.x
NO-NOTICE       ./demo/gtk/buttons.x
NO-NOTICE       ./demo/gtk/entry.x
NO-NOTICE       ./demo/gtk/eventbox.x
NO-NOTICE       ./demo/gtk/fixed.x
NO-NOTICE       ./demo/gtk/frame.x
NO-NOTICE       ./demo/gtk/helloworld2.x
NO-NOTICE       ./demo/gtk/helloworld.x
NO-NOTICE       ./demo/gtk/menu.x
NO-NOTICE       ./demo/gtk/notebook.x
NO-NOTICE       ./demo/gtk/packbox.x
NO-NOTICE       ./demo/gtk/progressbar.x
NO-NOTICE       ./demo/gtk/radiobuttons.x
NO-NOTICE       ./demo/gtk/rangewidgets.x
NO-NOTICE       ./demo/gtk/rulers.x
NO-NOTICE       ./demo/gtk/spinbutton.x
NO-NOTICE       ./demo/gtk/statusbar.x
NO-NOTICE       ./demo/gtk/table.x
NO-NOTICE       ./demo/hello.x
LGPL            ./demo/Kittedy.x
GPL             ./demo/qbtoxb.x
NO-NOTICE       ./demo/tcheckbx.x
NO-NOTICE       ./demo/tcolors.x
NO-NOTICE       ./demo/tcolor.x
NO-NOTICE       ./demo/tdial2.x
NO-NOTICE       ./demo/tdial3.x
NO-NOTICE       ./demo/tdial4.x
NO-NOTICE       ./demo/tdropbox.x
NO-NOTICE       ./demo/tdropbut.x
NO-NOTICE       ./demo/tfile.x
NO-NOTICE       ./demo/tfont.x
NO-NOTICE       ./demo/tlabel.x
NO-NOTICE       ./demo/tlist2.x
NO-NOTICE       ./demo/tlistbox.x
NO-NOTICE       ./demo/tlistbut.x
NO-NOTICE       ./demo/tlist.x
NO-NOTICE       ./demo/tmenubar.x
NO-NOTICE       ./demo/tmenu.x
NO-NOTICE       ./demo/tmess1.x
NO-NOTICE       ./demo/tmess2.x
NO-NOTICE       ./demo/tmess3.x
NO-NOTICE       ./demo/tmess4.x
NO-NOTICE       ./demo/tpress.x
NO-NOTICE       ./demo/tprog.x
NO-NOTICE       ./demo/tpulldn.x
NO-NOTICE       ./demo/tpush.x
NO-NOTICE       ./demo/tradiobx.x
NO-NOTICE       ./demo/tradio.x
NO-NOTICE       ./demo/trange.x
NO-NOTICE       ./demo/tscrollh.x
NO-NOTICE       ./demo/tscrollv.x
NO-NOTICE       ./demo/ttoggle.x
NO-NOTICE       ./demo/ttxtarea.x
NO-NOTICE       ./demo/ttxtline_cr.x
NO-NOTICE       ./demo/ttxtline_jc.x
NO-NOTICE       ./demo/ttxtline.x
NO-NOTICE       ./demo/warning.x
NO-NOTICE       ./demo/wviewbmp.x
NO-NOTICE       ./demo/xgrids.x
NO-NOTICE       ./demo/zap.x
NO-NOTICE       ./helpsrc/help_program/CreateHelp.x
NO-NOTICE       ./helpsrc/help_program/MakeDistLinux.x
NO-NOTICE       ./helpsrc/help_program/MakeDist.x
NO-NOTICE       ./helpsrc/help_text/lang.txt
NO-NOTICE       ./helpsrc/help_text/messages.txt
NO-NOTICE       ./helpsrc/help_text/misc.txt
NO-NOTICE       ./helpsrc/help_text/pde.txt
LGPL            ./include/clib.dec
NO-NOTICE       ./include/elf32.dec
NO-NOTICE       ./include/elf64.dec
NO-NOTICE       ./include/gdk_pixbuf-2.0.dec
NO-NOTICE       ./include/gdk-x11-2.0.dec
NO-NOTICE       ./include/gio-2.0.dec
NO-NOTICE       ./include/glib-2.0.dec
NO-NOTICE       ./include/gmodule-2.0.dec
NO-NOTICE       ./include/gobject-2.0.dec
NO-NOTICE       ./include/gtk-x11-2.0.dec
LGPL            ./include/shell32.dec
NO-NOTICE       ./include/sqlite3.dec
LGPL            ./include/ssh2.dec
LGPL            ./include/ssh.dec
LGPL            ./include/winmm.dec
NO-NOTICE       ./include/wsock32.dec
NO-NOTICE       ./include/xbasic.dec
NO-NOTICE       ./include/xin.dec
NO-NOTICE       ./include/xlib.dec
NO-NOTICE       ./include/xma_old.dec
NO-NOTICE       ./include/xwin.dec
NO-NOTICE       ./lib/gdi32.dec
NO-NOTICE       ./lib/gdi32.x
NO-NOTICE       ./lib/kernel32.dec
NO-NOTICE       ./lib/kernel32.x
NO-NOTICE       ./lib/user32.dec
NO-NOTICE       ./lib/user32.x
NO-NOTICE       ./lib/xcm.dec
LGPL            ./lib/xcm.x
GPL             ./lib/xcol.x
GPL             ./lib/xdis.x
NO-NOTICE       ./lib/xgr.dec
LGPL            ./lib/xgr.x
NO-NOTICE       ./lib/xin.dec
LGPL            ./lib/xin.x
GPL             ./lib/xit.x
NO-NOTICE       ./lib/xma.dec
LGPL            ./lib/xma.x
LGPL            ./lib/xrun.x
NO-NOTICE       ./lib/xst.dec
LGPL            ./lib/xst.x
NO-NOTICE       ./lib/xui.dec
LGPL            ./lib/xui.x
NO-NOTICE       ./lib/xut.dec
NO-NOTICE       ./lib/xutpde.dec
LGPL            ./lib/xutpde.x
LGPL            ./lib/xut.x
NO-NOTICE       ./templates/code.xxx
NO-NOTICE       ./templates/create.xxx
NO-NOTICE       ./templates/entry.xxx
NO-NOTICE       ./templates/expire.xxx
NO-NOTICE       ./templates/fonts.xxx
NO-NOTICE       ./templates/gentry.xxx
NO-NOTICE       ./templates/gprolog.xxx
NO-NOTICE       ./templates/initgui.xxx
NO-NOTICE       ./templates/initprog.xxx
NO-NOTICE       ./templates/initwins.xxx
NO-NOTICE       ./templates/intro.xxx
NO-NOTICE       ./templates/linux/first.xxx
NO-NOTICE       ./templates/linux/fonts.xxx
NO-NOTICE       ./templates/linux/font.xxx
LGPL            ./templates/linux/start.xxx
NO-NOTICE       ./templates/linux/title.xxx
NO-NOTICE       ./templates/linux/xapp.xxx
NO-NOTICE       ./templates/linux/xdll.xxx
NO-NOTICE       ./templates/linux/xlib.xxx
NO-NOTICE       ./templates/message.xxx
NO-NOTICE       ./templates/name.xxx
NO-NOTICE       ./templates/prolog.xxx
NO-NOTICE       ./templates/property.xxx
NO-NOTICE       ./templates/version.xxx
NO-NOTICE       ./templates/xapp.xxx
NO-NOTICE       ./templates/xtool0.xxx
NO-NOTICE       ./templates/xtool1.xxx
NO-NOTICE       ./templates/xtool2.xxx
NO-NOTICE       ./templates/xtoolkit.xxx
NO-NOTICE       ./tools/mkxbvar.c
```

Files not covered by the scan (binary/data/help-text formats with no
header convention) fall under the tree-level distribution license:

```
  ./COPYING
  ./COPYING_LIB
  ./crtl/README
  ./demo/acolors.win
  ./demo/employee.dat
  ./demo/employee.win
  ./demo/gtk/apple-red.png
  ./demo/gtk/goalie.gif
  ./demo/gtk/icon.png
  ./demo/gtk/important.tiff
  ./demo/gtk/info.xpm
  ./demo/gtk/soccerball.gif
  ./demo/luigi.win
  ./demo/query.win
  ./demo/simple.win
  ./demo/xitmain.win
  ./doc/CHANGES
  ./doc/README.Linux
  ./help/amath.hlp
  ./help/changelog.hlp
  ./help/command.hlp
  ./help/index.hlp
  ./help/lang.hlp
  ./help/languagelist.hlp
  ./help/messagelist.hlp
  ./help/messages.hlp
  ./help/misc.hlp
  ./help/notes.hlp
  ./help/operator.hlp
  ./help/pde.hlp
  ./help/support.hlp
  ./help/xgr.hlp
  ./help/xst.hlp
  ./help/xui.hlp
  ./templates/copx.bin
  ./templates/zcharmap.bin
  ./tools/Makefile
```
