# WIT (appendix)

If this is your first plugin — you do not need WIT: [contract](00-contract.md). If you look at host sources — this chapter.

**Rule.** The author path does not copy `world.wit` and does not write `wit_bindgen::generate`. Bindings live inside `modus-sdk`. Host contract — [`wit/world.wit`](https://github.com/CaptainGnome/modus-sdk/blob/main/wit/world.wit) in [modus-sdk](https://github.com/CaptainGnome/modus-sdk), package `modus:abi@2.0.0`. Guest always on world **`plugin`**.

## Consequence

- Raw `wit_bindgen::generate` is accepted by the host if the component is valid.
- In one crate with `modus-sdk` — `pack` / `check` refuse: `manual WIT plus SDK — dual bindgen`.
- SDK crate major = ABI. Breaking WIT — new SDK major in the same release as the ABI.
- On disagreement between wrapper and WIT — WIT (host) wins; fix the bug in the SDK.

`modus dev` and Core speak the same ABI. Behavior mismatch = SDK or Core bug, not “a second ABI”.
