#ifndef CLIPBOARD_CHANNEL_H_
#define CLIPBOARD_CHANNEL_H_

#include <flutter/binary_messenger.h>

namespace cliper {

void RegisterClipboardChannel(flutter::BinaryMessenger* messenger);

}  // namespace cliper

#endif  // CLIPBOARD_CHANNEL_H_
