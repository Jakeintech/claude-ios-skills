import SwiftUI
import UIKit
import Testing
@testable import APPNAME

/// Minimal image snapshot testing with no third-party dependency.
///
/// A view is hosted in a real `UIWindow` (so Lists, navigation and glass
/// render as they do in the app) at a given size and size class, drawn with
/// `drawHierarchy`, and compared with a reference PNG committed under
/// `APPNAMETests/__Snapshots__/`.
///
/// - Missing reference: the image is recorded and the test fails once with
///   "recorded", so a new snapshot is always looked at before it counts.
/// - `APP_RECORD_SNAPSHOTS=1` in the scheme's environment re-records all.
/// - Every run also writes the rendered image and, on mismatch, a diff to
///   `$APP_SNAPSHOT_ARTIFACTS` (default: the test's tmp dir) for review.
///
/// References depend on the simulator runtime's fonts and rendering, so
/// they are recorded on one simulator (see docs/foldable-layout.md) and
/// compared on that runtime. An iPad host draws the same views with its own
/// safe area and text metrics, so iPad runs keep their own references in
/// `__Snapshots__/<suite>-iPad/`, and iPhones on the iOS 27 runtime (the
/// foldable iPhone simulator) keep theirs in `__Snapshots__/<suite>-iOS27/`
/// (inner display) and `__Snapshots__/<suite>-iOS27-cover/` (cover screen).
@MainActor
enum Snapshot {

    struct Size: Sendable {
        let name: String
        let width: CGFloat
        let height: CGFloat
        let horizontalSizeClass: UIUserInterfaceSizeClass

        /// Folded cover screen: phone-shaped, compact width.
        static let cover = Size(name: "cover", width: 390, height: 844, horizontalSizeClass: .compact)
        /// Unfolded inner display: book-shaped, regular width. Close to the
        /// rumoured ~7.8in panel; the rules key off width, not this exact size.
        static let inner = Size(name: "inner", width: 960, height: 1080, horizontalSizeClass: .regular)
        /// A sidebar column on the inner display.
        static let sidebar = Size(name: "sidebar", width: 360, height: 240, horizontalSizeClass: .compact)
        /// A detail column on the inner display.
        static let detail = Size(name: "detail", width: 600, height: 520, horizontalSizeClass: .regular)
    }

    /// Render `view` at `size` in a window.
    static func render<V: View>(
        _ view: V,
        size: Size,
        dynamicType: UIContentSizeCategory = .large
    ) async throws -> UIImage {
        let scene = try #require(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "Snapshot tests need the app host's window scene"
        )
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        window.traitOverrides.horizontalSizeClass = size.horizontalSizeClass
        window.traitOverrides.preferredContentSizeCategory = dynamicType
        window.traitOverrides.userInterfaceStyle = .dark
        let host = UIHostingController(rootView: view.preferredColorScheme(.dark))
        host.view.backgroundColor = UIColor(Theme.background)
        window.rootViewController = host
        window.isHidden = false
        window.layoutIfNeeded()
        // Let SwiftUI settle (tasks, geometry callbacks, async layout).
        try await Task.sleep(for: .milliseconds(400))
        window.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        window.rootViewController = nil
        return image
    }

    /// Compare against (or record) `__Snapshots__/<suite>/<name>.png`.
    static func assertMatches(
        _ image: UIImage,
        named name: String,
        tolerance: Double = 0.01,
        folder: String? = nil,
        filePath: String = #filePath,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let testFile = URL(fileURLWithPath: filePath)
        let suite = testFile.deletingPathExtension().lastPathComponent
        let referenceDir = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            // `folder` is for images that do not depend on the host's
            // screen (rendered share cards), so one set serves every device.
            .appendingPathComponent(folder ?? referenceFolder(for: suite))
        let reference = referenceDir.appendingPathComponent("\(name).png")
        let png = try #require(image.pngData())

        writeArtifact(png, name: "\(suite)-\(name).png")

        let recordAll = ProcessInfo.processInfo.environment["APP_RECORD_SNAPSHOTS"] == "1"
        guard !recordAll, let referenceData = try? Data(contentsOf: reference) else {
            try FileManager.default.createDirectory(at: referenceDir, withIntermediateDirectories: true)
            try png.write(to: reference)
            Issue.record("Recorded snapshot \(name) at \(reference.path). Review it and run again.",
                         sourceLocation: sourceLocation)
            return
        }

        let referenceImage = try #require(UIImage(data: referenceData))
        let result = compare(image, referenceImage)
        if let diff = result.diff?.pngData() { writeArtifact(diff, name: "\(suite)-\(name)-diff.png") }
        #expect(result.sameSize, "Snapshot \(name) changed size", sourceLocation: sourceLocation)
        #expect(result.differingFraction <= tolerance,
                "Snapshot \(name) differs in \(String(format: "%.2f", result.differingFraction * 100))% of pixels",
                sourceLocation: sourceLocation)
    }

    /// iPhone references keep the plain suite name; iPad hosts get their own.
    /// iPhone hosts on the iOS 27 runtime (recorded on the foldable iPhone
    /// simulator) get `-iOS27`: the new runtime draws text and glass
    /// differently, so its references can't be shared with iOS 26.
    ///
    /// On the iOS 27 runtime the host can be the foldable iPhone, and its
    /// cover screen (compact width) draws navigation bars differently from
    /// the inner display (the system moves bar items into a side rail), so
    /// a cover-screen host keeps its own `-iOS27-cover` set.
    ///
    /// A regular (non-folding) iPhone on the iOS 27 runtime is also compact
    /// but draws with its own screen and text metrics, so it keeps a separate
    /// `-iOS27-iPhone` set. It is told apart from the foldable's cover screen
    /// by shape: a regular iPhone screen is tall (about 2.2:1), the cover
    /// screen is short (about 1.5:1).
    private static func referenceFolder(for suite: String) -> String {
        if UIDevice.current.userInterfaceIdiom == .pad { return "\(suite)-iPad" }
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27 {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }.first
            let hostIsCompact = scene?.traitCollection.horizontalSizeClass == .compact
            guard hostIsCompact else { return "\(suite)-iOS27" }
            let bounds = scene?.screen.bounds ?? .zero
            let aspect = max(bounds.width, bounds.height) / max(min(bounds.width, bounds.height), 1)
            return aspect > 1.8 ? "\(suite)-iOS27-iPhone" : "\(suite)-iOS27-cover"
        }
        return suite
    }

    // MARK: Comparison

    struct Comparison {
        let sameSize: Bool
        let differingFraction: Double
        let diff: UIImage?
    }

    static func compare(_ a: UIImage, _ b: UIImage, channelThreshold: Int = 12) -> Comparison {
        guard let pa = pixels(a), let pb = pixels(b), pa.width == pb.width, pa.height == pb.height else {
            return Comparison(sameSize: false, differingFraction: 1, diff: nil)
        }
        var differing = 0
        var diffBytes = [UInt8](repeating: 0, count: pa.bytes.count)
        for i in stride(from: 0, to: pa.bytes.count, by: 4) {
            var delta = 0
            for c in 0..<3 { delta = max(delta, abs(Int(pa.bytes[i + c]) - Int(pb.bytes[i + c]))) }
            if delta > channelThreshold {
                differing += 1
                diffBytes[i] = 255; diffBytes[i + 3] = 255
            } else {
                let grey = UInt8(Int(pa.bytes[i]) / 4)
                diffBytes[i] = grey; diffBytes[i + 1] = grey; diffBytes[i + 2] = grey; diffBytes[i + 3] = 255
            }
        }
        let total = pa.width * pa.height
        return Comparison(sameSize: true,
                          differingFraction: total == 0 ? 0 : Double(differing) / Double(total),
                          diff: image(from: diffBytes, width: pa.width, height: pa.height))
    }

    private static func pixels(_ image: UIImage) -> (bytes: [UInt8], width: Int, height: Int)? {
        guard let cg = image.cgImage else { return nil }
        let width = cg.width, height = cg.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let ctx = CGContext(data: buffer.baseAddress, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: width * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? (bytes, width, height) : nil
    }

    private static func image(from bytes: [UInt8], width: Int, height: Int) -> UIImage? {
        var bytes = bytes
        let cg: CGImage? = bytes.withUnsafeMutableBytes { buffer in
            CGContext(data: buffer.baseAddress, width: width, height: height,
                      bitsPerComponent: 8, bytesPerRow: width * 4,
                      space: CGColorSpaceCreateDeviceRGB(),
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?.makeImage()
        }
        return cg.map { UIImage(cgImage: $0) }
    }

    private static func writeArtifact(_ data: Data, name: String) {
        let dir = ProcessInfo.processInfo.environment["APP_SNAPSHOT_ARTIFACTS"].map(URL.init(fileURLWithPath:))
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("APPNAMESnapshots")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: dir.appendingPathComponent(name))
    }
}
