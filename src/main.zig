const std = @import("std");
const minilib = @import("./minilib.zig");
const LinkedList = @import("./linked_list.zig").LinkedList;
const HashMap = @import("./hash_map.zig").HashMap;
const CountingAllocator = @import("./alloc.zig").CountingAllocator;

pub fn main() !void {
    // setup allocator for linked list
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const backup_allocator = gpa.allocator();
    defer _ = gpa.deinit();
    var counting_allocator = CountingAllocator.init(backup_allocator);
    const allocator = counting_allocator.allocator();

    // init I/O
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    // init the HashMap
    var linkedListArray: [10]LinkedList = undefined;
    var hashmap = HashMap.init(allocator, &linkedListArray);
    defer hashmap.deinit();

    // main loop
    var input: []const u8 = undefined;
    while (true) {
        try stdout.print("()> ", .{});
        input = stdin.readUntilDelimiterAlloc(allocator, '\n', 4096) catch {
            minilib.flush(stdin);
            continue;
        };
        defer allocator.free(input);
        switch (try minilib.exec(input, &hashmap, counting_allocator)) {
            0 => void{},
            1 => try stdout.print("{s}: command not found...\n", .{input}),
            2 => try stdout.print("commands: help, show, clear, heap, add, del, exit\n", .{}),
            3 => return,
            4 => try stdout.print("{s}: missing argument...\n", .{input}),
            else => try stdout.print("shouldn't print this :)\n", .{}),
        }
    }
}
