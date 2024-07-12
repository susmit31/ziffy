const std = @import("std");
const fs = std.fs;
const http = std.http;
const time = std.time;

const URL = "download.library.lol/main/565000/1fcbc4de3c0a25215e68df3768d5f804/%28Cambridge%20Introductions%20to%20Philosophy%29%20Michael%20J.%20Murray%2C%20Michael%20C.%20Rea%20-%20An%20Introduction%20to%20the%20Philosophy%20of%20Religion-Cambridge%20University%20Press%20%282008%29.pdf";

const FILENAME = "phil-rel-cambridge.pdf";

pub fn main() !void{
	const stdout = std.io.getStdOut();
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const alloc = gpa.allocator();
	defer _ = gpa.deinit();
	
	const URI = try std.Uri.parse("http://"++URL);
	var client = std.http.Client{.allocator = alloc};
	defer client.deinit();

	var buf_head: [1024*32]u8 = undefined;
	var buf_response: [1024*1024*10]u8 = undefined;

	const start_time: i64 = time.milliTimestamp();
	var req = try client.open(http.Method.GET, URI, .{.server_header_buffer = &buf_head});
	defer req.deinit();

	try stdout.writer().print("Connected to the server. Initiating download...\n",.{});
	
	try req.send();
	try req.finish();
	try req.wait();

	const end_time: i64 = time.milliTimestamp();
	const duration: f32 = @as(f32, @floatFromInt(end_time - start_time)) / std.math.pow(f32, 10, 3);

	const downsize = try req.readAll(&buf_response);
	const downsize_hr = try hr_size(downsize, alloc);
	defer alloc.free(downsize_hr);

	const downspeed = @as(f32, @floatFromInt(downsize)) / duration;
	const downspeed_hr = try hr_size(downspeed, alloc);
	defer alloc.free(downspeed_hr);
	
	try stdout.writer().print("Received content of type {s}. {s} received in {d:.3} seconds @ {s}/s.\n",.{req.response.content_type.?, downsize_hr, duration, downspeed_hr});

	// Writing file into disk
	try stdout.writer().print("Preparing to write file into disk...\n",.{});

	const currdir: fs.Dir = try fs.cwd().openDir(".", .{});
	try currdir.writeFile(.{.sub_path="./"++FILENAME, .data = &buf_response});

	try stdout.writer().print("Wrote file {s} to current directory successfully.\n",.{FILENAME});
}


fn hr_size(size_bytes: anytype, alloc: std.mem.Allocator) ![]u8{
	var float_size: f32 = undefined;
	var suffix: []const u8 = undefined;
	var num: f32 = undefined;
	
	if (@TypeOf(size_bytes) != f32) {
		float_size = @as(f32, @floatFromInt(size_bytes));
	} else {
		float_size =  size_bytes;
	}

	if (float_size > 1024*1024){
		num = float_size / (1024.0*1024.0);
		suffix = "MB";
	} else if (float_size > 1024){
		num = float_size / 1024.0;
		suffix = "KB";
	} else {
		num = float_size;
		suffix = "B";
	}

	const output = try std.fmt.allocPrint(alloc, "{d:.1} {s}", .{num, suffix});
	return output;
}
