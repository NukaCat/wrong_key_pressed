const std = @import("std");
const common = @import("common.zig");

const Editor = @This();

lines: std.ArrayList(std.ArrayList(u8)),
cursor_x: usize = 0,
cursor_y: usize = 0,

pub fn init() Editor {
    var lines = std.ArrayList(std.ArrayList(u8)).init(common.allocator);
    lines.append(std.ArrayList(u8).init(common.allocator)) catch unreachable;
    return Editor{
        .lines = lines,
    };
}

pub fn write_text(self: *Editor, text: []const u8) void {
    self.lines.items[self.cursor_y].insertSlice(self.cursor_x, text) catch unreachable;
    self.cursor_x += text.len;
}

pub fn add_new_line(self: *Editor) void {
    self.lines.append(std.ArrayList(u8).init(common.allocator)) catch unreachable;
    self.cursor_y += 1;
    self.cursor_x = 0;
}

pub fn move_cursor_left(self: *Editor) void {
    if (self.cursor_x > 0) {
        self.cursor_x -= 1;
    }
}

pub fn move_cursor_right(self: *Editor) void {
    const line = self.lines.items[self.cursor_y];
    if (self.cursor_x < line.len) {
        self.cursor_x += 1;
    }
}

pub fn move_cursor_down(self: *Editor) void {
    if (self.cursor_y > 0) {
        self.cursor_y -= 1;
    }
}

pub fn move_cursor_up(self: *Editor) void {
    if (self.cursor_y < self.lines.items.len) {
        self.cursor_y += 1;
    }
}
