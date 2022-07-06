const std = @import("std");
const print = std.debug.print;

const Node = struct {
    next: ?*Node,
    data: []u8,
};

pub const LinkedList = struct {
    head: ?*Node,
    length: usize,
    allocator: std.mem.Allocator,

    /// have to call deinit() to free the data and allocator
    pub fn init(allocator: std.mem.Allocator) LinkedList {
        var new = LinkedList{
            .head = null,
            .length = 0,
            .allocator = allocator,
        };
        return new;
    }

    /// free all node and destroy the allocator
    pub fn deinit(self: *LinkedList) void {
        if (self.length == 0) {
            return;
        }
        var current: *Node = self.head.?;
        while (true) {
            var buff: ?*Node = current.next;
            self.allocator.free(current.data);
            self.allocator.destroy(current);
            if (buff) |b| {
                current = b;
            } else {
                break;
            }
        }
    }

    /// show all nodes with their data
    pub fn show(self: *LinkedList) void {
        if (self.length == 0) {
            return;
        }
        var index: usize = 0;
        var current: *Node = self.head.?;
        while (index < self.length) : (index += 1) {
            print("    \"{s}\"\n", .{current.*.data});
            // print("    Node: {}, data: \"{s}\", next: {}\n", .{ @ptrToInt(current), current.*.data, @ptrToInt(current.next) });
            current = current.next orelse break;
        }
    }

    /// add new node at the beginning of the list
    pub fn add(self: *LinkedList, data: []const u8) !void {
        var alloc_data: []u8 = try self.allocator.alloc(u8, data.len);
        std.mem.copy(u8, alloc_data, data);
        var new = try self.allocator.create(Node);
        new.data = alloc_data;
        new.next = self.head;
        self.head = new;
        self.length += 1;
    }

    /// delete the first entry that contains `data`
    pub fn del(self: *LinkedList, data: []const u8) !void {
        if (self.length == 0) {
            print("{s}: not found..\n", .{data});
            return;
        }
        if (self.length == 1 and std.mem.containsAtLeast(u8, self.head.?.data, 1, data)) {
            self.allocator.free(self.head.?.data);
            self.allocator.destroy(self.head.?);
            self.head = null;
            self.length -= 1;
            return;
        }

        var index: usize = 1;
        var next_node: *Node = self.head.?;
        while (index < self.length) : (index += 1) {
            if (std.mem.containsAtLeast(u8, next_node.next.?.data, 1, data)) {
                var buf: ?*Node = next_node.next.?.next;
                self.allocator.free(next_node.next.?.data);
                self.allocator.destroy(next_node.next.?);
                next_node.next = buf;
                self.length -= 1;
                print("deleted: {s}\n", .{data});
                return;
            }
            next_node = next_node.next orelse break;
        }
        print("{s}: not found..\n", .{data});
    }
};

test "linked" {
    print("\n", .{});

    // init allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // init list
    var list = LinkedList.init(allocator);
    defer list.deinit();

    try list.add("Hello, There !");
    try list.add("You're here ?");
    list.show();
    try list.del("Hello, There !");
    list.show();
}
