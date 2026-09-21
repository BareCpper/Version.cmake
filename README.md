# Version.cmake

[![CI](https://github.com/BareCpper/Version.cmake/actions/workflows/ci.yml/badge.svg)](https://github.com/BareCpper/Version.cmake/actions/workflows/ci.yml)

Simplify your Semantic-Version automation within every developer build using code commits and repository tags.

## Prerequisites

1. Use [CMake](https://cmake.org/) to build your project.
2. Use [Git](https://git-scm.com/) as your code repository.
   <br/> :bulb: If you are using a different SCM please [raise an issue](https://github.com/BareCpper/Version.cmake/issues)
3. Structure your project. See [Here](https://cliutils.gitlab.io/modern-cmake/chapters/basics/structure.html).
4. Use _modern_ CMake features like targets and properties. See [here](https://pabloariasal.github.io/2018/02/19/its-time-to-do-cmake-right/) and [here](https://rix0r.nl/blog/2015/08/13/cmake-guide/).
5. Understand semantic versioning [here](https://semver.org/spec/v2.0.0.html) and [here](https://en.wikipedia.org/wiki/Software_versioning).
6. Tag your releases with the version prefixed by a `v`.
   <br/> :gem: This is now *optional* but still preferred - `Version.cmake` should detect if your tag is 'version-like'
7. Use a 'Prefix' for your project options in CMake options:
   <br/> :gem: Instead of `BUILD_TESTING` use `MYLIBRARY_BUILD_TESTING`

## Output Variables

All CMake variables use the form `VERSION_<field>`:

| Variable | Description | Example |
|---|---|---|
| `VERSION_SET` | `TRUE` if version fields were populated successfully | `TRUE` |
| `VERSION_IS_FALLBACK` | `TRUE` if the version came from `VERSION_FALLBACK` rather than a tag | `FALSE` |
| `VERSION_MAJOR` | Major semantic-version extracted from repository tag | `0` |
| `VERSION_MINOR` | Minor semantic-version extracted from repository tag | `1` |
| `VERSION_PATCH` | Patch semantic-version extracted from repository tag | `2` |
| `VERSION_COMMIT` | Commit count since last tag | `30` |
| `VERSION_SHA` | Revision-specific unique SHA hash | `4c757e7` |
| `VERSION_SEMANTIC` | Full semantic version `major.minor.patch.commit` | `0.1.2.30` |
| `VERSION_FULL` | Full git describe output, useful for ABI compatibility | `v0.1.2-30-g4c757e7-dirty` |
| `VERSION_DATE` | Configure-time build date | `2026-09-21` |
| `VERSION_DATETIME` | Configure-time build timestamp, ISO 8601 | `2026-09-21T14:32:05Z` |

## Adding Version.cmake

We recommend using [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake) so you stay up to date with the latest fixes and features.

Alternatively, you may directly include `Version.cmake` in your project but we don't encourage this as you may miss important updates.

### Basic Usage

After [adding CPM.cmake](https://github.com/cpm-cmake/CPM.cmake#adding-cpm), add the following to your `CMakeLists.txt`:

```cmake
CPMAddPackage("gh:BareCpper/Version.cmake@0.4")
```

You may wish to optionally set the project version on the `project(...)` call.
If so, we recommend checking `VERSION_SET`:

```cmake
if(NOT VERSION_SET)
    message(FATAL_ERROR "Version.cmake is required")
endif()
project(MyProject VERSION ${VERSION_SEMANTIC})
```

To use the version information within a CMake build target:
1. Add `version::version` to the `target_link_libraries` for the target library/executable.
2. Add `Version.h` via the `#include` directive.
3. Use the `VERSION_<field>` preprocessor values in your code.
   <br/> :gem: The default template defines C-preprocessor directives. For C++17 and later, see the [constexpr template](#c17-usage-constexpr-namespace) below.

```cmake
target_link_libraries(MyLibrary
    PRIVATE
        version::version
)
```
```cpp
#include "Version.h"
```

## Configuration Variables

All variables are optional -- sensible defaults are provided for every one.
Override any of them in your `CMakeLists.txt` before calling `CPMAddPackage` / `include(Version.cmake)`:

| Variable | Default | Description |
|---|---|---|
| `VERSION_OUT_DIR` | `CMAKE_BINARY_DIR` | Output directory for the generated header. Override to place the header inside a sub-directory already on the include path (e.g. `${CMAKE_BINARY_DIR}/include/myapp`). |
| `VERSION_SOURCE_DIR` | `CMAKE_SOURCE_DIR` | The git repository root to query. Override for sub-module or CPM-fetched versioning. |
| `VERSION_PREFIX` | `""` | Optional prefix for C preprocessor macros. `"MYAPP_"` produces `MYAPP_VERSION_MAJOR`; a `_` separator is appended if you do not write one. Useful when multiple libraries use Version.cmake in the same build. |
| `VERSION_H_FILENAME` | `"${VERSION_PREFIX}Version.h"` | Output filename. Set to `"Version.hpp"` to select the C++17 `constexpr` template instead of the default C-preprocessor template. The template lookup ignores case, so `"version.hpp"` selects the same one. |
| `VERSION_H_TEMPLATE` | *(looked up from `VERSION_H_FILENAME`)* | Path to the `.in` template, used as-is. Set it to generate from a template outside the Version.cmake package directory. |
| `VERSION_NAMESPACE` | `""` | Optional C++ namespace for `constexpr` constants in `Version.hpp.in`. Supports nested namespaces (e.g. `"myapp::version"`). Only used when `VERSION_H_FILENAME` ends in `.hpp`. |
| `VERSION_TAG_PATTERN` | `"v[0-9]*"` | glob(7) pattern(s) of tags `git describe` may select. Accepts a CMake list, expanded to one `--match` flag per element. Set to `""` to consider every tag. |
| `VERSION_TAG_EXCLUDE_PATTERN` | `"v[0-9]*[._][0-9]*[._][0-9]*-[0-9]*"` | glob(7) pattern(s) of tags `git describe` must reject, applied after `VERSION_TAG_PATTERN`. Accepts a CMake list. Set to `""` to reject nothing. |
| `VERSION_FALLBACK` | `PROJECT_VERSION`, else `0.0.0` | `major.minor.patch` used when no tag supplies a version. |

### Versioning a Nested Project

`VERSION_SOURCE_DIR` and `VERSION_OUT_DIR` default to `CMAKE_SOURCE_DIR` and `CMAKE_BINARY_DIR`, which belong to the *top-level* project. A library built as part of a larger tree -- a [west](https://docs.zephyrproject.org/latest/develop/west/index.html)-assembled Zephyr application, a git submodule, a CPM-fetched dependency -- would otherwise describe the outer repository and write its header into the outer build tree. Set both to the current directories before including:

```cmake
set(VERSION_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(VERSION_OUT_DIR    "${CMAKE_CURRENT_BINARY_DIR}/include/mylib")
CPMAddPackage("gh:BareCpper/Version.cmake@0.4")
```

### Which Tag Becomes the Version

Only version-shaped tags are candidates. `VERSION_TAG_PATTERN` defaults to `v[0-9]*`, so tags like `perfgate-pre-recovery` -- the safety tag many projects write before a risky git operation -- are ignored no matter how recent they are. Without that filter such a tag becomes the version, fails to parse, and the generated header carries no version at all.

`VERSION_TAG_EXCLUDE_PATTERN` is applied on top, and rejects 'tweak' tags of the form `v0.1.2-30` whose trailing `-30` collides with `git describe`'s own `-<commits>-g<sha>` suffix.

If your project tags differently, set the pattern to your convention. Both variables accept a list:

```cmake
# Un-prefixed release tags such as 2024.1.5, alongside the default v1.2.3 form
set(VERSION_TAG_PATTERN "v[0-9]*;[0-9]*")
```

:warning: The default exclude pattern only rejects `v`-prefixed tweak tags. If you override `VERSION_TAG_PATTERN` to accept un-prefixed tags, override `VERSION_TAG_EXCLUDE_PATTERN` to match, or a tag like `1.2.3-30` will be selected and fail to parse.

### When No Tag Matches

A fresh clone, or a project that has not tagged its first release, has no matching tag. `git describe --always` then returns a bare commit id, which is not a version.

Version.cmake never emits a header with empty fields in that case -- a header that compiles and ships while reporting no version at all is worse than a failed build. It falls back to `VERSION_FALLBACK`, which defaults to the version already declared on your `project()` call, keeps the commit count and SHA from git, and sets `VERSION_IS_FALLBACK`:

```cmake
project(MyProject VERSION 1.4.0)
CPMAddPackage("gh:BareCpper/Version.cmake@0.4")

# Release builds must carry a real tag; developer builds need not.
if(MYPROJECT_RELEASE AND VERSION_IS_FALLBACK)
    message(FATAL_ERROR "Release build has no ${VERSION_TAG_PATTERN} tag; got ${VERSION_FULL}")
endif()
```

This is reported at `STATUS` level, not as a warning: an untagged repository is an ordinary state its developer already knows about, and a warning on every configure of every fresh clone teaches people to ignore warnings. The one case that *does* warn is a tag that matched `VERSION_TAG_PATTERN` but failed to parse -- that means the pattern and the parser disagree, which is a real configuration bug and the one that silently produced version-less builds.

### C++17 Usage (constexpr namespace)

Set `VERSION_H_FILENAME` and `VERSION_NAMESPACE` to get `inline constexpr` constants in a named namespace:
<br/> :gem: This is the recommended approach for C++17 (and later) projects.

```cmake
set(VERSION_OUT_DIR    "${CMAKE_BINARY_DIR}/include/myapp")
set(VERSION_PREFIX     "MYAPP_")
set(VERSION_H_FILENAME "Version.hpp")
set(VERSION_NAMESPACE  "myapp::version")

CPMAddPackage("gh:BareCpper/Version.cmake@0.4")
target_link_libraries(MyLibrary PUBLIC version::version)
```

Generated `include/myapp/Version.hpp`:

```cpp
// Generated by Version.cmake -- do not edit.
#pragma once
#include <cstdint>
#include <string_view>

namespace myapp::version {
    inline constexpr std::uint32_t  version_major   = 0;
    inline constexpr std::uint32_t  version_minor   = 1;
    inline constexpr std::uint32_t  version_patch   = 2;
    inline constexpr std::uint32_t  version_commit  = 30;
    inline constexpr std::string_view version_sha    = "4c757e7";
    inline constexpr std::string_view version_string = "0.1.2.30";
    inline constexpr std::string_view version_full   = "v0.1.2-30-g4c757e7";
    inline constexpr std::string_view version_date   = "2026-09-21";
} // namespace myapp::version

// C preprocessor macros, for C ABI headers and C++ that predates the above
#define MYAPP_VERSION_MAJOR    0
#define MYAPP_VERSION_SEMANTIC "0.1.2.30"
// ...
```

```cpp
#include "myapp/Version.hpp"

// C++ constexpr path
static_assert(myapp::version::version_major >= 0);

// C legacy path (e.g. in a C ABI header)
// MYAPP_VERSION_MAJOR == 0
```

### Custom Templates

`VERSION_H_FILENAME` names the header to generate; `VERSION_H_TEMPLATE` names the `.in` file it is generated from. Point the latter at your own template anywhere on disk:

```cmake
set(VERSION_H_FILENAME "MyVersion.h")
set(VERSION_H_TEMPLATE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/MyVersion.h.in")
```

A `VERSION_H_TEMPLATE` that does not exist stops the configure with an error, rather than falling through to some other template.

With `VERSION_H_TEMPLATE` unset, the template is looked up by name in the Version.cmake package directory: `Version.h.in` for the default C output, `Version.hpp.in` for the C++ one. That lookup ignores case, so `version.hpp` and `Version.hpp` select the same template on a case-sensitive filesystem as well as on Windows and macOS. A filename this package ships no template for is generated from a copy of the default C template.

Available substitution variables inside any template:

| Template variable | Value |
|---|---|
| `@_VERSION_MAJOR@` | Major component (integer) |
| `@_VERSION_MINOR@` | Minor component (integer) |
| `@_VERSION_PATCH@` | Patch component (integer) |
| `@_VERSION_COMMIT@` | Commit count (integer) |
| `@_VERSION_SHA@` | Short SHA string |
| `@_VERSION_SEMANTIC@` | Full semantic string |
| `@_VERSION_FULL@` | Full git describe string |
| `@_VERSION_PREFIX@` | Resolved prefix (with trailing `_` if non-empty) |
| `@_VERSION_NAMESPACE_BEGIN@` | `namespace X {` or empty |
| `@_VERSION_NAMESPACE_END@` | `} // namespace X` or empty |

# Advantages
- **Small and reusable** so can be added to any CMake build.
- **No re-configuring of CMake necessary** -- the build-time step updates version information transparently.
- **C and C++ compatible** -- default template uses C preprocessor; C++17 `constexpr` template available via `VERSION_H_FILENAME`.
- **Namespace scoping** -- `VERSION_NAMESPACE` prevents symbol collisions when multiple libraries use Version.cmake.
- **Prefix scoping** -- `VERSION_PREFIX` scopes C preprocessor macros.

# Limitations
- Git on `PATH` at build time is needed for the commit count, SHA and dirty flag. Without it the build still succeeds, reporting `VERSION_FALLBACK` with `VERSION_IS_FALLBACK` set.
- The generated header is regenerated on every build (tracks `HEAD` and `.git/index`) -- this is intentional, ensuring version information always reflects the actual commit.
- Only the built-in semantic-version shape is parsed by default. A tag matching `VERSION_TAG_PATTERN` in a form the parser does not accept warns and falls back; supply `VERSION_PARSE_FUNCTION` for a different scheme.
- Configure-time consumers of the version -- `CPACK_PACKAGE_VERSION`, target `VERSION` properties, `install()` filenames -- keep the value from the last `cmake` run. The build-time step regenerates the header and nothing else, so an installer packaged after further commits carries the version of the last configure. Re-run `cmake` before `cpack` to refresh it.
- No support for non-git SCMs -- [raise an issue](https://github.com/BareCpper/Version.cmake/issues) if you need support for another SCM.
