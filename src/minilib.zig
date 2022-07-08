const std = @import("std");
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

/// trim removes all spaces from the beginning and the end of the string
pub fn trim(str: []const u8) []const u8 {
    // start from beginning
    var start: usize = 0;
    while (str[start] == ' ') : (start += 1) {}

    // start from end
    var end: usize = str.len - 1;
    while (str[end] == ' ') : (end -= 1) {}

    return str[start .. end + 1];
}

/// check command and execute it
pub fn exec(bcmd: []const u8, hash: *HashMap, allocator: CountingAllocator) !u8 {
    const cmd = trim(bcmd);
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
        std.debug.print("w/Prompt => {}\n", .{allocator.allocated_bytes - bcmd.len});
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
