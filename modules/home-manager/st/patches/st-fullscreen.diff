diff -r -u a/config.def.h b/config.def.h
--- a/config.def.h	2022-01-07 06:41:35.000000000 -0500
+++ b/config.def.h	2022-01-15 13:32:01.644320198 -0500
@@ -201,6 +201,8 @@
 	{ TERMMOD,              XK_Y,           selpaste,       {.i =  0} },
 	{ ShiftMask,            XK_Insert,      selpaste,       {.i =  0} },
 	{ TERMMOD,              XK_Num_Lock,    numlock,        {.i =  0} },
+	{ XK_NO_MOD,            XK_F11,         fullscreen,     {.i =  0} },
+	{ MODKEY,               XK_Return,      fullscreen,     {.i =  0} },
 };
 
 /*
diff -r -u a/st.h b/st.h
--- a/st.h	2022-01-07 06:41:35.000000000 -0500
+++ b/st.h	2022-01-15 13:32:40.084320514 -0500
@@ -81,6 +81,7 @@
 void redraw(void);
 void draw(void);
 
+void fullscreen(const Arg *);
 void printscreen(const Arg *);
 void printsel(const Arg *);
 void sendbreak(const Arg *);
diff -r -u a/x.c b/x.c
--- a/x.c	2022-01-07 06:41:35.000000000 -0500
+++ b/x.c	2022-01-15 13:50:28.164329295 -0500
@@ -94,6 +94,7 @@
 	Drawable buf;
 	GlyphFontSpec *specbuf; /* font spec buffer used for rendering */
 	Atom xembed, wmdeletewin, netwmname, netwmiconname, netwmpid;
+	Atom netwmstate, netwmfullscreen;
 	struct {
 		XIM xim;
 		XIC xic;
@@ -744,6 +745,24 @@
 	xw.specbuf = xrealloc(xw.specbuf, col * sizeof(GlyphFontSpec));
 }
 
+void
+fullscreen(const Arg *arg)
+{
+	XEvent ev;
+
+	memset(&ev, 0, sizeof(ev));
+	
+	ev.xclient.type = ClientMessage;
+	ev.xclient.message_type = xw.netwmstate;
+	ev.xclient.display = xw.dpy;
+	ev.xclient.window = xw.win;
+	ev.xclient.format = 32;
+	ev.xclient.data.l[0] = 2; /* _NET_WM_STATE_TOGGLE */
+	ev.xclient.data.l[1] = xw.netwmfullscreen;
+
+	XSendEvent(xw.dpy, DefaultRootWindow(xw.dpy), False, SubstructureNotifyMask|SubstructureRedirectMask, &ev);
+}
+
 ushort
 sixd_to_16bit(int x)
 {
@@ -1208,6 +1227,9 @@
 	XChangeProperty(xw.dpy, xw.win, xw.netwmpid, XA_CARDINAL, 32,
 			PropModeReplace, (uchar *)&thispid, 1);
 
+	xw.netwmstate = XInternAtom(xw.dpy, "_NET_WM_STATE", False);
+	xw.netwmfullscreen = XInternAtom(xw.dpy, "_NET_WM_STATE_FULLSCREEN", False);
+
 	win.mode = MODE_NUMLOCK;
 	resettitle();
 	xhints();
