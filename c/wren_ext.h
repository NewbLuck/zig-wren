#ifndef wrenex_h
#define wrenex_h

#include <stdarg.h>
#include <stdlib.h>
#include <stdbool.h>

#include "wren.h"

//EXTENSTION: Returns the key into the [keySlot] and value into [valueSlot] of the
// map in [mapSlot] at the map index of [index]
WREN_API void wrenGetMapElement(WrenVM *vm, int mapSlot, int index, int keySlot, int valueSlot);

#endif