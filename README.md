# rules_maven_bom

![CI](https://github.com/slamdev/rules_maven_bom/workflows/build/badge.svg?branch=main)

Bazel rules to import versions from maven BOM files.

## Usage

Add the following to your WORKSPACE file:

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

RULES_MAVEN_BOM_VERSION = ""
RULES_MAVEN_BOM_SHA256 = ""

http_archive(
    name = "slamdev_rules_maven_bom",
    strip_prefix = "rules_maven_bom-%s" % RULES_MAVEN_BOM_VERSION,
    url = "https://github.com/slamdev/rules_maven_bom/archive/%s.tar.gz" % RULES_MAVEN_BOM_VERSION,
    sha256 = RULES_MAVEN_BOM_SHA256
)

load("@slamdev_rules_maven_bom//maven_bom:deps.bzl", "maven_bom_rules_dependencies", "maven_bom_import")

maven_bom_rules_dependencies()

maven_bom_import([
    "org.springframework.boot:spring-boot-dependencies:2.4.4",
    "io.opentelemetry:opentelemetry-bom:1.1.0",
], [
    "https://repo1.maven.org/maven2",
])
```

Then you can use version from boms in rules_jvm_external:

```starlark
load("@maven_bom//:defs.bzl", "MAVEN_BOMS")
load("@rules_jvm_external//:defs.bzl", "maven_install")

def maven_deps():
    maven_install(
        artifacts = [
            MAVEN_BOMS.get("org.springframework.boot:spring-boot-starter-web"),
        ],
    )
```
