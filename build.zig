const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the main library
    const lib = b.addStaticLibrary(.{
        .name = "xcrypt",
        .target = target,
        .optimize = optimize,
    });

    // Generate config.h using addConfigHeader
    const config_header = b.addConfigHeader(
        .{
            .style = .blank,
            .include_path = "config.h",
        },
        .{
            // System headers - assume POSIX system
            .HAVE_SYS_TYPES_H = 1,
            .HAVE_SYS_STAT_H = 1,
            .HAVE_SYS_RANDOM_H = 1,
            .HAVE_UNISTD_H = 1,
            .HAVE_STRING_H = 1,
            .HAVE_STRINGS_H = 1,
            .HAVE_STDLIB_H = 1,
            .HAVE_STDINT_H = 1,
            .HAVE_INTTYPES_H = 1,
            .HAVE_ERRNO_H = 1,
            .HAVE_FCNTL_H = 1,
            .HAVE_LIMITS_H = 1,
            .HAVE_STDBOOL_H = 1,
            .HAVE_STDALIGN_H = 1,  // C11 has stdalign.h

            // Functions - typical for macOS/BSD/Linux
            .HAVE_GETENTROPY = null,
            .HAVE_GETRANDOM = null,
            .HAVE_ARC4RANDOM_BUF = 1,
            .HAVE_EXPLICIT_BZERO = null,
            .HAVE_EXPLICIT_MEMSET = null,
            .HAVE_MEMSET_S = 1,

            // Build configuration
            .ENABLE_FAILURE_TOKENS = 1,
            .ENABLE_OBSOLETE_API = 1,
            .ENABLE_OBSOLETE_API_ENOSYS = 0,

            // Type sizes
            .SIZEOF_LONG_LONG = 8,

            // Endianness
            .WORDS_BIGENDIAN = 0,
            .ENDIANNESS_IS_LITTLE = 1,
            .ENDIANNESS_IS_BIG = null,
            .ENDIANNESS_IS_PDP = null,

            // All hash algorithms enabled by default
            .INCLUDE_descrypt = 1,
            .INCLUDE_bigcrypt = 1,
            .INCLUDE_bsdicrypt = 1,
            .INCLUDE_md5crypt = 1,
            .INCLUDE_nt = 1,
            .INCLUDE_sunmd5 = 1,
            .INCLUDE_sha1crypt = 1,
            .INCLUDE_sha256crypt = 1,
            .INCLUDE_sha512crypt = 1,
            .INCLUDE_bcrypt = 1,
            .INCLUDE_bcrypt_a = 1,
            .INCLUDE_bcrypt_x = 1,
            .INCLUDE_bcrypt_y = 1,
            .INCLUDE_scrypt = 1,
            .INCLUDE_gost_yescrypt = 1,
            .INCLUDE_yescrypt = 1,
            .INCLUDE_sm3crypt = 1,
            .INCLUDE_sm3_yescrypt = 1,

            // Symbol versioning (disabled for static lib)
            .SYMVER_FLOOR = "",
            .SYMVER_CEILING = "",

            // Function availability
            .HAVE_FUNC_CRYPT = 1,
            .HAVE_FUNC_CRYPT_R = 1,
            .HAVE_FUNC_CRYPT_RA = 1,
            .HAVE_FUNC_CRYPT_RN = 1,
            .HAVE_FUNC_CRYPT_GENSALT = 1,
            .HAVE_FUNC_CRYPT_GENSALT_R = 1,
            .HAVE_FUNC_CRYPT_GENSALT_RA = 1,
            .HAVE_FUNC_CRYPT_GENSALT_RN = 1,
            .HAVE_FUNC_CRYPT_CHECKSALT = 1,
            .HAVE_FUNC_CRYPT_PREFERRED_METHOD = 1,
            .HAVE_FUNC_XCRYPT = 1,
            .HAVE_FUNC_XCRYPT_R = 1,
            .HAVE_FUNC_XCRYPT_GENSALT = 1,
            .HAVE_FUNC_XCRYPT_GENSALT_R = 1,

            // Compiler features
            .HAVE_STRONG_ALIAS = 1,
            .HAVE_STATIC_ASSERT_IN_ASSERT_H = 1,  // C11 has static_assert
            .HAVE__STATIC_ASSERT = 1,              // C11 has _Static_assert
            .HAVE_MAX_ALIGN_T = 1,                 // C11 has max_align_t

            // Package info
            .PACKAGE_NAME = "libxcrypt",
            .PACKAGE_VERSION = "4.5.0",
            .PACKAGE_STRING = "libxcrypt 4.5.0",
        },
    );
    lib.addConfigHeader(config_header);

    // Add include paths
    lib.addIncludePath(b.path("lib"));
    lib.addIncludePath(b.path("."));

    // All library sources from Makefile.am
    const lib_sources = [_][]const u8{
        "lib/alg-des-tables.c",
        "lib/alg-des.c",
        "lib/alg-gost3411-2012-core.c",
        "lib/alg-gost3411-2012-hmac.c",
        "lib/alg-hmac-sha1.c",
        "lib/alg-md4.c",
        "lib/alg-md5.c",
        "lib/alg-sha1.c",
        "lib/alg-sha256.c",
        "lib/alg-sha512.c",
        "lib/alg-sm3.c",
        "lib/alg-sm3-hmac.c",
        "lib/alg-yescrypt-common.c",
        "lib/alg-yescrypt-opt.c",
        // "lib/alg-yescrypt-platform.c",  // This is included by alg-yescrypt-opt.c
        "lib/crypt-bcrypt.c",
        "lib/crypt-des.c",
        "lib/crypt-des-obsolete.c",
        "lib/crypt-gensalt-static.c",
        "lib/crypt-gost-yescrypt.c",
        "lib/crypt-sm3-yescrypt.c",
        "lib/crypt-md5.c",
        "lib/crypt-nthash.c",
        "lib/crypt-pbkdf1-sha1.c",
        "lib/crypt-scrypt.c",
        "lib/crypt-sha256.c",
        "lib/crypt-sha512.c",
        "lib/crypt-sm3.c",
        "lib/crypt-static.c",
        "lib/crypt-sunmd5.c",
        "lib/crypt-yescrypt.c",
        "lib/crypt.c",
        "lib/util-base64.c",
        "lib/util-gensalt-sha.c",
        "lib/util-get-random-bytes.c",
        "lib/util-make-failure-token.c",
        "lib/util-xbzero.c",
        "lib/util-xstrcpy.c",
    };

    // Compile flags
    const cflags = [_][]const u8{
        "-std=gnu11",  // Changed from gnu99 to support C11 alignment features
        "-D_DEFAULT_SOURCE",
        "-D_GNU_SOURCE",
        "-DHAVE_CONFIG_H=1",
        "-DIN_LIBCRYPT",  // Important: this flag activates the correct build mode
        "-fno-strict-aliasing",
        "-Wno-error",
    };

    for (lib_sources) |src| {
        lib.addCSourceFile(.{
            .file = b.path(src),
            .flags = &cflags,
        });
    }

    lib.linkLibC();

    // Install library and headers
    b.installArtifact(lib);
    lib.installHeader(b.path("crypt.h"), "crypt.h");
    lib.installHeader(config_header.getOutput(), "config.h");

    // Tests
    const test_step = b.step("test", "Run all tests");

    const test_programs = [_]struct {
        name: []const u8,
        source: []const u8,
    }{
        // Algorithm tests
        .{ .name = "test-alg-des", .source = "test/alg-des.c" },
        .{ .name = "test-alg-gost3411-2012", .source = "test/alg-gost3411-2012.c" },
        .{ .name = "test-alg-gost3411-2012-hmac", .source = "test/alg-gost3411-2012-hmac.c" },
        .{ .name = "test-alg-hmac-sha1", .source = "test/alg-hmac-sha1.c" },
        .{ .name = "test-alg-md4", .source = "test/alg-md4.c" },
        .{ .name = "test-alg-md5", .source = "test/alg-md5.c" },
        .{ .name = "test-alg-pbkdf-hmac-sha256", .source = "test/alg-pbkdf-hmac-sha256.c" },
        .{ .name = "test-alg-sha1", .source = "test/alg-sha1.c" },
        .{ .name = "test-alg-sha256", .source = "test/alg-sha256.c" },
        .{ .name = "test-alg-sha512", .source = "test/alg-sha512.c" },
        .{ .name = "test-alg-sm3", .source = "test/alg-sm3.c" },
        .{ .name = "test-alg-sm3-hmac", .source = "test/alg-sm3-hmac.c" },
        .{ .name = "test-alg-yescrypt", .source = "test/alg-yescrypt.c" },

        // Crypt function tests
        .{ .name = "test-badsalt", .source = "test/badsalt.c" },
        .{ .name = "test-badsetting", .source = "test/badsetting.c" },
        .{ .name = "test-byteorder", .source = "test/byteorder.c" },
        .{ .name = "test-checksalt", .source = "test/checksalt.c" },
        .{ .name = "test-crypt-badargs", .source = "test/crypt-badargs.c" },
        .{ .name = "test-crypt-gost-yescrypt", .source = "test/crypt-gost-yescrypt.c" },
        .{ .name = "test-crypt-sm3-yescrypt", .source = "test/crypt-sm3-yescrypt.c" },
        .{ .name = "test-des-obsolete", .source = "test/des-obsolete.c" },
        .{ .name = "test-des-obsolete_r", .source = "test/des-obsolete_r.c" },
        .{ .name = "test-explicit-bzero", .source = "test/explicit-bzero.c" },
        .{ .name = "test-gensalt", .source = "test/gensalt.c" },
        .{ .name = "test-gensalt-bcrypt_x", .source = "test/gensalt-bcrypt_x.c" },
        .{ .name = "test-gensalt-extradata", .source = "test/gensalt-extradata.c" },
        .{ .name = "test-gensalt-nthash", .source = "test/gensalt-nthash.c" },
        .{ .name = "test-getrandom-fallbacks", .source = "test/getrandom-fallbacks.c" },
        .{ .name = "test-getrandom-interface", .source = "test/getrandom-interface.c" },
        .{ .name = "test-ka-tester", .source = "test/ka-tester.c" },
        .{ .name = "test-preferred-method", .source = "test/preferred-method.c" },
        .{ .name = "test-short-outbuf", .source = "test/short-outbuf.c" },
        .{ .name = "test-special-char-salt", .source = "test/special-char-salt.c" },
    };

    const test_cflags = [_][]const u8{
        "-std=gnu11",  // Changed from gnu99 to support C11 alignment features
        "-D_DEFAULT_SOURCE",
        "-D_GNU_SOURCE",
        "-DHAVE_CONFIG_H=1",
        "-fno-strict-aliasing",
        "-Wno-error",
    };

    for (test_programs) |test_prog| {
        const test_exe = b.addExecutable(.{
            .name = test_prog.name,
            .target = target,
            .optimize = optimize,
        });

        test_exe.addCSourceFile(.{
            .file = b.path(test_prog.source),
            .flags = &test_cflags,
        });

        test_exe.addIncludePath(b.path("lib"));
        test_exe.addIncludePath(b.path("test"));
        test_exe.addIncludePath(b.path("."));
        test_exe.addConfigHeader(config_header);

        test_exe.linkLibrary(lib);
        test_exe.linkLibC();

        const run_test = b.addRunArtifact(test_exe);
        run_test.has_side_effects = true;
        test_step.dependOn(&run_test.step);
    }

    // Example program demonstrating the library
    const example = b.addExecutable(.{
        .name = "crypt-example",
        .target = target,
        .optimize = optimize,
    });

    const example_src = b.addWriteFile("example.c",
        \\#include <stdio.h>
        \\#include <string.h>
        \\#include <stdlib.h>
        \\#include "crypt.h"
        \\
        \\int main() {
        \\    const char *password = "test123";
        \\
        \\    // Generate a salt for SHA-512
        \\    char *salt = crypt_gensalt("$6$", 0, NULL, 0);
        \\    if (salt) {
        \\        printf("Generated salt: %s\n", salt);
        \\
        \\        // Hash the password
        \\        char *hash = crypt(password, salt);
        \\        if (hash && hash[0] != '*') {
        \\            printf("Hashed password: %s\n", hash);
        \\
        \\            // Verify the password
        \\            char *verify = crypt(password, hash);
        \\            if (verify && strcmp(hash, verify) == 0) {
        \\                printf("Password verification: SUCCESS\n");
        \\            } else {
        \\                printf("Password verification: FAILED\n");
        \\            }
        \\        } else {
        \\            printf("Failed to hash password\n");
        \\        }
        \\        free(salt);
        \\    } else {
        \\        printf("Failed to generate salt\n");
        \\    }
        \\
        \\    return 0;
        \\}
    );

    example.addCSourceFile(.{
        .file = example_src.getDirectory().path(b, "example.c"),
        .flags = &[_][]const u8{
            "-std=c99",
            "-D_DEFAULT_SOURCE",
            "-D_GNU_SOURCE",
        },
    });

    example.addIncludePath(b.path("."));
    example.linkLibrary(lib);
    example.linkLibC();

    const run_example = b.addRunArtifact(example);
    const run_example_step = b.step("run-example", "Run the example program");
    run_example_step.dependOn(&run_example.step);

    // Information step
    const info_step = b.step("info", "Print build information");
    const info_run = b.addSystemCommand(&.{
        "echo",
        "libxcrypt build.zig - Full functionality",
        "\nSupported algorithms: All libxcrypt algorithms",
        "\nNotes:",
        "\n  - crypt-hashes.h must be generated with: perl build-aux/scripts/gen-crypt-hashes-h ...",
        "\n  - Uses -DIN_LIBCRYPT flag for correct symbol visibility",
        "\n  - All tests from test/ directory included",
    });
    info_step.dependOn(&info_run.step);
}