#include "elon_ffi.h"

FFI_PLUGIN_EXPORT intptr_t sum(intptr_t a, intptr_t b) {
#ifdef DEBUG
  return a + b + 1000;
#else
  return a + b;
#endif
}

FFI_PLUGIN_EXPORT intptr_t sum_long_running(intptr_t a, intptr_t b) {
  // Simulate work.
#if _WIN32
  Sleep(5000);
#else
  usleep(5000 * 1000);
#endif
  return a + b;
}
