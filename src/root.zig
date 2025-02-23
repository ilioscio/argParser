const std = @import("std");

/// Represents the type of an argument's value
pub const ArgType = enum {
    string,
    boolean,
    integer,
};

/// Configuration for an argument
pub const ArgConfig = struct {
    name: []const u8,
    short_form: ?u8, // Single character for short form (e.g., 't' for -t)
    arg_type: ArgType,
    required: bool,
    default_value: ?[]const u8, // String representation of default value
    description: []const u8, // For help text generation
};

/// Represents a parsed argument with its value
pub const Argument = struct {
    name: []const u8,
    value: []const u8,
};

/// Main parser struct that handles argument processing
pub const ArgParser = struct {
    allocator: std.mem.Allocator,
    args: std.ArrayList(Argument),
    configs: std.ArrayList(ArgConfig), // Store configurations for arguments

    /// Initialize a new ArgParser
    pub fn init(allocator: std.mem.Allocator) ArgParser {
        return .{
            .allocator = allocator,
            .args = std.ArrayList(Argument).init(allocator),
            .configs = std.ArrayList(ArgConfig).init(allocator),
        };
    }

    /// Free allocated memory
    pub fn deinit(self: *ArgParser) void {
        self.args.deinit();
        self.configs.deinit();
    }

    /// Register an argument configuration
    pub fn addArg(self: *ArgParser, config: ArgConfig) !void {
        try self.configs.append(config);
    }

    /// Find argument configuration by name or short form
    fn findConfig(self: *const ArgParser, name: []const u8, is_short: bool) ?ArgConfig {
        for (self.configs.items) |config| {
            if (is_short) {
                // For short form, name should be a single character
                if (config.short_form) |short| {
                    if (name.len == 1 and name[0] == short) {
                        return config;
                    }
                }
            } else if (std.mem.eql(u8, config.name, name)) {
                return config;
            }
        }
        return null;
    }

    /// Parse command line arguments
    pub fn parse(self: *ArgParser, args: []const []const u8) !void {
        var i: usize = 1; // Skip program name at index 0
        while (i < args.len) {
            const arg = args[i];

            // Check if argument starts with -- or -
            const is_short = std.mem.startsWith(u8, arg, "-") and !std.mem.startsWith(u8, arg, "--");
            const is_long = std.mem.startsWith(u8, arg, "--");

            if (!is_short and !is_long) {
                return error.InvalidArgumentFormat;
            }

            // Remove prefix (- or --)
            const name = if (is_long) arg[2..] else arg[1..];

            // Find configuration for this argument
            const config = self.findConfig(name, is_short) orelse return error.UnknownArgument;

            // Handle boolean flags
            if (config.arg_type == .boolean) {
                try self.args.append(.{
                    .name = config.name,
                    .value = "true",
                });
                i += 1;
                continue;
            }

            // For non-boolean arguments, we need a value
            if (i + 1 >= args.len) {
                return error.MissingValue;
            }

            // Get the value
            const value = args[i + 1];

            // Check if value isn't another argument
            if (std.mem.startsWith(u8, value, "-")) {
                return error.MissingValue;
            }

            // Validate integer values
            if (config.arg_type == .integer) {
                _ = std.fmt.parseInt(i64, value, 10) catch {
                    return error.InvalidIntegerValue;
                };
            }

            // Store the argument and value
            try self.args.append(.{
                .name = config.name, // Store canonical name, not short form
                .value = value,
            });

            i += 2;
        }

        // Validate required arguments and apply defaults
        try self.validateAndApplyDefaults();
    }

    /// Validate required arguments and apply default values
    fn validateAndApplyDefaults(self: *ArgParser) !void {
        // Check each configured argument
        for (self.configs.items) |config| {
            const has_value = self.getValue(config.name) != null;

            if (!has_value) {
                if (config.required) {
                    return error.MissingRequiredArgument;
                } else if (config.default_value) |default| {
                    // Apply default value
                    try self.args.append(.{
                        .name = config.name,
                        .value = default,
                    });
                }
            }
        }
    }

    /// Get value for a specific argument
    pub fn getValue(self: *const ArgParser, name: []const u8) ?[]const u8 {
        for (self.args.items) |arg| {
            if (std.mem.eql(u8, arg.name, name)) {
                return arg.value;
            }
        }
        return null;
    }

    /// Get boolean value for a specific argument
    pub fn getBoolValue(self: *const ArgParser, name: []const u8) bool {
        if (self.getValue(name)) |value| {
            return std.mem.eql(u8, value, "true");
        }
        return false;
    }

    /// Get integer value for a specific argument
    pub fn getIntValue(self: *const ArgParser, name: []const u8) !?i64 {
        if (self.getValue(name)) |value| {
            return try std.fmt.parseInt(i64, value, 10);
        }
        return null;
    }

    /// Check if an argument exists
    pub fn hasArg(self: *const ArgParser, name: []const u8) bool {
        return self.getValue(name) != null;
    }

    /// Generate help text for all registered arguments
    pub fn generateHelp(self: *const ArgParser, writer: anytype) !void {
        try writer.writeAll("Available arguments:\n");
        for (self.configs.items) |config| {
            // Format the argument syntax
            try writer.print("  --{s}", .{config.name});
            if (config.short_form) |short| {
                try writer.print(", -{c}", .{short});
            }

            // Add value type unless it's a boolean flag
            if (config.arg_type != .boolean) {
                try writer.print(" <{s}>", .{@tagName(config.arg_type)});
            }

            // Add required/default information
            if (config.required) {
                try writer.writeAll(" (required)");
            } else if (config.default_value) |default| {
                try writer.print(" (default: {s})", .{default});
            }

            // Add description
            try writer.print("\n    {s}\n", .{config.description});
        }
    }
};

// Enhanced error set for argument parsing
pub const ArgParserError = error{
    InvalidArgumentFormat,
    MissingValue,
    UnknownArgument,
    MissingRequiredArgument,
    InvalidIntegerValue,
};
