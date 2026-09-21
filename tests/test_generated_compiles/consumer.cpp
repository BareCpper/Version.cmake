// Consumes the generated header the way a real dependent target does.
#include "Version.hpp"

#include <cstdint>
#include <string_view>

// The fixture repository is tagged v2.3.4 with one commit after it.
static_assert(compiled::version::version_major == 2u);
static_assert(compiled::version::version_minor == 3u);
static_assert(compiled::version::version_patch == 4u);
static_assert(compiled::version::version_commit == 1u);

static_assert(!compiled::version::version_string.empty());
static_assert(!compiled::version::version_sha.empty());
static_assert(!compiled::version::version_date.empty());

// The C macros must agree with the constexpr constants above them: a consumer
// mixing a C ABI header with C++ call sites sees both.
static_assert(COMPILED_VERSION_MAJOR == 2);
static_assert(COMPILED_VERSION_MINOR == 3);
static_assert(COMPILED_VERSION_PATCH == 4);

int main()
{
    return static_cast<int>(compiled::version::version_major) - 2;
}
