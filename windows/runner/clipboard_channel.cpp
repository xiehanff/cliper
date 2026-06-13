#include "clipboard_channel.h"

#include <windows.h>
#include <shellapi.h>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <vector>
#include <string>

namespace cliper {

namespace {

std::vector<std::string> GetClipboardFilePaths() {
  std::vector<std::string> paths;

  if (!OpenClipboard(nullptr)) {
    return paths;
  }

  HDROP hDrop = static_cast<HDROP>(GetClipboardData(CF_HDROP));
  if (hDrop == nullptr) {
    // Fallback to registered FileNameW format for single-file scenarios.
    UINT fileNameFormat = RegisterClipboardFormatW(L"FileNameW");
    if (fileNameFormat != 0) {
      HANDLE handle = GetClipboardData(fileNameFormat);
      if (handle != nullptr) {
        const wchar_t* data = static_cast<const wchar_t*>(GlobalLock(handle));
        if (data != nullptr) {
          int len = WideCharToMultiByte(CP_UTF8, 0, data, -1, nullptr, 0, nullptr, nullptr);
          if (len > 0) {
            std::string path(len - 1, '\0');
            WideCharToMultiByte(CP_UTF8, 0, data, -1, &path[0], len, nullptr, nullptr);
            paths.push_back(path);
          }
          GlobalUnlock(handle);
        }
      }
    }
    CloseClipboard();
    return paths;
  }

  UINT fileCount = DragQueryFileW(hDrop, 0xFFFFFFFF, nullptr, 0);
  for (UINT i = 0; i < fileCount; ++i) {
    UINT length = DragQueryFileW(hDrop, i, nullptr, 0);
    if (length == 0) continue;

    std::vector<wchar_t> buffer(length + 1);
    DragQueryFileW(hDrop, i, buffer.data(), length + 1);

    int utf8Len = WideCharToMultiByte(CP_UTF8, 0, buffer.data(), -1, nullptr, 0, nullptr, nullptr);
    if (utf8Len > 0) {
      std::string path(utf8Len - 1, '\0');
      WideCharToMultiByte(CP_UTF8, 0, buffer.data(), -1, &path[0], utf8Len, nullptr, nullptr);
      paths.push_back(path);
    }
  }

  CloseClipboard();
  return paths;
}

}  // namespace

void RegisterClipboardChannel(flutter::BinaryMessenger* messenger) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.example.cliper/clipboard",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "getFilePaths") {
          std::vector<std::string> paths = GetClipboardFilePaths();
          flutter::EncodableList list;
          for (const auto& path : paths) {
            list.push_back(flutter::EncodableValue(path));
          }
          result->Success(flutter::EncodableValue(list));
        } else {
          result->NotImplemented();
        }
      });

  // Keep channel alive for the lifetime of the application.
  static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_channel;
  g_channel = std::move(channel);
}

}  // namespace cliper
