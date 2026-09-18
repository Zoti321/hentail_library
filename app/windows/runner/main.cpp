#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// The window is shown on the first Flutter frame, which happens before any
// Dart-side window setup can run. Place it before the message loop starts so
// the user never sees the window at its creation position.
void CenterWindowOnWorkArea(HWND hwnd) {
  RECT window_rect;
  if (!::GetWindowRect(hwnd, &window_rect)) {
    return;
  }

  MONITORINFO monitor_info = {};
  monitor_info.cbSize = sizeof(MONITORINFO);
  if (!::GetMonitorInfo(::MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST),
                        &monitor_info)) {
    return;
  }

  const RECT& work_area = monitor_info.rcWork;
  const LONG x = work_area.left + ((work_area.right - work_area.left) -
                                   (window_rect.right - window_rect.left)) /
                                      2;
  const LONG y = work_area.top + ((work_area.bottom - work_area.top) -
                                  (window_rect.bottom - window_rect.top)) /
                                     2;
  ::SetWindowPos(hwnd, nullptr, x, y, 0, 0,
                 SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
#ifdef APP_DATA_PROFILE_DEV
  const wchar_t *window_title = L"Hentai Library [dev]";
#else
  const wchar_t *window_title = L"Hentai Library";
#endif
  if (!window.Create(window_title, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);
  CenterWindowOnWorkArea(window.GetHandle());

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
