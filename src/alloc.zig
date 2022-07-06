const std = @import("std");

pub const CountingAllocator = struct {
    backing_allocator: std.mem.Allocator,
    allocated_bytes: u64,

    pub fn init(backing_allocator: std.mem.Allocator) CountingAllocator {
        return CountingAllocator{
            .backing_allocator = backing_allocator,
            .allocated_bytes = 0,
        };
    }

    pub fn allocator(self: *CountingAllocator) std.mem.Allocator {
        return std.mem.Allocator.init(
            self,
            CountingAllocator.alloc,
            CountingAllocator.resize,
            CountingAllocator.free,
        );
    }

    fn alloc(self: *CountingAllocator, len: usize, ptr_align: u29, len_align: u29, ret_addr: usize) std.mem.Allocator.Error![]u8 {
        const result = try self.backing_allocator.rawAlloc(len, ptr_align, len_align, ret_addr);
        self.allocated_bytes += result.len;
        return result;
    }

    fn resize(self: *CountingAllocator, buf: []u8, buf_align: u29, new_len: usize, len_align: u29, ret_addr: usize) ?usize {
        const result = self.backing_allocator.rawResize(buf, buf_align, new_len, len_align, ret_addr) orelse return null;
        if (result < buf.len) {
            self.allocated_bytes -= buf.len - result;
        } else {
            self.allocated_bytes += result - buf.len;
        }
        return result;
    }

    fn free(self: *CountingAllocator, buf: []u8, buf_align: u29, ret_addr: usize) void {
        self.allocated_bytes -= buf.len;
        self.backing_allocator.rawFree(buf, buf_align, ret_addr);
    }
};
