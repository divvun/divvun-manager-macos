# Páhkat Client for macOS

[![Build Status](https://dev.azure.com/divvun/divvun-installer/_apis/build/status/divvun.pahkat-client-macos?branchName=master)](https://dev.azure.com/divvun/divvun-installer/_build/latest?definitionId=8&branchName=master)

## Building

Ensure you have cloned this repository into the same directory as the [`divvun/pahkat-client-core`](https://github.com/divvun/pahkat-client-core) repository.

You will need the [Rust toolchain installed](https://www.rustup.rs/), as well as Xcode and Cocoapods.

After that, run `pod install`, open the `Pahkat.xcworkspace` and build as any other macOS project.

## Generating Localisations

This project uses [bbqsrc/strut-icu](https://github.com/bbqsrc/strut-icu) to manage the generation of localisations.

If you make an update to anything in `Pahkat/Support/LocalisationResources/`, run from the `Pahkat/` directory:

```
strut-icu-generate swift Support/LocalisationResources/base.yaml Support/LocalisationResources/{your other langs}.yaml
-o .
```

## License

GPLv3 — see LICENSE file.
