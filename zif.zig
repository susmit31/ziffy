const std = @import("std");
const fs = std.fs;

pub fn main() !void{
	const stdout = std.io.getStdOut();

	var currdir: fs.Dir = try fs.cwd().openDir(".",.{.iterate = true});
	var iter = currdir.iterate();

	while (try iter.next()) |item| {
		try stdout.writer().print("=> {s}\n", .{item.name});
	}
	
}
