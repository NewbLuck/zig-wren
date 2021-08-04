const c = @import("c.zig");
usingnamespace @import("wren.zig");

// Common
pub extern fn wrenGetVersionNumber(...) c_int;
pub extern fn wrenInitConfiguration(configuration: [*c]Configuration) void;
pub extern fn wrenNewVM(configuration: [*c]Configuration) ?*VM;
pub extern fn wrenFreeVM(vm: ?*VM) void;
pub extern fn wrenCollectGarbage(vm: ?*VM) void;
pub extern fn wrenInterpret(vm: ?*VM, module: [*c]const u8, source: [*c]const u8) InterpretResult;
pub extern fn wrenMakeCallHandle(vm: ?*VM, signature: [*c]const u8) ?*Handle;
pub extern fn wrenCall(vm: ?*VM, method: ?*Handle) InterpretResult;
pub extern fn wrenReleaseHandle(vm: ?*VM, handle: ?*Handle) void;
pub extern fn wrenGetSlotCount(vm: ?*VM) c_int;
pub extern fn wrenEnsureSlots(vm: ?*VM, numSlots: c_int) void;
pub extern fn wrenGetSlotType(vm: ?*VM, slot: c_int) WrenType;
pub extern fn wrenGetSlotBool(vm: ?*VM, slot: c_int) bool;
pub extern fn wrenGetSlotBytes(vm: ?*VM, slot: c_int, length: [*c]c_int) [*c]const u8;
pub extern fn wrenGetSlotDouble(vm: ?*VM, slot: c_int) f64;
pub extern fn wrenGetSlotForeign(vm: ?*VM, slot: c_int) ?*c_void;
pub extern fn wrenGetSlotString(vm: ?*VM, slot: c_int) [*c]const u8;
pub extern fn wrenGetSlotHandle(vm: ?*VM, slot: c_int) ?*Handle;
pub extern fn wrenSetSlotBool(vm: ?*VM, slot: c_int, value: bool) void;
pub extern fn wrenSetSlotBytes(vm: ?*VM, slot: c_int, bytes: [*c]const u8, length: usize) void;
pub extern fn wrenSetSlotDouble(vm: ?*VM, slot: c_int, value: f64) void;
pub extern fn wrenSetSlotNewForeign(vm: ?*VM, slot: c_int, classSlot: c_int, size: usize) ?*c_void;
pub extern fn wrenSetSlotNewList(vm: ?*VM, slot: c_int) void;
pub extern fn wrenSetSlotNewMap(vm: ?*VM, slot: c_int) void;
pub extern fn wrenSetSlotNull(vm: ?*VM, slot: c_int) void;
pub extern fn wrenSetSlotString(vm: ?*VM, slot: c_int, text: [*c]const u8) void;
pub extern fn wrenSetSlotHandle(vm: ?*VM, slot: c_int, handle: ?*Handle) void;
pub extern fn wrenGetListCount(vm: ?*VM, slot: c_int) c_int;
pub extern fn wrenGetListElement(vm: ?*VM, listSlot: c_int, index: c_int, elementSlot: c_int) void;
pub extern fn wrenSetListElement(vm: ?*VM, listSlot: c_int, index: c_int, elementSlot: c_int) void;
pub extern fn wrenInsertInList(vm: ?*VM, listSlot: c_int, index: c_int, elementSlot: c_int) void;
pub extern fn wrenGetMapCount(vm: ?*VM, slot: c_int) c_int;
pub extern fn wrenGetMapContainsKey(vm: ?*VM, mapSlot: c_int, keySlot: c_int) bool;
pub extern fn wrenGetMapValue(vm: ?*VM, mapSlot: c_int, keySlot: c_int, valueSlot: c_int) void;
pub extern fn wrenSetMapValue(vm: ?*VM, mapSlot: c_int, keySlot: c_int, valueSlot: c_int) void;
pub extern fn wrenRemoveMapValue(vm: ?*VM, mapSlot: c_int, keySlot: c_int, removedValueSlot: c_int) void;
pub extern fn wrenGetVariable(vm: ?*VM, module: [*c]const u8, name: [*c]const u8, slot: c_int) void;
pub extern fn wrenHasVariable(vm: ?*VM, module: [*c]const u8, name: [*c]const u8) bool;
pub extern fn wrenHasModule(vm: ?*VM, module: [*c]const u8) bool;
pub extern fn wrenAbortFiber(vm: ?*VM, slot: c_int) void;
pub extern fn wrenGetUserData(vm: ?*VM) ?*c_void;
pub extern fn wrenSetUserData(vm: ?*VM, userData: ?*c_void) void;

// Meta extension
pub extern fn wrenMetaSource() [*c]const u8;
pub extern fn wrenMetaBindForeignMethod(vm: ?*VM, className: [*c]const u8, isStatic: bool, signature: [*c]const u8) ForeignMethodFn;

// Random extension
pub extern fn wrenRandomSource() [*c]const u8;
pub extern fn wrenRandomBindForeignClass(vm: ?*VM, module: [*c]const u8, className: [*c]const u8) ForeignClassMethods;
pub extern fn wrenRandomBindForeignMethod(vm: ?*VM, className: [*c]const u8, isStatic: bool, signature: [*c]const u8) ForeignMethodFn;
