# UN1CA sm7325 kernel CI

Build scripts and GitHub Actions CI for the UN1CA sm7325 kernel
(Galaxy A52s 5G `a52sxq`, Galaxy A73 5G `a73xq`, Galaxy M52 5G `m52xq`).

The kernel source lives on the `sixteen` branch of this repository.

## CI

Run the **Build kernel** workflow from the Actions tab:

- `kernel_ref`: kernel branch/tag/commit to build (default: `sixteen`)
- `release`: upload the images to a new GitHub Release
- `changelog`: optional release notes

Release assets, per target:

| File | Content |
| --- | --- |
| `Image-<target>` | Kernel image |
| `dtbo-<target>.img` | DTBO image |
| `dtb-<target>` | SoC base DTB (vendor_boot) |
| `modules-<target>.tar.gz` | Stripped kernel modules |
| `sha256sums-<target>.txt` | Checksums |

## Local build

```sh
git clone -b sixteen https://github.com/UN1CA/kernel_samsung_sm7325 kernel
# Extract clang-r614150 into ./llvm-aosp
./build.sh <a52sxq|a73xq|m52xq>
```

Output is placed in `dist/`. `KERNEL_DIR`, `LLVM_DIR`, `OUT_DIR` and
`DIST_DIR` can be overridden through the environment.
