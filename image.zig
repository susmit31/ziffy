const std = @import("std");
const fs = std.fs;
const eql = std.mem.eql;

pub fn main() !void{
	const stdout = std.io.getStdOut();
	const picname = "putin3.jpg";

	var currdir : fs.Dir = try fs.cwd().openDir(".",.{.iterate = true});

	var iter = currdir.iterate();

	while (try iter.next()) |item|{
		try stdout.writer().print("=> {s}---{}\n", .{item.name, item.kind});
		if (item.kind == .file) {
			if (eql(u8, item.name, picname)) {
				try stdout.writer().print("Reading {s}...\n",.{item.name});

				var gpa = std.heap.GeneralPurposeAllocator(.{}){};
				const alloc = gpa.allocator();

				const max_size: usize = 1024*1024;

				const contents = try currdir.readFileAlloc(alloc, "./"++picname, max_size);
				try stdout.writer().print("Writing new file...",.{});
				try currdir.writeFile(.{.sub_path=picname[0..picname.len - 4]++"-zig.jpg", .data = contents});
				try stdout.writer().print("Done!\n",.{});
			}
		} 
	}
}
