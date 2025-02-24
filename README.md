## argParser
argParser simple but reasonably robust command-line argument parser written in Zig. It provides a straightforward interface for defining and processing
command-line options with different types such as strings, boolean flags, integers, and positive floats.

### Features

- **Dynamic Configuration**: Register multiple types of arguments at runtime.
- **Short Forms**: Use single characters for short-form options (e.g., `-t` for `--test`).
- **Required and Optional Arguments**: Define whether an argument is mandatory or optional.
- **Default Values**: Set default values for arguments that are not provided on the command line.
- **Help Generation**: Automatically generate detailed help messages with examples of how to use each argument.

### Usage
Import the module into your zig project by running the following in your project main directory:
```
zig fetch --save git+https://github.com/ilioscio/argParser
```
This will save the dependency in your project's build.zig.zon file, but next to make it available to @import into your project you must add the module to your build.zig file by adding the following line after your exe is defined (assuming the standard name exe):
```
exe.root_module.addImport("argParser", b.dependency("argParser", .{ .target = target, .optimize = optimize }).module("argParser"));
```
Now you are free to @import the module as shown in this very basic example (For a more complete example check [src/example.zig](https://github.com/ilioscio/argParser/blob/main/src/example.zig)):
```
const std = @import("std");
const ArgParser = @import("argParser").ArgParser;

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
        .name = "headless",
        .short_form = 'h',
        .arg_type = .boolean,
        .required = false,
        .default_value = "false",
        .description = "Run in headless mode",
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
    const headless = parser.getBoolValue("headless");

    if (headless) {
        std.debug.print("I ain't got no head", .{});
    } else {
        std.debug.print("We're headed in the right direction", .{});
    }
}
```
### Known issues
- Tests are unimplemented
- ~~No support for reading float inputs~~
- No support for negative float inputs
