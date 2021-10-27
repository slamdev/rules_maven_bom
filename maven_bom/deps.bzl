load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@bazel_tools//tools/build_defs/repo:java.bzl", "java_import_external")

def maven_bom_rules_dependencies():
    maybe(
        java_import_external,
        name = "bom_versions_extractor",
        jar_urls = [
            "https://github.com/slamdev/bom-versions-extractor/releases/download/0.0.2/bom-versions-extractor.jar",
        ],
        jar_sha256 = "008da9f3508a4d85d687229f8c8be369d4d4dcd382f4f6929453de2ccccf5238",
    )

def maven_bom_import(boms, repos):
    _maven_bom_import(
        name = "maven_bom",
        boms = boms,
        repos = repos,
        debug = True,
    )

def _impl(ctx):
    jar_path = ctx.path(ctx.attr._cli)
    java_home = ctx.os.environ.get("JAVA_HOME")
    if java_home != None:
        java = ctx.path(java_home + "/bin/java")
        cmd = [java, "-jar", jar_path]
    elif ctx.which("java") != None:
        # Use 'java' from $PATH
        cmd = [ctx.which("java"), "-jar", jar_path]
    else:
        cmd = [jar_path]

    for r in ctx.attr.repos:
        cmd += ["-r", r]
    for b in ctx.attr.boms:
        cmd += ["-b", b]

    cmd += ["-f", ctx.path("versions.json")]
    cmd += ["-c", ctx.path("cache")]

    exec_result = ctx.execute(
        cmd,
        quiet = not ctx.attr.debug,
    )
    if exec_result.return_code != 0:
        fail("Unable to run bom-versions-extractor: " + exec_result.stderr)

    artifacts = json.decode(ctx.read("versions.json"))
    version_defs = []
    for a in artifacts:
        version_defs.append(
            """
        "{group}:{name}":"{group}:{name}:{version}",
                            """.format(group = a["group"], name = a["name"], version = a["version"]),
        )
    ctx.file("BUILD")
    ctx.file("defs.bzl", content = """
MAVEN_BOMS = {
%s
}
""" % "".join(version_defs))

_maven_bom_import = repository_rule(
    _impl,
    attrs = {
        "boms": attr.string_list(),
        "repos": attr.string_list(),
        "debug": attr.bool(),
        "_cli": attr.label(default = "@bom_versions_extractor//:bom-versions-extractor.jar"),
    },
    environ = [
        "JAVA_HOME",
    ],
    doc = ("Some doc should be here."),
)
