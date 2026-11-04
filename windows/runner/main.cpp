#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <memory>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  constexpr wchar_t title[] = L"\u041A\u0418\u041F \u041F\u043E\u043C\u043E\u0449\u043D\u0438\u043A";
  // Preferences and the PDF index belong to one application in this Windows
  // session. Keep the handle alive until teardown; the OS releases it on crash.
  HANDLE instance_handle = ::CreateMutexW(nullptr, FALSE, L"Local\\KIPHelper.Desktop.Instance");
  const DWORD instance_error = ::GetLastError();
  if (!instance_handle) {
    ::MessageBoxW(nullptr, L"Cannot protect personal data: instance lock failed.", title, MB_OK | MB_ICONERROR);
    return EXIT_FAILURE;
  }
  const std::unique_ptr<void, decltype(&::CloseHandle)> instance_guard(instance_handle, ::CloseHandle);
  if (instance_error == ERROR_ALREADY_EXISTS) {
    const HWND existing = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", title);
    if (existing) {
      if (::IsIconic(existing)) ::ShowWindow(existing, SW_RESTORE);
      ::SetForegroundWindow(existing);
    }
    return EXIT_SUCCESS;
  }
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
  if (!window.Create(title, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
