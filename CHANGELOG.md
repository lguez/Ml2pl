# Changelog

## 0.7 (2026-03-12)

### Changed

- Replace wrapper script `ml2pl.sh` by `ml2pl.py` (51a0ea27, f6d78f34)
- Look for `ml2pl_runtime_env.py` instead of `ml2pl_runtime_env.sh` in
  LIBEXECDIR (f6d78f34)
- Download specific versions of the libraries (167a9bec, ef31712f)

### Added

- Add option `--version` to wrapper script
- Allow comma-separated lists of variables
- Do not require units attribute for input pressure
- Do not require descending pressure (99dd2e63)
