# OpenCoreVideo implementation rules

Read `DESIGN.md` completely before changing this package.

- Preserve the Core Video responsibility: image-buffer representation, pixel
  layout, buffer ownership, attachments, pools, and access synchronization.
- Do not add capture-device discovery, media timing, codecs, inference, or Manas
  dependencies.
- Keep shared targets free of Foundation, Objective-C, Dispatch, JavaScriptKit,
  Darwin, Glibc, camera SDKs, and GPU SDKs.
- Platform integrations implement storage contracts outside the compatibility
  layer. Never branch on a camera model in OpenCoreVideo.
- Buffer access is zero-copy by default. Any required copy must be explicit in
  the API and justified in code.
- Borrowed plane or byte views may not outlive the owning buffer lease.
- Do not add an Apple-named declaration until its signature has been checked with
  `remark` and its behavior has a conformance test plan.
- Unsupported operations return a typed failure. Do not return empty buffers,
  invented dimensions, or placeholder storage as success.
- Tests use Swift Testing. Run focused `xcodebuild test` commands with a timeout,
  plus WASM and Embedded builds for shared-source changes.
