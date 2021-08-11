#include <stdarg.h>
#include <string.h>

#include "wren.h"
#include "wren_common.h"
#include "wren_compiler.h"
#include "wren_core.h"
#include "wren_debug.h"
#include "wren_primitive.h"
#include "wren_vm.h"

#if WREN_OPT_META
#include "wren_opt_meta.h"
#endif
#if WREN_OPT_RANDOM
#include "wren_opt_random.h"
#endif

#if WREN_DEBUG_TRACE_MEMORY || WREN_DEBUG_TRACE_GC
#include <time.h>
#include <stdio.h>
#endif

// Ensures that [slot] is a valid index into the API's stack of slots.
static void validateApiSlot(WrenVM *vm, int slot)
{
    ASSERT(slot >= 0, "Slot cannot be negative.");
    ASSERT(slot < wrenGetSlotCount(vm), "Not that many slots.");
}

void wrenGetMapElement(WrenVM *vm, int mapSlot, int index, int keySlot, int valueSlot)
{
    validateApiSlot(vm, mapSlot);
    validateApiSlot(vm, keySlot);
    validateApiSlot(vm, valueSlot);
    ASSERT(IS_MAP(vm->apiStack[mapSlot]), "Slot must hold a map.");

    ObjMap *map = AS_MAP(vm->apiStack[mapSlot]);

    uint32_t usedIndex = wrenValidateIndex(map->count, index);
    ASSERT(usedIndex != UINT32_MAX, "Index out of bounds.");

    uint32_t idx = 0;
    uint32_t cdx = 0;
    do
    {
        MapEntry *entry = &map->entries[idx];
        if (IS_UNDEFINED(entry->key))
        {
            if (IS_FALSE(entry->value))
            {
                ASSERT(false, "Map index iterated OOB");
            }
        }
        else
        {
            if (cdx == index)
            {
                // Return k,v
                Value key = entry->key;
                Value value = entry->value;
                if (IS_UNDEFINED(value))
                {
                    value = NULL_VAL;
                }
                vm->apiStack[keySlot] = key;
                vm->apiStack[valueSlot] = value;
                return;
            }
            cdx = cdx + 1;
        }
        idx = idx + 1;
    } while (idx < map->capacity);
    ASSERT(false, "Map container iterated OOB");
}