const std = @import("std");
const stdout = std.io.getStdOut();
const stdin = std.io.getStdIn();

pub fn main() !void{
	try stdout.writer().print("First string: ", .{});
	var buffer1: [1024]u8 = undefined;
	const str1 = (try stdin.reader().readUntilDelimiterOrEof(&buffer1, '\n')).?;

	try stdout.writer().print("Second string: ", .{});
	var buffer2: [1024]u8 = undefined;
	const str2 = (try stdin.reader().readUntilDelimiterOrEof(&buffer2, '\n')).?;

	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const alloc = gpa.allocator();
	
	const alignment = try levenshtein(str1, str2, alloc);
	try stdout.writer().print("{s}", .{try repeat("=",@intCast(14+@max(str1.len, str2.len)), alloc)});
	try stdout.writer().print("\nDist: {d},\n\nL1: {s}\nL2: {s}\n", .{alignment.distance, alignment.alignment1, alignment.alignment2});
}

fn levenshtein(str1: []const u8, str2: []const u8, alloc: std.mem.Allocator) !Alignment{
	var dist_matrix = try alloc.alloc(i32, (str1.len+1) * (str2.len+1));
	var predecessor = try alloc.alloc(u8, (str1.len+1) * (str2.len+1));
	var alignment1: []const u8 = "";
	var alignment2: []const u8 = "";

	for (0..str2.len+1) |i|{
		dist_matrix[i*(str1.len+1)] = @intCast(i);
		predecessor[i*(str1.len+1)] = 'u';
	}

	for (0..str1.len+1) |j|{
		dist_matrix[j] = @intCast(j);
		predecessor[j] = 'l';
	}

	for (1..str1.len+1) |j|{
		for (1..str2.len+1) |i|{
			var diff: i32 = 0;
			if (str1[j-1] != str2[i-1]) {
				diff = 1;
			}
			const d1: i32 = dist_matrix[(i-1)*(str1.len+1) + j] + 1;
			const d2: i32 = dist_matrix[i*(str1.len+1) + (j-1)] + 1;
			const d3: i32 = dist_matrix[(i-1)*(str1.len+1) + (j-1)] + diff;
			dist_matrix[i*(str1.len+1) + j] = @min(d1, @min(d2, d3));

			if (dist_matrix[i*(str1.len+1) + j] == d1) {
				predecessor[i*(str1.len+1) + j] = 'u';
			} else if (dist_matrix[i*(str1.len+1) + j] == d2){
				predecessor[i*(str1.len+1) + j] = 'l';
			} else { 
				predecessor[i*(str1.len+1) + j] = 0;
			}
		}
	}

	var i = str2.len;
	var j = str1.len;
	var pred: u8 = undefined;
	while (i > 0 or j > 0) {
		pred = predecessor[i*(str1.len+1) + j];
		if (pred == 0) {
			alignment1 = try concat(str1[j-1..j], alignment1, alloc);
			alignment2 = try concat(str2[i-1..i], alignment2, alloc);
			j -= 1;
			i -= 1;
		} else if (pred == 'u') {
			alignment1 = try concat("-", alignment1, alloc);
			alignment2 = try concat(str2[i-1..i], alignment2, alloc);
			i -= 1;
		} else if (pred == 'l'){
			alignment1 = try concat(str1[j-1..j], alignment1, alloc);
			alignment2 = try concat("-", alignment2, alloc);
			j -= 1;
		}
	}

	return Alignment.init(str1, str2, alignment1, alignment2, dist_matrix[(str2.len+1)*(str1.len+1)-1]);
}

fn concat(str1: []const u8, str2: []const u8, alloc: std.mem.Allocator) ![]const u8{
	var buffer = try alloc.alloc(u8, str1.len+str2.len);	
	for (str1, 0..) |char, i|{
		buffer[i] = char;
	}
	for (str2, 0..) |char, i|{
		buffer[str1.len + i] = char;
	}		
	return buffer;
}

fn repeat(str: []const u8, num: i32, alloc: std.mem.Allocator) ![]const u8{
	const number: usize = @intCast(num);
	var buffer = try alloc.alloc(u8, str.len * number);
	for (0..number) |i|{
		for (0..str.len) |j|{
			buffer[i * str.len + j] = str[j];
		}
	}
	return buffer;
}

const Alignment = struct{
	str1: []const u8,
	str2: []const u8,
	alignment1: []const u8,
	alignment2: []const u8,
	distance: i32,

	pub fn init(str1: []const u8, str2: []const u8, alignment1: []const u8, alignment2: []const u8, distance: i32) Alignment{
		return Alignment{
			.str1 = str1,
			.str2 = str2,
			.alignment1 = alignment1,
			.alignment2 = alignment2,
			.distance = distance
		};
	}
};
