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

    // Generate config.h using addConfigHeader - minimal config
    const config_header = b.addConfigHeader(
        .{
            .style = .blank,
            .include_path = "config.h",
        },
        .{
            // Minimal system headers
            .HAVE_SYS_TYPES_H = 1,
            .HAVE_UNISTD_H = 1,
            .HAVE_STRING_H = 1,
            .HAVE_STDLIB_H = 1,
            .HAVE_STDINT_H = 1,
            .HAVE_ERRNO_H = 1,
            .HAVE_LIMITS_H = 1,
            .HAVE_STDBOOL_H = 1,
            .HAVE_STDALIGN_H = 1,

            // Memory functions
            .HAVE_EXPLICIT_BZERO = null,
            .HAVE_EXPLICIT_MEMSET = null,
            .HAVE_MEMSET_S = 1,

            // Endianness
            .WORDS_BIGENDIAN = 0,
            .ENDIANNESS_IS_LITTLE = 1,
            .ENDIANNESS_IS_BIG = null,
            .ENDIANNESS_IS_PDP = null,

            // Build configuration - start minimal
            .ENABLE_FAILURE_TOKENS = 1,
            .ENABLE_OBSOLETE_API = 0,
            .ENABLE_OBSOLETE_API_ENOSYS = 1,

            // Only enable SHA256 and SHA512 for now
            .INCLUDE_sha256crypt = 1,
            .INCLUDE_sha512crypt = 1,

            // Disable all other algorithms
            .INCLUDE_descrypt = 0,
            .INCLUDE_bigcrypt = 0,
            .INCLUDE_bsdicrypt = 0,
            .INCLUDE_md5crypt = 0,
            .INCLUDE_nt = 0,
            .INCLUDE_sunmd5 = 0,
            .INCLUDE_sha1crypt = 0,
            .INCLUDE_bcrypt = 0,
            .INCLUDE_bcrypt_a = 0,
            .INCLUDE_bcrypt_x = 0,
            .INCLUDE_bcrypt_y = 0,
            .INCLUDE_scrypt = 0,
            .INCLUDE_gost_yescrypt = 0,
            .INCLUDE_yescrypt = 0,
            .INCLUDE_sm3crypt = 0,
            .INCLUDE_sm3_yescrypt = 0,

            // Symbol versioning (disabled for static lib)
            .SYMVER_FLOOR = "",
            .SYMVER_CEILING = "",

            // Core functions
            .HAVE_FUNC_CRYPT = 1,
            .HAVE_FUNC_CRYPT_R = 1,
            .HAVE_FUNC_CRYPT_RN = 1,
            .HAVE_FUNC_CRYPT_GENSALT = 1,
            .HAVE_FUNC_CRYPT_GENSALT_R = 1,
            .HAVE_FUNC_CRYPT_GENSALT_RN = 1,
            .HAVE_FUNC_CRYPT_CHECKSALT = 1,
            .HAVE_FUNC_CRYPT_PREFERRED_METHOD = 1,

            // Compiler features
            .HAVE_STRONG_ALIAS = 1,
            .HAVE_STATIC_ASSERT_IN_ASSERT_H = 1,
            .HAVE__STATIC_ASSERT = 1,
            .HAVE_MAX_ALIGN_T = 1,

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

    // Minimal source files for SHA256/512
    const lib_sources = [_][]const u8{
        // Core algorithm files
        "lib/alg-sha256.c",
        "lib/alg-sha512.c",

        // Crypt implementations
        "lib/crypt-sha256.c",
        "lib/crypt-sha512.c",

        // Core infrastructure
        "lib/crypt.c",
        "lib/crypt-static.c",
        "lib/crypt-gensalt-static.c",

        // Utilities
        "lib/util-base64.c",
        "lib/util-gensalt-sha.c",
        "lib/util-get-random-bytes.c",
        "lib/util-make-failure-token.c",
        "lib/util-xbzero.c",
        "lib/util-xstrcpy.c",
    };

    // Compile flags
    const cflags = [_][]const u8{
        "-std=gnu11",
        "-D_DEFAULT_SOURCE",
        "-D_GNU_SOURCE",
        "-DHAVE_CONFIG_H=1",
        "-DIN_LIBCRYPT",
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

    // Minimal test set
    const test_step = b.step("test", "Run minimal tests");

    const test_programs = [_]struct {
        name: []const u8,
        source: []const u8,
    }{
        .{ .name = "test-alg-sha256", .source = "test/alg-sha256.c" },
        .{ .name = "test-alg-sha512", .source = "test/alg-sha512.c" },
        // These tests need more infrastructure:
        // .{ .name = "test-crypt-badargs", .source = "test/crypt-badargs.c" },
        // .{ .name = "test-gensalt", .source = "test/gensalt.c" },
    };

    const test_cflags = [_][]const u8{
        "-std=gnu11",
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
}