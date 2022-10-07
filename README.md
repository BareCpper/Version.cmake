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

## Adding Version.cmake

We recommend using [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake) so you stay upto-date with the latest fixes and features.

Alternative, you may directly include `Version.cmake` in your project but we don't encourage this.

### Basic Usage

After [adding CPM.cmake](https://github.com/cpm-cmake/CPM.cmake#adding-cpm), add the following line to the project's `CMakeLists.txt` after calling `project(...)`.

```cmake
include(CPM)
CPMAddPackage("gh:BareCpper/Version.cmake")

target_link_libraries( MyProject
    PRIVATE
        version::version
)
```

# Advantages
- **Small and reusable** so can be added to any CMake build
- **Every build** has access to Version.h information
- TODO: lots to think about & list
