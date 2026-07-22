load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

# Vendored NovagramAds SDK — pure-Foundation, zero-dependency typed client for the
# Channel Management API (ads-api.vipads.uz). Source of truth is the standalone
# SwiftPM package at repo-root /NovagramAds; re-copy Sources/NovagramAds/ here when
# that package changes (Bazel can't read an external Package.swift, so the sources
# are vendored).
#
# One fork-local addition on top of the upstream package, needed because this app
# ships down to iOS 13 while the SDK targets iOS 16.4:
#   - Core/SDKURLSessionCompat.swift  (added) — a `URLSession.sdkData(for:)` shim.
#   - Core/SDKRequestExecutor.swift    (1 line) — calls `sdkData(for:)` not `data(for:)`.
# Both edits are mirrored back into the source-of-truth package so a re-copy is safe.
swift_library(
    name = "NovagramAds",
    module_name = "NovagramAds",
    srcs = glob(["Sources/NovagramAds/**/*.swift"]),
    visibility = ["//visibility:public"],
)

# Novagram bridge: turns a search-ads result from the SDK into a resolved Telegram
# peer + a SwiftSignalKit Signal that global search can render at the top of its
# results. Keeps all Telegram-type dependencies out of the pure SDK above.
swift_library(
    name = "FenixNovagramAds",
    module_name = "FenixNovagramAds",
    srcs = glob(["Sources/FenixNovagramAds/**/*.swift"]),
    deps = [
        ":NovagramAds",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/Postbox:Postbox",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/AccountContext:AccountContext",
        "//submodules/Fenixuz/ProMessager:FenixuzProMessager",
    ],
    visibility = ["//visibility:public"],
)
