# Version.cmake
Simplify your Semantic-Version automation within every developer build using code commits and repository tags.

## Prerequisites

1. Use [CMake](https://cmake.org/) to build your project.
2. Use [Git](https://git-scm.com/) as your code repository 
   <br/> :bulb: If you are using a different SCM please [raise an issue](https://github.com/BareCpper/Version.cmake/issues)
3. Structure your project. See [Here](https://cliutils.gitlab.io/modern-cmake/chapters/basics/structure.html).
4. Use _modern_ CMake features like targets and properties. See [here](https://pabloariasal.github.io/2018/02/19/its-time-to-do-cmake-right/) and [here](https://rix0r.nl/blog/2015/08/13/cmake-guide/).
5. Understand semantic versioning [here](https://semver.org/spec/v2.0.0.html) and [here](https://en.wikipedia.org/wiki/Software_versioning).
6. Tag your releases with the version prefixed by a `v`.
   <br/> :gem: This is now *optional* but still preferred - `Version.cmake` should detect if your tag is 'version-like'
7. Use a 'Prefix' for your project options in CMake options:
   <br/> :gem: Instead of `BUILD_TESTING` use `MYLIBRARY_BUILD_TESTING`

## Output Variables
All variables use the form `VERSION_<field>`

Values are defined similar both `CMake` and via the default `Version.h` using C-Preprocessor:or:
- `VERSION_SET` - Boolean indicating if `VERSION_<fields>` have been populated
- `VERSION_MAJOR` - Major semantic-version extracted from repository tag
- `VERSION_MINOR` - Minor semantic-version extracted from repository tag
- `VERSION_PATCH` - Patch semantic-version extracted from repository tag
- `VERSION_COMMIT` - Commit-count semantic-version extracted from repository branch revision
- `VERSION_SHA` - Revision specific unique SHA hash. For example `4c757e7`
- `VERSION_SEMANTIC` - Full semantic version in form `<major>.<minor>.<patch>.<commit>`. For example `0.1.0.10`
- `VERSION_FULL` - Full string description, useful for ABI compatiblity. For example `v0.1-9-g4c757e7-dirty`

## Adding Version.cmake

We recommend using [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake) so you stay upto-date with the latest fixes and features.

Alternative, you may directly include `Version.cmake` in your project but we don't encourage this.

### Basic Usage

After [adding CPM.cmake](https://github.com/cpm-cmake/CPM.cmake#adding-cpm), add the following line to the `CMakeLists.txt`.

```cmake
include(CPM)
CPMAddPackage("gh:BareCpper/Version.cmake")
```

You may wish to optionally set the PROJECT version on the `project(...)`. 
If so we recommend checking `VERSION_SET == True`:
```cmake
if ( NOT VERSION_SET )
    message( FATAL_ERROR "Version.cmake is required")
endif()
project( MyProject VERSION ${VERSION_SEMANTIC} ) 
```

To use the Version information within a cmake build target:
1. Add `version::version` to the `target_link_libraries` for the target library/executable etc
2. Add `Version.h` via the `#include` directive
3. Use the `VERSION_<field>` preprocessor values in your code
 <br/> :gem: The default template `.in` defines C-preprocessor directives. For Modern C++ we intent to support constexpr constants in an upcoming release. 

```cmake
target_link_libraries( MyLibrary
    PRIVATE
        version::version
)
```
```cpp
#include "Version.h"
```

# Advantages
- **Small and reusable** so can be added to any CMake build
- **Automatic update of buil-time variables** so code always has up-to date `Version.h` with no developer interaction.
- **Short Git-SHA available** so multiple-developers can generate unique build versions.
- **No re-configuring of CMake project necessary** as the build-time step will udpate version information for your build transparently.
- ...lots more to think about & list

# Limitations
- **CMake variables** are cached and do not reflect the current development version.
  <br/> :exclamation: This can affect version-name when using CPack Installers. See [Issue #1](https://github.com/BareCpper/Version.cmake/issues/1)
- **Only Git support is currently maintained** but we would love you to [raise an issue](https://github.com/BareCpper/Version.cmake/issues)