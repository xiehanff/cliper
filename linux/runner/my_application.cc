#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include <glib.h>

#include "flutter/generated_plugin_registrant.h"

namespace {

gchar* get_executable_path() { return g_file_read_link("/proc/self/exe", nullptr); }

gchar* get_icon_path() {
  g_autofree gchar* executable_path = get_executable_path();
  if (executable_path == nullptr) {
    return nullptr;
  }

  g_autofree gchar* executable_dir = g_path_get_dirname(executable_path);
  return g_build_filename(executable_dir, "data", "flutter_assets", "assets",
                          "icon.png", nullptr);
}

void ensure_icon_theme_entry() {
  g_autofree gchar* icon_path = get_icon_path();
  if (icon_path == nullptr || !g_file_test(icon_path, G_FILE_TEST_EXISTS)) {
    return;
  }

  g_autofree gchar* icon_dir = g_build_filename(
      g_get_user_data_dir(), "icons", "hicolor", "256x256", "apps", nullptr);
  if (g_mkdir_with_parents(icon_dir, 0755) != 0) {
    return;
  }

  const gchar* icon_names[] = {APPLICATION_ID, "cliper"};
  for (const gchar* icon_name : icon_names) {
    g_autofree gchar* icon_file_name = g_strconcat(icon_name, ".png", nullptr);
    g_autofree gchar* target_icon_path =
        g_build_filename(icon_dir, icon_file_name, nullptr);
    g_autoptr(GError) error = nullptr;
    g_autoptr(GFile) source_file = g_file_new_for_path(icon_path);
    g_autoptr(GFile) target_file = g_file_new_for_path(target_icon_path);
    g_file_copy(source_file, target_file, G_FILE_COPY_OVERWRITE, nullptr,
                nullptr, nullptr, &error);
    if (error != nullptr) {
      g_warning("Failed to install app icon: %s", error->message);
    }
  }
}

void write_desktop_entry(const gchar* desktop_id, const gchar* icon_name,
                         const gchar* startup_wm_class,
                         const gchar* executable_path,
                         const gchar* applications_dir) {
  g_autofree gchar* desktop_file_name = g_strconcat(desktop_id, ".desktop", nullptr);
  g_autofree gchar* desktop_file_path =
      g_build_filename(applications_dir, desktop_file_name, nullptr);
  g_autofree gchar* desktop_entry = g_strdup_printf(
      "[Desktop Entry]\n"
      "Version=1.0\n"
      "Type=Application\n"
      "Name=CLIPER\n"
      "Comment=Clipboard history manager\n"
      "Exec=%s\n"
      "Icon=%s\n"
      "Terminal=false\n"
      "Categories=Utility;\n"
      "StartupNotify=true\n"
      "StartupWMClass=%s\n"
      "X-GNOME-WMClass=%s\n",
      executable_path, icon_name, startup_wm_class, startup_wm_class);

  g_file_set_contents(desktop_file_path, desktop_entry, -1, nullptr);
}

void ensure_desktop_entry() {
  g_autofree gchar* executable_path = get_executable_path();
  if (executable_path == nullptr) {
    return;
  }

  // The installed .deb already ships a system desktop entry and icon.
  if (g_str_has_prefix(executable_path, "/opt/cliper/")) {
    return;
  }

  ensure_icon_theme_entry();

  g_autofree gchar* applications_dir =
      g_build_filename(g_get_user_data_dir(), "applications", nullptr);
  if (g_mkdir_with_parents(applications_dir, 0755) != 0) {
    return;
  }

  write_desktop_entry(APPLICATION_ID, APPLICATION_ID, APPLICATION_ID,
                      executable_path, applications_dir);
  write_desktop_entry("cliper", "cliper", "cliper", executable_path,
                      applications_dir);
}

void apply_window_icon(GtkWindow* window) {
  g_autofree gchar* icon_path = get_icon_path();

  if (icon_path == nullptr || !g_file_test(icon_path, G_FILE_TEST_EXISTS)) {
    return;
  }

  g_autoptr(GError) error = nullptr;
  gtk_window_set_default_icon_name(APPLICATION_ID);
  gtk_window_set_icon_name(window, APPLICATION_ID);
  gtk_window_set_default_icon_from_file(icon_path, &error);
  if (error != nullptr) {
    g_warning("Failed to set default app icon: %s", error->message);
    g_clear_error(&error);
  }

  gtk_window_set_icon_from_file(window, icon_path, &error);
  if (error != nullptr) {
    g_warning("Failed to set app icon: %s", error->message);
  }
}

}  // namespace

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "CLIPER");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "CLIPER");
  }

  apply_window_icon(window);

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.
  ensure_desktop_entry();

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);
  g_set_application_name("CLIPER");
  gdk_set_program_class(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
