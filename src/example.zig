const std = @import("std");
const ArgParser = @import("root.zig").ArgParser;
// If you are importing via build.zig.zon you can instead use the following:
//const ArgParser = @import("argparse").ArgParser;

pub fn main() !void {
    // Initialize our allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create our argument parser
    var parser = ArgParser.init(allocator);
    defer parser.deinit();

    // Register all our arguments
    try parser.addArg(.{
        .name = "input",
        .short_form = 'i',
        .arg_type = .string,
        .required = true,
        .default_value = null,
        .description = "Input file path to process",
    });
    try parser.addArg(.{
        .name = "output",
        .short_form = 'o',
        .arg_type = .string,
        .required = false,
        .default_value = "output.txt",
        .description = "Output file path (default: output.txt)",
    });
    try parser.addArg(.{
        .name = "buffer-size",
        .short_form = 'b',
        .arg_type = .integer,
        .required = false,
        .default_value = "1024",
        .description = "Buffer size for reading (default: 1024)",
    });
    try parser.addArg(.{
        .name = "verbose",
        .short_form = 'v',
        .arg_type = .boolean,
        .required = false,
        .default_value = null,
        .description = "Enable verbose output",
    });
    try parser.addArg(.{
        .name = "dry-run",
        .short_form = 'd',
        .arg_type = .boolean,
        .required = false,
        .default_value = null,
        .description = "Show what would be done without actually doing it",
    });

    // Convert argv to the format our parser expects
    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();

    // Convert each argument from null-terminated string to string slice
    for (std.os.argv) |arg| {
        try args.append(std.mem.span(arg));
    }

    // Parse the arguments and handle any errors
    parser.parse(args.items) catch |err| {
        switch (err) {
            error.MissingRequiredArgument => {
                std.debug.print("\nError: Missing required arguments\n\n", .{});
                try parser.generateHelp(std.io.getStdErr().writer());
                return err;
            },
            error.InvalidIntegerValue => {
                std.debug.print("\nError: Buffer size must be a valid integer\n\n", .{});
                return err;
            },
            else => {
                std.debug.print("\nError: {}\n", .{err});
                return err;
            },
        }
    };

    // Get all our argument values
    const input_path = parser.getValue("input").?;
    const output_path = parser.getValue("output").?;
    const buffer_size = (try parser.getIntValue("buffer-size")).?;
    const verbose = parser.getBoolValue("verbose");
    const dry_run = parser.getBoolValue("dry-run");

    // Print configuration if verbose
    if (verbose) {
        std.debug.print("\nConfiguration:\n", .{});
        std.debug.print("  Verbose: {}\n", .{verbose});
        std.debug.print("  Input file: {s}\n", .{input_path});
        std.debug.print("  Output file: {s}\n", .{output_path});
        std.debug.print("  Buffer size: {d} bytes\n", .{buffer_size});
        std.debug.print("  Dry run: {}\n\n", .{dry_run});
    }

    // Simulate file processing
    if (dry_run) {
        std.debug.print("Dry run - would process '{s}' to '{s}'\n", .{
            input_path,
            output_path,
        });
        return;
    }

    // Actually process the file
    processFile(input_path, output_path, buffer_size, verbose) catch |err| {
        std.debug.print("Error processing file: {}\n", .{err});
        return err;
    };
}

fn processFile(input_path: []const u8, output_path: []const u8, buffer_size: i64, verbose: bool) !void {
    // Open input file
    const input_file = try std.fs.cwd().openFile(input_path, .{});
    defer input_file.close();

    // Create output file
    const output_file = try std.fs.cwd().createFile(output_path, .{});
    defer output_file.close();

    var buffer = try std.heap.page_allocator.alloc(u8, @intCast(buffer_size));
    defer std.heap.page_allocator.free(buffer);

    var total_bytes: usize = 0;

    // Read and write in chunks
    while (true) {
        const bytes_read = try input_file.read(buffer);
        if (bytes_read == 0) break;

        try output_file.writeAll(buffer[0..bytes_read]);
        total_bytes += bytes_read;

        if (verbose) {
            std.debug.print("Processed {d} bytes...\n", .{total_bytes});
        }
    }

    std.debug.print("Successfully processed {d} total bytes\n", .{total_bytes});
}
