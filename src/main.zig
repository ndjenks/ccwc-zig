const std = @import("std");
const process = std.process;
const ascii = std.ascii;
const unicode = std.unicode;

const Counter = struct { line: usize = 0, byte: usize = 0, word: usize = 0, char: usize = 0 };
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    const allocator = gpa.allocator();
    var argIterator = try std.process.argsWithAllocator(allocator);
    defer argIterator.deinit();

    const allocatorArray = gpa.allocator();
    var list = std.ArrayList([:0]const u8).init(allocatorArray);
    defer list.deinit();

    while (argIterator.next()) |arg| {
        try list.append(arg);
    }

    const argv = list.items;
    var options: []const u8 = "";
    var filepath: []const u8 = "";

    for (argv[1..argv.len]) |arg| {
        const slice = arg[0..arg.len];
        if (slice[0] == '-') {
            options = slice[1..arg.len];
        } else {
            filepath = arg;
        }
    }
    var file: std.fs.File = undefined;
    if (std.mem.eql(u8, filepath, "")) {
        file = std.io.getStdIn();
    } else {
        file = std.fs.cwd().openFile(filepath, .{}) catch |err| switch (err) {
            error.FileNotFound => {
                std.debug.print("File non-existent or wrong path\n", .{});
                return err;
            },
            else => {
                return err;
            },
        };
    }
    const result = try fileParser(file);
    if (std.mem.eql(u8, options, "")) {
        std.debug.print("\t{d}\t{d}\t{d}\t{s}\n", .{ result.line, result.word, result.byte, filepath });
    } else {
        for (options) |opt| {
            std.debug.print("opt {c}\n", .{opt});
            if (opt == 'l') {
                std.debug.print("\t{d}", .{result.line});
            } else if (opt == 'w') {
                std.debug.print("\t{d}", .{result.word});
            } else if (opt == 'c') {
                std.debug.print("\t{d}", .{result.byte});
            } else if (opt == 'm') {
                std.debug.print("\t{d}", .{result.char});
            }
            if (!std.mem.eql(u8, filepath, "")) {
                std.debug.print("\t{s}\n", .{filepath});
            } else {
                std.debug.print("\n", .{});
            }
        }
    }
    defer file.close();
}

fn fileParser(file: std.fs.File) anyerror!Counter {
    var counter: Counter = .{};
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var arl = std.ArrayList(u8).init(allocator);
    var wordArray = std.ArrayList(u8).init(allocator);
    while (true) {
        in_stream.streamUntilDelimiter(arl.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => {
                break;
            },

            else => {
                return err;
            },
        };
        counter.line += 1;
        try arl.append('\n');
        counter.byte += arl.items.len;
        var inWord: bool = false;
        var inWord2: bool = false;

        for (arl.items) |c| {
            if (ascii.isWhitespace(c)) {
                counter.char += 1;
                inWord = false;
            } else {
                try wordArray.append(c);
                inWord = true;
            }
            counter.word += @intFromBool(!inWord and inWord2);
            if (!inWord and inWord2) {
                const hh = try wordArray.toOwnedSlice();
                const bytesDecoded = try unicode.utf8CountCodepoints(hh);
                counter.char += bytesDecoded;
                wordArray.clearRetainingCapacity();
            }
            inWord2 = inWord;
        }
        arl.clearRetainingCapacity();
    }
    return counter;
}
