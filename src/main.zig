const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var aa = std.heap.ArenaAllocator.init(gpa.allocator());
    defer aa.deinit();
    const allocator = aa.allocator();
    const proc = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "git", "remote", "-v" },
    });
    if (proc.stdout.len <= 0) {
        return error.GitRemoteMissing;
    }
    const remote = try origin(proc.stdout);
    const project = try repo(remote);
    const url = try coverage(allocator, project);
    _ = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "open", url },
    }) catch {
        try std.io.getStdOut().writer().print("{s}\n", .{url});
    };
}

fn origin(remotes: []const u8) ![]const u8 {
    var remote = std.mem.splitScalar(u8, remotes, '\n');
    while (true) {
        const line = remote.next();
        if (line) |val| {
            if (std.mem.startsWith(u8, val, "origin") and std.mem.endsWith(u8, val, "(push)")) {
                return std.mem.trim(u8, val[7 .. val.len - 6], " ");
            }
        } else {
            return error.GitOriginMissing;
        }
    }
}

test "origin http" {
    const remotes = "origin  https://github.com/zimeg/git-coverage.git (fetch)\norigin  https://github.com/zimeg/git-coverage.git (push)";
    const remote = try origin(remotes);
    try std.testing.expectEqualStrings(remote, "https://github.com/zimeg/git-coverage.git");
}

test "origin ssh" {
    const remotes = "origin  git@github.com:zimeg/git-coverage.git (fetch)\norigin  git@github.com:zimeg/git-coverage.git (push)";
    const remote = try origin(remotes);
    try std.testing.expectEqualStrings(remote, "git@github.com:zimeg/git-coverage.git");
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

fn coverage(allocator: std.mem.Allocator, project: []const u8) ![]const u8 {
    return std.fmt.allocPrint(
        allocator,
        "https://app.codecov.io/gh/{s}",
        .{project},
    );
}

test "coverage project" {
    const project = "zimeg/git-coverage";
    const url = try coverage(std.testing.allocator, project);
    defer std.testing.allocator.free(url);
    try std.testing.expectEqualStrings(url, "https://app.codecov.io/gh/zimeg/git-coverage");
}
