const std = @import("std");

const Flags = struct {
    help: bool,
    branch: []const u8,
    path: []const u8,
    remote: []const u8,

    pub fn init(allocator: std.mem.Allocator) !Flags {
        var flags = Flags{
            .help = false,
            .branch = "main",
            .path = ".",
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
                } else if (std.mem.eql(u8, arg, "--path")) {
                    flags.path = try parse(&args);
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
            \\    --path    string   show a specific file      (default: ".")
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
    const url = try coverage(allocator, project, flags.branch, flags.path);
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
    if (std.mem.containsAtLeast(u8, remote, 1, "@github.com:")) {
        var splits = std.mem.splitScalar(u8, remote, ':');
        _ = splits.first();
        const project = splits.next().?;
        return project[0 .. project.len - 4];
    }
    return error.GitProtocolMissing;
}

test "repo http default" {
    const remote = "https://github.com/zimeg/git-coverage.git";
    const project = try repo(remote);
    try std.testing.expectEqualStrings(project, "zimeg/git-coverage");
}

test "repo ssh user" {
    const remote = "git@github.com:zimeg/git-coverage.git";
    const project = try repo(remote);
    try std.testing.expectEqualStrings(project, "zimeg/git-coverage");
}

test "repo ssh org" {
    const remote = "org-0123456@github.com:example/git-coverage.git";
    const project = try repo(remote);
    try std.testing.expectEqualStrings(project, "example/git-coverage");
}

fn relative(allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
    const git = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "git", "rev-parse", "--show-toplevel" },
    });
    const root = std.mem.trimRight(u8, git.stdout, "\n");
    const cwd = try std.fs.cwd().realpathAlloc(allocator, path);
    const realpath = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "realpath", "--relative-to", root, cwd },
    });
    return std.mem.trimRight(u8, realpath.stdout, "\n");
}

test "relative cwd" {
    var aa = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer aa.deinit();
    const path = ".";
    const full = try relative(aa.allocator(), path);
    try std.testing.expectEqualStrings(full, ".");
}

test "relative dir" {
    var aa = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer aa.deinit();
    const path = ".././git-coverage/";
    const full = try relative(aa.allocator(), path);
    try std.testing.expectEqualStrings(full, ".");
}

test "relative file" {
    var aa = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer aa.deinit();
    const path = "././src/.././README.md";
    const full = try relative(aa.allocator(), path);
    try std.testing.expectEqualStrings(full, "README.md");
}

fn coverage(allocator: std.mem.Allocator, project: []const u8, branch: []const u8, path: []const u8) ![]const u8 {
    const fullpath = try relative(allocator, path);
    const slashes = std.mem.count(u8, fullpath, "/");
    const encoding = try allocator.alloc(u8, fullpath.len + slashes * 2);
    defer allocator.free(encoding);
    _ = std.mem.replace(u8, fullpath, "/", "%2F", encoding);
    const stat = try std.fs.cwd().statFile(path);
    switch (stat.kind) {
        .directory => return std.fmt.allocPrint(
            allocator,
            "https://app.codecov.io/gh/{s}/tree/{s}/{s}",
            .{ project, branch, encoding },
        ),
        .file => return std.fmt.allocPrint(
            allocator,
            "https://app.codecov.io/gh/{s}/blob/{s}/{s}",
            .{ project, branch, encoding },
        ),
        else => return error.FileKindMissing,
    }
}

test "coverage project main root" {
    var aa = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer aa.deinit();
    const project = "zimeg/git-coverage";
    const url = try coverage(aa.allocator(), project, "main", ".");
    try std.testing.expectEqualStrings(url, "https://app.codecov.io/gh/zimeg/git-coverage/tree/main/.");
}

test "coverage project main dir" {
    var aa = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer aa.deinit();
    const project = "zimeg/git-coverage";
    const url = try coverage(aa.allocator(), project, "main", "./src");
    try std.testing.expectEqualStrings(url, "https://app.codecov.io/gh/zimeg/git-coverage/tree/main/src");
}

test "coverage project main file" {
    var aa = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer aa.deinit();
    const project = "zimeg/git-coverage";
    const url = try coverage(aa.allocator(), project, "main", "./src/main.zig");
    try std.testing.expectEqualStrings(url, "https://app.codecov.io/gh/zimeg/git-coverage/blob/main/src%2Fmain.zig");
}

test "coverage project dev root" {
    var aa = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer aa.deinit();
    const project = "zimeg/git-coverage";
    const url = try coverage(aa.allocator(), project, "dev", ".");
    try std.testing.expectEqualStrings(url, "https://app.codecov.io/gh/zimeg/git-coverage/tree/dev/.");
}

test "coverage project dev dir" {
    var aa = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer aa.deinit();
    const project = "zimeg/git-coverage";
    const url = try coverage(aa.allocator(), project, "dev", "./src");
    try std.testing.expectEqualStrings(url, "https://app.codecov.io/gh/zimeg/git-coverage/tree/dev/src");
}

test "coverage project dev file" {
    var aa = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer aa.deinit();
    const project = "zimeg/git-coverage";
    const url = try coverage(aa.allocator(), project, "dev", "./src/main.zig");
    try std.testing.expectEqualStrings(url, "https://app.codecov.io/gh/zimeg/git-coverage/blob/dev/src%2Fmain.zig");
}
