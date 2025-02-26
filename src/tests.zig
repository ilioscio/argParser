const std = @import("std");
const testing = std.testing;
const ArgParser = @import("root.zig").ArgParser;
const ArgConfig = @import("root.zig").ArgConfig;
const ArgType = @import("root.zig").ArgType;

test "parse basic arguments" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    try parser.addArg(.{
        .name = "input",
        .short_form = 'i',
        .arg_type = .string,
        .required = true,
        .default_value = null,
        .description = "Input file path",
    });

    try parser.addArg(.{
        .name = "output",
        .short_form = 'o',
        .arg_type = .string,
        .required = false,
        .default_value = "output.txt",
        .description = "Output file path",
    });

    const args = [_][]const u8{ "program", "--input", "input.txt" };
    try parser.parse(&args);

    try testing.expectEqualStrings("input.txt", parser.getValue("input").?);
    try testing.expectEqualStrings("output.txt", parser.getValue("output").?);
}

test "parse short form arguments" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    try parser.addArg(.{
        .name = "input",
        .short_form = 'i',
        .arg_type = .string,
        .required = true,
        .default_value = null,
        .description = "Input file path",
    });

    const args = [_][]const u8{ "program", "-i", "input.txt" };
    try parser.parse(&args);

    try testing.expectEqualStrings("input.txt", parser.getValue("input").?);
}

test "parse boolean arguments" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    try parser.addArg(.{
        .name = "verbose",
        .short_form = 'v',
        .arg_type = .boolean,
        .required = false,
        .default_value = "false",
        .description = "Verbose output",
    });

    try parser.addArg(.{
        .name = "quiet",
        .short_form = 'q',
        .arg_type = .boolean,
        .required = false,
        .default_value = "false",
        .description = "Quiet mode",
    });

    const args = [_][]const u8{ "program", "--verbose" };
    try parser.parse(&args);

    try testing.expect(parser.getBoolValue("verbose"));
    try testing.expect(!parser.getBoolValue("quiet"));
}

test "parse integer arguments" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    try parser.addArg(.{
        .name = "count",
        .short_form = 'c',
        .arg_type = .integer,
        .required = true,
        .default_value = null,
        .description = "Count of items",
    });

    const args = [_][]const u8{ "program", "--count", "42" };
    try parser.parse(&args);

    try testing.expectEqual(@as(i64, 42), (try parser.getIntValue("count")).?);
}

test "parse float arguments" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    try parser.addArg(.{
        .name = "rate",
        .short_form = 'r',
        .arg_type = .float,
        .required = true,
        .default_value = null,
        .description = "Rate value",
    });

    const args = [_][]const u8{ "program", "--rate", "3.14" };
    try parser.parse(&args);

    try testing.expectApproxEqAbs(@as(f64, 3.14), (try parser.getFloatValue("rate")).?, 0.0001);
}

test "hasArg function" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    try parser.addArg(.{
        .name = "verbose",
        .short_form = 'v',
        .arg_type = .boolean,
        .required = false,
        .default_value = null,
        .description = "Verbose output",
    });

    try parser.addArg(.{
        .name = "quiet",
        .short_form = 'q',
        .arg_type = .boolean,
        .required = false,
        .default_value = null,
        .description = "Quiet mode",
    });

    const args = [_][]const u8{ "program", "--verbose" };
    try parser.parse(&args);

    try testing.expect(parser.hasArg("verbose"));
    try testing.expect(!parser.hasArg("quiet"));
}

test "required arguments error" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    try parser.addArg(.{
        .name = "input",
        .short_form = 'i',
        .arg_type = .string,
        .required = true,
        .default_value = null,
        .description = "Input file path",
    });

    const args = [_][]const u8{"program"};
    try testing.expectError(error.MissingRequiredArgument, parser.parse(&args));
}

test "unknown argument error" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    const args = [_][]const u8{ "program", "--unknown", "value" };
    try testing.expectError(error.UnknownArgument, parser.parse(&args));
}

test "invalid integer value error" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    try parser.addArg(.{
        .name = "count",
        .short_form = 'c',
        .arg_type = .integer,
        .required = true,
        .default_value = null,
        .description = "Count of items",
    });

    const args = [_][]const u8{ "program", "--count", "not-a-number" };
    try testing.expectError(error.InvalidIntegerValue, parser.parse(&args));
}

test "invalid float value error" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    try parser.addArg(.{
        .name = "rate",
        .short_form = 'r',
        .arg_type = .float,
        .required = true,
        .default_value = null,
        .description = "Rate value",
    });

    const args = [_][]const u8{ "program", "--rate", "not-a-float" };
    try testing.expectError(error.InvalidFloatValue, parser.parse(&args));
}

test "missing value error" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    try parser.addArg(.{
        .name = "input",
        .short_form = 'i',
        .arg_type = .string,
        .required = true,
        .default_value = null,
        .description = "Input file path",
    });

    const args = [_][]const u8{ "program", "--input" };
    try testing.expectError(error.MissingValue, parser.parse(&args));
}

test "invalid argument format" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    try parser.addArg(.{
        .name = "input",
        .short_form = 'i',
        .arg_type = .string,
        .required = true,
        .default_value = null,
        .description = "Input file path",
    });

    const args = [_][]const u8{ "program", "input", "value" };
    try testing.expectError(error.InvalidArgumentFormat, parser.parse(&args));
}

test "generateHelp output" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    try parser.addArg(.{
        .name = "input",
        .short_form = 'i',
        .arg_type = .string,
        .required = true,
        .default_value = null,
        .description = "Input file path",
    });

    try parser.addArg(.{
        .name = "verbose",
        .short_form = 'v',
        .arg_type = .boolean,
        .required = false,
        .default_value = "false",
        .description = "Verbose output",
    });

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    try parser.generateHelp(buffer.writer());

    const expected =
        \\Available arguments:
        \\  --input, -i <string> (required)
        \\    Input file path
        \\  --verbose, -v (default: false)
        \\    Verbose output
        \\
    ;

    try testing.expectEqualStrings(expected, buffer.items);
}

test "mixed long and short form arguments" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    try parser.addArg(.{
        .name = "input",
        .short_form = 'i',
        .arg_type = .string,
        .required = true,
        .default_value = null,
        .description = "Input file path",
    });

    try parser.addArg(.{
        .name = "output",
        .short_form = 'o',
        .arg_type = .string,
        .required = false,
        .default_value = "output.txt",
        .description = "Output file path",
    });

    try parser.addArg(.{
        .name = "verbose",
        .short_form = 'v',
        .arg_type = .boolean,
        .required = false,
        .default_value = "false",
        .description = "Verbose output",
    });

    const args = [_][]const u8{ "program", "-i", "input.txt", "--output", "custom.txt", "-v" };
    try parser.parse(&args);

    try testing.expectEqualStrings("input.txt", parser.getValue("input").?);
    try testing.expectEqualStrings("custom.txt", parser.getValue("output").?);
    try testing.expect(parser.getBoolValue("verbose"));
}
