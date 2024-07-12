const std = @import("std");

pub fn main() !void{
//    const size1 = 152;
    const size2 = 105*1024;
//    const size3 = 10*1024*1024;

    const stdout = std.io.getStdOut();

//    const s1_hr = try hr_size(size1);
    const s2_hr = try hr_size(size2);
//    const s3_hr = try hr_size(size3);

//    try stdout.writer().print("{d}B: {s}\n", .{size1, s1_hr});
    try stdout.writer().print("{d}B: {s}\n", .{size2, s2_hr});
//    try stdout.writer().print("{d}B: {s}\n", .{size3, s3_hr});
}

fn hr_size(size_bytes: i32) ![]const u8{
    var output: [32]u8 = undefined;
    var num: f32 = undefined;
    var suffix: []const u8 = undefined;

    if (size_bytes > 1024*1024) {
        num = @as(f32, @floatFromInt(size_bytes))/@as(f32, @floatFromInt(1024*1024));
        suffix = "MB";
    } else if (size_bytes > 1024) {
        num = @as(f32, @floatFromInt(size_bytes))/@as(f32, @floatFromInt(1024));
        suffix = "KB";
    } else {
        num = @as(f32, @floatFromInt(size_bytes));
        suffix = "B";
    }

    const out_f = try std.fmt.bufPrint(&output, "{d} {s}", .{num, suffix});

    return out_f;
}
