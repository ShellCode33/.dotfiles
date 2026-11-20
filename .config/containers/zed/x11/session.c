/* Keep Zed fitted to one isolated Xephyr screen. No decorations, key bindings,
 * layout engine, timer, or general-purpose window-manager protocol emulation.
 * DWM (or another host WM) controls the outer window and fullscreen state. */
#define _POSIX_C_SOURCE 200809L
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/Xutil.h>
#include <X11/extensions/Xrandr.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/signalfd.h>
#include <sys/wait.h>
#include <unistd.h>

static Display *display;
static Window root;
static Atom window_type, normal_type, active_window, protocols, take_focus;
static unsigned int width, height;

static int xerror(Display *d, XErrorEvent *e)
{
    /* Windows may disappear between notification and query. */
    if (e->error_code != BadWindow && e->error_code != BadDrawable &&
        e->error_code != BadMatch) {
        char message[128];
        XGetErrorText(d, e->error_code, message, sizeof(message));
        fprintf(stderr, "zed-box: X11 sizing helper: %s\n", message);
    }
    return 0;
}

static int visible(Window window, XWindowAttributes *attributes)
{
    return XGetWindowAttributes(display, window, attributes) &&
        attributes->map_state == IsViewable && !attributes->override_redirect &&
        attributes->class == InputOutput;
}

static void fit(Window window)
{
    XWindowAttributes attributes;
    XClassHint hint = {0};
    Window transient;
    if (!visible(window, &attributes) ||
        XGetTransientForHint(display, window, &transient)) return;
    if (!XGetClassHint(display, window, &hint)) return;
    int editor = hint.res_class && !strcmp(hint.res_class, "dev.zed.Zed");
    if (hint.res_name) XFree(hint.res_name);
    if (hint.res_class) XFree(hint.res_class);
    if (!editor) return;

    Atom actual;
    int format;
    unsigned long count, remaining;
    unsigned char *data = NULL;
    int normal = 1;
    if (XGetWindowProperty(display, window, window_type, 0, 1, False, XA_ATOM,
                           &actual, &format, &count, &remaining, &data) == Success &&
        actual == XA_ATOM && format == 32 && count)
        normal = *(Atom *)data == normal_type;
    if (data) XFree(data);
    if (!normal) return;
    if (attributes.border_width) XSetWindowBorderWidth(display, window, 0);
    if (attributes.x || attributes.y || attributes.width != (int)width ||
        attributes.height != (int)height)
        XMoveResizeWindow(display, window, 0, 0, width, height);
}

static void focus(Window window, Time timestamp)
{
    XWindowAttributes attributes;
    if (!visible(window, &attributes)) return;
    XWMHints *hints = XGetWMHints(display, window);
    if (!hints || !(hints->flags & InputHint) || hints->input)
        XSetInputFocus(display, window, RevertToParent, timestamp);
    if (hints) XFree(hints);
    Atom *supported = NULL;
    int count = 0;
    if (XGetWMProtocols(display, window, &supported, &count)) {
        for (int i = 0; i < count; ++i) {
            if (supported[i] == take_focus) {
                XEvent message = {0};
                message.xclient.type = ClientMessage;
                message.xclient.window = window;
                message.xclient.message_type = protocols;
                message.xclient.format = 32;
                message.xclient.data.l[0] = (long)take_focus;
                message.xclient.data.l[1] = (long)timestamp;
                XSendEvent(display, window, False, NoEventMask, &message);
                break;
            }
        }
        XFree(supported);
    }
}

static void scan(int restore_focus)
{
    Window ignored_root, parent, *children = NULL;
    unsigned int count;
    if (!XQueryTree(display, root, &ignored_root, &parent, &children, &count)) return;
    Window top = None;
    for (unsigned int i = 0; i < count; ++i) {
        XWindowAttributes attributes;
        XSelectInput(display, children[i], PropertyChangeMask);
        fit(children[i]);
        if (visible(children[i], &attributes)) top = children[i];
    }
    if (restore_focus && top != None) focus(top, CurrentTime);
    if (children) XFree(children);
}

static void screen_changed(void)
{
    /* A full query refreshes Xephyr's otherwise stale virtual output bounds. */
    XRRScreenResources *resources = XRRGetScreenResources(display, root);
    if (resources) XRRFreeScreenResources(resources);
    XWindowAttributes attributes;
    if (!XGetWindowAttributes(display, root, &attributes)) return;
    width = (unsigned int)attributes.width;
    height = (unsigned int)attributes.height;
    scan(0);
}

int main(int argc, char **argv)
{
    display = XOpenDisplay(NULL);
    if (!display) {
        fputs("zed-box: cannot authenticate/connect to the isolated X11 display\n", stderr);
        return 1;
    }
    XSetErrorHandler(xerror);
    root = DefaultRootWindow(display);
    window_type = XInternAtom(display, "_NET_WM_WINDOW_TYPE", False);
    normal_type = XInternAtom(display, "_NET_WM_WINDOW_TYPE_NORMAL", False);
    active_window = XInternAtom(display, "_NET_ACTIVE_WINDOW", False);
    protocols = XInternAtom(display, "WM_PROTOCOLS", False);
    take_focus = XInternAtom(display, "WM_TAKE_FOCUS", False);
    XSelectInput(display, root, StructureNotifyMask | SubstructureNotifyMask);
    screen_changed();
    XSync(display, False); /* Subscribe before Zed can create its first window. */

    sigset_t signals, previous;
    sigemptyset(&signals);
    sigaddset(&signals, SIGCHLD);
    sigaddset(&signals, SIGTERM);
    sigaddset(&signals, SIGINT);
    sigaddset(&signals, SIGHUP);
    if (sigprocmask(SIG_BLOCK, &signals, &previous) < 0) { perror("sigprocmask"); return 1; }
    int signal_fd = signalfd(-1, &signals, SFD_CLOEXEC);
    if (signal_fd < 0) { perror("signalfd"); return 1; }
    fcntl(ConnectionNumber(display), F_SETFD, FD_CLOEXEC);
    char **command = calloc((size_t)argc + 2, sizeof(*command));
    if (!command) { perror("calloc"); return 1; }
    command[0] = "/opt/zed.app/bin/zed";
    command[1] = "--foreground";
    for (int i = 1; i < argc; ++i) command[i + 1] = argv[i];
    pid_t child = fork();
    if (child < 0) { perror("fork"); return 1; }
    if (!child) {
        setpgid(0, 0);
        sigprocmask(SIG_SETMASK, &previous, NULL);
        execv(command[0], command);
        perror("zed-box: launch Zed");
        _exit(127);
    }
    free(command);
    setpgid(child, child);
    struct pollfd fds[] = {{ConnectionNumber(display), POLLIN, 0}, {signal_fd, POLLIN, 0}};
    for (;;) {
        while (XPending(display)) {
            XEvent event;
            XNextEvent(display, &event);
            if (event.type == ConfigureNotify && event.xconfigure.window == root)
                screen_changed();
            else if (event.type == CreateNotify)
                XSelectInput(display, event.xcreatewindow.window, PropertyChangeMask);
            else if (event.type == MapNotify && !event.xmap.override_redirect) {
                fit(event.xmap.window);
                focus(event.xmap.window, CurrentTime);
            } else if (event.type == UnmapNotify || event.type == DestroyNotify)
                scan(1);
            else if (event.type == PropertyNotify &&
                     (event.xproperty.atom == XA_WM_CLASS ||
                      event.xproperty.atom == XA_WM_TRANSIENT_FOR ||
                      event.xproperty.atom == window_type))
                fit(event.xproperty.window);
            else if (event.type == ClientMessage && event.xclient.message_type == active_window) {
                XRaiseWindow(display, event.xclient.window);
                focus(event.xclient.window, (Time)event.xclient.data.l[1]);
            }
        }
        XFlush(display);
        if (poll(fds, 2, -1) < 0) {
            if (errno == EINTR) continue;
            perror("poll");
            kill(-child, SIGTERM);
            return 1;
        }
        if (fds[1].revents & POLLIN) {
            struct signalfd_siginfo info;
            if (read(signal_fd, &info, sizeof(info)) != sizeof(info)) continue;
            if (info.ssi_signo == SIGCHLD) {
                int status;
                if (waitpid(child, &status, WNOHANG) == child) {
                    close(signal_fd);
                    XCloseDisplay(display);
                    return WIFEXITED(status) ? WEXITSTATUS(status) : 128 + WTERMSIG(status);
                }
            } else kill(-child, (int)info.ssi_signo);
        }
    }
}
