const std = @import("std");

const Flags = struct {
    help: bool,
    branch: []const u8,
    remote: []const u8,

    pub fn init(allocator: std.mem.Allocator) !Flags {
        var flags = Flags{
            .help = false,
            .branch = "main",
            .remote = "origin",
        };
        var args = try std.process.argsWithAllocator(allocator);
        _ = args.next();
        while (true) {
            const opt = args.next();
            if (opt) |arg| {
                if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                    flags.help = true;
                    break;
                } else if (std.mem.eql(u8, arg, "--branch")) {
                    flags.branch = try parse(&args);
                } else if (std.mem.eql(u8, arg, "--remote")) {
                    flags.remote = try parse(&args);
                } else {
                    return error.FlagOptionMissing;
                }
            } else {
                break;
            }
        }
        return flags;
    }

    fn parse(args: *std.process.ArgIterator) ![]const u8 {
        const path = args.next();
        if (path) |value| {
            return value;
        } else {
            return error.FlagValueMissing;
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var aa = std.heap.ArenaAllocator.init(gpa.allocator());
    defer aa.deinit();
    const allocator = aa.allocator();
    const writer = std.io.getStdOut().writer();
    const flags = try Flags.init(allocator);
    if (flags.help) {
        try writer.print(
            \\usage: git coverage [options]
            \\
            \\Open test coverage uploaded to codecov in a web browser.
            \\
            \\    --help    boolean  print these usage details (default: false)
            \\    --branch  string   fetch changes to inspect  (default: "main")
            \\    --remote  string   pick an upstream project  (default: "origin")
            \\
        , .{});
        return;
    }
    const proc = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "git", "remote", "-v" },
    });
    if (proc.stdout.len <= 0) {
        return error.GitRemoteMissing;
    }
    const remote = try origin(proc.stdout, flags.remote);
    const project = try repo(remote);
    const url = try coverage(allocator, project, flags.branch);
    _ = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "open", url },
    }) catch {
        try writer.print("{s}\n", .{url});
    };
}

fn origin(remotes: []const u8, upstream: []const u8) ![]const u8 {
    var remote = std.mem.splitScalar(u8, remotes, '\n');
    while (true) {
        const line = remote.next();
        if (line) |val| {
            if (std.mem.startsWith(u8, val, upstream) and std.mem.endsWith(u8, val, "(push)")) {
                return std.mem.trim(u8, val[upstream.len + 1 .. val.len - 6], " ");
            }
        } else {
            return error.GitOriginMissing;
        }
    }
}

test "origin http default" {
    const remotes =
        \\origin    https://github.com/example/git-coverage.git (fetch)
        \\origin    https://github.com/example/git-coverage.git (push)
        \\upstream  https://github.com/zimeg/git-coverage.git (fetch)
        \\upstream  https://github.com/zimeg/git-coverage.git (push)
        \\
    ;
    const remote = try origin(remotes, "origin");
    try std.testing.expectEqualStrings(remote, "https://github.com/example/git-coverage.git");
}

test "origin http custom" {
    const remotes =
        \\origin    https://github.com/example/git-coverage.git (fetch)
        \\origin    https://github.com/example/git-coverage.git (push)
        \\upstream  https://github.com/zimeg/git-coverage.git (fetch)
        \\upstream  https://github.com/zimeg/git-coverage.git (push)
        \\
    ;
    const remote = try origin(remotes, "upstream");
    try std.testing.expectEqualStrings(remote, "https://github.com/zimeg/git-coverage.git");
}

test "origin ssh default" {
    const remotes =
        \\fork    git@github.com:example/git-coverage.git (fetch)
        \\fork    git@github.com:example/git-coverage.git (push)
        \\origin  git@github.com:zimeg/git-coverage.git (fetch)
        \\origin  git@github.com:zimeg/git-coverage.git (push)
        \\
    ;
    const remote = try origin(remotes, "origin");
    try std.testing.expectEqualStrings(remote, "git@github.com:zimeg/git-coverage.git");
}

test "origin ssh custom" {
    const remotes =
        \\fork    git@github.com:example/git-coverage.git (fetch)
        \\fork    git@github.com:example/git-coverage.git (push)
        \\origin  git@github.com:zimeg/git-coverage.git (fetch)
        \\origin  git@github.com:zimeg/git-coverage.git (push)
        \\
    ;
    const remote = try origin(remotes, "fork");
    try std.testing.expectEqualStrings(remote, "git@github.com:example/git-coverage.git");
}

fn repo(remote: []const u8) ![]const u8 {
    if (std.mem.startsWith(u8, remote, "https://github.com/")) {
        return remote[19 .. remote.len - 4];
    }
    if (std.mem.startsWith(u8, remote, "git@github.com:")) {
        return remote[15 .. remote.len - 4];
    }
    return error.GitProtocolMissing;
}

test "repo http" {
    const remote = "https://github.com/zimeg/git-coverage.git";
    const project = try repo(remote);
    try std.testing.expectEqualStrings(project, "zimeg/git-coverage");
}

test "repo ssh" {
    const remote = "git@github.com:zimeg/git-coverage.git";
    const project = try repo(remote);
    try std.testing.expectEqualStrings(project, "zimeg/git-coverage");
}

fn coverage(allocator: std.mem.Allocator, project: []const u8, branch: []const u8) ![]const u8 {
    return std.fmt.allocPrint(
        allocator,
        "https://app.codecov.io/gh/{s}/tree/{s}",
        .{ project, branch },
    );
}

test "coverage project main" {
    const project = "zimeg/git-coverage";
    const url = try coverage(std.testing.allocator, project, "main");
    defer std.testing.allocator.free(url);
    try std.testing.expectEqualStrings(url, "https://app.codecov.io/gh/zimeg/git-coverage/tree/main");
}

test "coverage project dev" {
    const project = "zimeg/git-coverage";
    const url = try coverage(std.testing.allocator, project, "dev");
    defer std.testing.allocator.free(url);
    try std.testing.expectEqualStrings(url, "https://app.codecov.io/gh/zimeg/git-coverage/tree/dev");
}
