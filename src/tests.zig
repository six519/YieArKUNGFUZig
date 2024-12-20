const global = @import("global.zig");
const std = @import("std");

test "generate random" {
    const val = global.getRandomNumber(0, 1) catch |err| {
        std.debug.print("Error on villainRandomAttack: {}\n", .{err});
        return;
    };
    try std.testing.expect(val >= 0 and val <= 1);
    std.debug.print("The value is: {d}\n", .{val});
}
