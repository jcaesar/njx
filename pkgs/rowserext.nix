# We need bit-by-bit reproducible builds so the signatures work, so we can't update rustc.
# Really, it would be better to just upload the signed extensions somewhere…
{}: (builtins.getFlake "github:jcaesar/rowserext/c1f86795792f8984f8d6d9302f9b8689e847f7cd").packages.x86_64-linux.default
