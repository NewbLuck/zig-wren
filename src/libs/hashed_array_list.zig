const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

/// HashMap of ArrayLists
pub fn HashedArrayList(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        alloc: *Allocator,
        hash: AutoHashMap(K, *ArrayList(V)),

        pub const Size = u32;
        pub const Entry = struct {
            key_ptr: *K,
            value_ptr: *V,
        };

        pub fn init(allocator: *Allocator) Self {
            return Self{
                .alloc = allocator,
                .hash = AutoHashMap(K, *ArrayList(V)).init(allocator),
            };
        }
        pub fn deinit(self: *Self) void {
            var it = self.hash.keyIterator();
            while (it.next()) |key| {
                var ar_ptr = self.hash.get(key.*).?;
                ar_ptr.deinit();
                self.alloc.destroy(ar_ptr);
            }
            self.hash.deinit();
        }

        /// Get backing ArrayList for key, or null.
        pub fn getKey(self: *Self, key: K) ?*ArrayList(V) {
            if (self.hash.get(key)) |al_ptr| {
                return al_ptr;
            }
            return null;
        }

        /// Try to get backing ArrayList for key, creating it if it does not exist.
        pub fn getOrPutKey(self: *Self, key: K) !*ArrayList(V) {
            if (self.hash.get(key)) |al_ptr| {
                return al_ptr;
            } else {
                var new_ptr = try self.alloc.create(ArrayList(V));
                new_ptr.* = ArrayList(V).init(self.alloc);
                try self.hash.putNoClobber(key, new_ptr);
                return new_ptr;
            }
        }

        /// Removes the key and backing ArrayList, if the key exists.
        /// Does nothing if the key does not exist.
        /// Returns whether it removed a key or not.
        pub fn removeKey(self: *Self, key: K) bool {
            if (self.getKey(key)) |al_ptr| {
                // If we have an entry, purge the ArrayList and remove key
                al_ptr.deinit();
                self.alloc.destroy(al_ptr);
                return self.hash.remove(key);
            }
            return false;
        }

        /// Removes the key and backing ArrayList if the key exists.
        /// Does nothing if the key does not exist.
        /// Returns the owned slice of the arraylist.
        pub fn removeAndReturnOwned(self: *Self, key: K) ?ArrayList(V).Slice {
            if (self.getKey(key)) |al_ptr| {
                var slice = al_ptr.toOwnedSlice();
                al_ptr.deinit();
                self.alloc.destroy(al_ptr);
                return slice;
            }
            return null;
        }

        /// Extend the list by 1 element. Allocates more memory as necessary.
        /// Creates key if it does not exist.
        pub fn append(self: *Self, key: K, item: V) !void {
            var arr = try self.getOrPutKey(key);
            try arr.append(item);
        }

        /// Append the slice of items to the list. Allocates more memory as necessary.
        /// Creates key if it does not exist.
        pub fn appendSlice(self: *Self, key: K, items: []const V) !void {
            var arr = try self.getOrPutKey(key);
            try arr.appendSlice(items);
        }

        /// Insert item at index n by moving list[n .. list.len] to make room.
        /// This operation is O(N).
        /// Creates key if it does not exist.
        pub fn insert(self: *Self, key: K, n: usize, item: V) !void {
            var arr = try self.getOrPutKey(key);
            try arr.insert(n, item);
        }

        /// Insert slice items at index i by moving list[i .. list.len] to make room.
        /// This operation is O(N).
        /// Creates key if it does not exist.
        pub fn insertSlice(self: *Self, key: K, n: usize, items: []const V) !void {
            var arr = try self.getOrPutKey(key);
            try arr.insertSlice(n, items);
        }

        /// Remove the element at index i, shift elements after index i forward, and return the removed element.
        /// Asserts the array has at least one item.
        /// Invalidates pointers to end of list.
        /// This operation is O(N).
        pub fn orderedRemove(self: *Self, key: K, i: usize) V {
            var arr = self.getOrPutKey(key) catch unreachable;
            return arr.orderedRemove(i);
        }

        /// Removes the element at the specified index and returns it.
        /// The empty slot is filled from the end of the list.
        /// This operation is O(1).
        pub fn swapRemove(self: *Self, key: K, i: usize) V {
            var arr = self.getOrPutKey(key) catch unreachable;
            return arr.swapRemove(i);
        }

        /// The caller owns the returned memory. Empties this ArrayList.
        /// Leaves the key behind.
        pub fn toOwnedSlice(self: *Self, key: K) ArrayList(V).Slice {
            var arr = self.getOrPutKey(key) catch unreachable;
            return arr.toOwnedSlice();
        }

        /// Remove and return the last element from the list.
        /// Asserts the list has at least one item.
        /// Invalidates pointers to the removed element.
        pub fn pop(self: *Self, key: K) V {
            var arr = self.getOrPutKey(key) catch unreachable;
            return arr.pop();
        }

        /// Remove and return the last element from the list, or return null if list is empty.
        /// Invalidates pointers to the removed element, if any.
        pub fn popOrNull(self: *Self, key: K) ?V {
            var arr = self.getOrPutKey(key) catch unreachable;
            return arr.popOrNull();
        }

        //TODO: Unimplemented
        //  replaceRange
        //  replaceRange
        //  appendNTimes
        //  clearAndFree
        //  addOne (returns type.*)

        /// Key iterator
        pub fn iterator(self: *Self) Iterator {
            return self.hash.iterator();
        }

        /// Iterator that iterates over all possible K,V pairs for every V.
        pub fn flatIterator(self: *Self) FlatIterator {
            return .{
                .target = self,
                //.hm = &self.hash,
                .ki = self.hash.iterator(),
            };
        }

        pub const FlatIterator = struct {
            target: *Self,
            //hm: *AutoHashMap(K,*ArrayList(V)),
            vindex: Size = 0,
            ki: AutoHashMap(K, *ArrayList(V)).Iterator,
            ci: AutoHashMap(K, *ArrayList(V)).Entry = undefined,
            fetch: bool = true,

            pub fn next(it: *FlatIterator) ?Entry {
                if (it.fetch) {
                    if (it.ki.next()) |nx| {
                        it.ci = nx;
                    } else {
                        return null;
                    }
                    it.fetch = false;
                }

                const key = it.ci.key_ptr;
                const value = &it.ci.value_ptr.*.items[it.vindex];

                if (it.vindex >= it.ci.value_ptr.*.items.len - 1) {
                    it.vindex = 0;
                    it.fetch = true;
                } else {
                    it.vindex += 1;
                    it.fetch = false;
                }

                return Entry{ .key_ptr = key, .value_ptr = value };
            }
        };
    };
}

test "Basic operation" {
    const hal = &HashedArrayList(u8, u8).init(std.testing.allocator);
    defer hal.deinit();
    hal.append(1, 1) catch unreachable;
    hal.append(2, 1) catch unreachable;
    hal.append(2, 2) catch unreachable;
    hal.append(2, 3) catch unreachable;
    hal.append(3, 1) catch unreachable;
    hal.append(3, 2) catch unreachable;
    hal.append(3, 3) catch unreachable;
    hal.append(3, 4) catch unreachable;
    hal.append(4, 1) catch unreachable;
    try expect(hal.getKey(3).?.items[2] == 3);

    const ha3 = hal.*.getOrPutKey(3) catch unreachable;
    try expect(ha3.items[1] == 2);

    const ha4 = hal.*.getOrPutKey(5) catch unreachable;
    ha4.append('S') catch unreachable;
    try expect(ha4.items[0] == 'S');

    try expect(hal.removeKey(2));

    try expect(hal.getKey(2) == null);

    hal.appendSlice(5, "PAM") catch unreachable;
    const ha9 = hal.*.getKey(5).?;
    try expect(ha9.items[0] == 'S');
    try expect(ha9.items[1] == 'P');
    try expect(ha9.items[2] == 'A');
    try expect(ha9.items[3] == 'M');

    try expect(hal.pop(5) == 'M');
    try expect(hal.popOrNull(5).? == 'A');
    try expect(hal.popOrNull(5).? == 'P');
    try expect(hal.popOrNull(5).? == 'S');
    try expect(hal.popOrNull(5) == null);
}

test "Iterators" {
    const hal = &HashedArrayList(u8, u8).init(std.testing.allocator);
    defer hal.deinit();
    hal.append(1, 1) catch unreachable;
    hal.append(2, 1) catch unreachable;
    hal.append(2, 2) catch unreachable;
    hal.append(2, 3) catch unreachable;
    hal.append(3, 1) catch unreachable;
    hal.append(3, 2) catch unreachable;
    hal.append(3, 3) catch unreachable;
    hal.append(3, 4) catch unreachable;
    hal.append(4, 1) catch unreachable;

    std.debug.print("KEYS:\n", .{});
    const it = &hal.hash.iterator();
    while (it.next()) |item| {
        std.debug.print(">>> {}\n", .{item.key_ptr.*});
    }

    var ctr: u8 = 0;
    std.debug.print("FLAT:\n", .{});
    const it2 = &hal.flatIterator();
    while (it2.next()) |item| {
        ctr += 1;
        std.debug.print(">>> {} -> {}\n", .{ item.key_ptr.*, item.value_ptr.* });
    }
    try expect(ctr == 9);
}
