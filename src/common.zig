const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

var prng = std.rand.DefaultPrng.init(0);
pub var random = prng.random();
