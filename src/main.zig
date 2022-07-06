const std = @import("std");
const LinkedList = @import("./linked_list.zig").LinkedList;
const HashMap = @import("./hash_map.zig").HashMap;
const CountingAllocator = @import("./alloc.zig").CountingAllocator;

/// flush stdin
pub fn flush(stdin: std.io.Reader(std.fs.File, std.os.ReadError, std.fs.File.read)) void {
    var buf: [256]u8 = undefined;
    while (true) {
        _ = stdin.readUntilDelimiter(&buf, '\n') catch |err| switch (err) {
            error.StreamTooLong => continue, // keep reading data
            else => return, // give up on I/O errors
        };
        break; // everything up to newline has been read
    }
}

/// shortcut to compare two string
pub fn cmp(str1: []const u8, str2: []const u8) bool {
    return std.mem.containsAtLeast(u8, str1, 1, str2);
}

/// check command and execute it
pub fn exec(cmd: []const u8, hash: *HashMap, allocator: CountingAllocator) !u8 {
    if (cmp(cmd, "exit")) {
        return 3;
    } else if (cmp(cmd, "help")) {
        return 2;
    } else if (cmp(cmd, "show")) {
        hash.show();
    } else if (cmp(cmd, "clear")) {
        std.debug.print("\x1Bc", .{});
    } else if (cmp(cmd, "heap")) {
        std.debug.print("wPrompt  => {}\n", .{allocator.allocated_bytes});
        std.debug.print("w/Prompt => {}\n", .{allocator.allocated_bytes - 4});
    } else if (cmp(cmd[0..3], "add")) {
        if (cmd.len <= 4) {
            return 4;
        }
        const toAdd = cmd[4..];
        try hash.add(toAdd);
    } else if (cmp(cmd[0..3], "del")) {
        if (cmd.len <= 4) {
            return 4;
        }
        const toDel = cmd[4..];
        try hash.del(toDel);
    } else {
        return 1;
    }
    return 0;
}

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
            flush(stdin);
            continue;
        };
        defer allocator.free(input);
        switch (try exec(input, &hashmap, counting_allocator)) {
            0 => void{},
            1 => try stdout.print("{s}: command not found...\n", .{input}),
            2 => try stdout.print("commands: help, show, clear, heap, add, del, exit\n", .{}),
            3 => return,
            4 => try stdout.print("{s}: missing argument...\n", .{input}),
            else => try stdout.print("shouldn't print this :)\n", .{}),
        }
    }
}
