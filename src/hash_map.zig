const std = @import("std");
const LinkedList = @import("./linked_list.zig").LinkedList;
const print = std.debug.print;

pub const HashMap = struct {
    table: []LinkedList,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, table: []LinkedList) HashMap {
        var hash = HashMap{ .table = undefined, .allocator = undefined };
        hash.allocator = allocator;
        hash.table = table;
        for (table) |*t| {
            t.* = LinkedList.init(allocator);
        }
        return hash;
    }

    pub fn deinit(self: *HashMap) void {
        for (self.table) |*t| {
            t.*.deinit();
        }
    }

    pub fn show(self: *HashMap) void {
        for (self.table) |*t, index| {
            if (t.length == 0) {
                print("[{d}]: {{}}\n", .{index + 1});
            } else {
                print("[{d}]: {{\n", .{index + 1});
                t.show();
                print("}}\n", .{});
            }
        }
    }

    /// add entry to the hashmap
    pub fn add(self: *HashMap, data: []const u8) !void {
        const index = self.getValue(data);
        try self.table[index].add(data);
    }

    /// delete entry from hashmap
    pub fn del(self: *HashMap, data: []const u8) !void {
        const index = self.getValue(data);
        try self.table[index].del(data);
    }

    /// way to calcul index from data
    pub fn getValue(self: *HashMap, data: []const u8) usize {
        var sum: usize = 0;
        for (data) |c| {
            sum += c;
        }
        return sum % self.table.len;
    }
};

test "createHash" {
    print("\n", .{});
    // init allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var array: [10]LinkedList = undefined;
    var hashm = HashMap.init(allocator, &array);
    defer hashm.deinit();
    try hashm.add("Simon");
    try hashm.add("Jean");
    hashm.show();
    try hashm.del("Simon");
    hashm.show();
    print("HashMap DONE\n", .{});
}
