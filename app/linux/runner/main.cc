#include "my_application.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// WSLg's Wayland compositor (weston over RDP) frequently terminates GTK/Flutter
// clients with "Error 71 (Protocol error)" or Gdk device assertion failures.
// Prefer X11/XWayland when unset so `flutter run -d linux` stays visible.
static int running_under_wsl(void) {
  const char* distro = getenv("WSL_DISTRO_NAME");
  if (distro != NULL && distro[0] != '\0') {
    return 1;
  }

  FILE* version = fopen("/proc/version", "r");
  if (version == NULL) {
    return 0;
  }

  char line[512];
  int is_wsl = 0;
  if (fgets(line, sizeof(line), version) != NULL) {
    if (strstr(line, "Microsoft") != NULL || strstr(line, "microsoft") != NULL ||
        strstr(line, "WSL") != NULL) {
      is_wsl = 1;
    }
  }
  fclose(version);
  return is_wsl;
}

static void prefer_x11_on_wslg(void) {
  if (getenv("GDK_BACKEND") != NULL) {
    return;
  }
  if (!running_under_wsl()) {
    return;
  }
  setenv("GDK_BACKEND", "x11", /*overwrite=*/0);
}

int main(int argc, char** argv) {
  prefer_x11_on_wslg();
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
