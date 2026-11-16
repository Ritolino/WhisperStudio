import Foundation

struct SemVer: Comparable, Sendable {
    let major: Int
    let minor: Int
    let patch: Int

    init(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let noV = (trimmed.hasPrefix("v") || trimmed.hasPrefix("V")) ? String(trimmed.dropFirst()) : trimmed
        let numericPrefix = noV.split(separator: "-", maxSplits: 1).first.map(String.init) ?? noV
        let parts = numericPrefix.split(separator: ".").map { Int($0) ?? 0 }
        self.major = parts.count > 0 ? parts[0] : 0
        self.minor = parts.count > 1 ? parts[1] : 0
        self.patch = parts.count > 2 ? parts[2] : 0
    }

    static func < (lhs: SemVer, rhs: SemVer) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}

struct AvailableUpdateInfo: Identifiable, Sendable {
    let id = UUID()
    let tagName: String
    let releaseName: String
    let body: String
    let htmlURL: URL
    let downloadURL: URL

    var displayTag: String {
        tagName.lowercased().hasPrefix("v") ? tagName : "v\(tagName)"
    }
}

private struct GitHubReleaseAssetDTO: Decodable, Sendable {
    let name: String
    let browser_download_url: String
}

private struct GitHubReleaseDTO: Decodable, Sendable {
    let tag_name: String
    let name: String?
    let body: String?
    let html_url: String?
    let draft: Bool?
    let prerelease: Bool?
    let assets: [GitHubReleaseAssetDTO]?
}

enum UpdateCheckOutcome: Sendable {
    case available(AvailableUpdateInfo)
    case upToDate
    case failed(String)
}

enum UpdateCheckerService {
    static func selectPlatformAssetURL(assets: [AvailableUpdateAsset], fallback: URL) -> URL {
        let includeTokens = ["macos", "mac", "osx", "darwin"]
        let excludeTokens = ["windows", "win64", "win32", "linux"]
        let validExts = [".dmg", ".zip"]

        for ext in validExts {
            for asset in assets {
                let lower = asset.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard lower.hasSuffix(ext) else { continue }
                if excludeTokens.contains(where: { lower.contains($0) }) { continue }
                if includeTokens.contains(where: { lower.contains($0) }),
                   let url = URL(string: asset.downloadURLString) {
                    return url
                }
            }
        }
        return fallback
    }

    struct AvailableUpdateAsset: Sendable {
        let name: String
        let downloadURLString: String
    }

    static func checkLatestRelease(
        currentVersion: String = AppConstants.version,
        isManual: Bool,
        skippedVersion: String,
        snoozedVersion: String,
        snoozedUntil: Double
    ) async -> UpdateCheckOutcome {
        guard let apiURL = URL(string: "https://api.github.com/repos/\(AppConstants.githubRepo)/releases/latest") else {
            return .failed("Invalid GitHub URL")
        }

        var req = URLRequest(url: apiURL, timeoutInterval: 10)
        req.setValue("WhisperStudio/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                return .failed("HTTP \(http.statusCode)")
            }

            let dto = try JSONDecoder().decode(GitHubReleaseDTO.self, from: data)
            let tag = dto.tag_name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !tag.isEmpty else {
                return .failed("Release tag missing")
            }
            if dto.draft == true || dto.prerelease == true {
                return .upToDate
            }

            let remoteSemVer = SemVer(tag)
            let currentSemVer = SemVer(currentVersion)
            guard remoteSemVer > currentSemVer else {
                return .upToDate
            }

            if !isManual {
                if !skippedVersion.isEmpty && remoteSemVer <= SemVer(skippedVersion) {
                    return .upToDate
                }
                if !snoozedVersion.isEmpty && snoozedUntil > Date().timeIntervalSince1970 && remoteSemVer <= SemVer(snoozedVersion) {
                    return .upToDate
                }
            }

            let fallbackString = dto.html_url ?? "https://github.com/\(AppConstants.githubRepo)/releases"
            let htmlURL = URL(string: fallbackString) ?? URL(string: "https://github.com/\(AppConstants.githubRepo)/releases")!
            let mappedAssets = (dto.assets ?? []).map {
                AvailableUpdateAsset(name: $0.name, downloadURLString: $0.browser_download_url)
            }
            let dlURL = selectPlatformAssetURL(assets: mappedAssets, fallback: htmlURL)

            let info = AvailableUpdateInfo(
                tagName: tag,
                releaseName: (dto.name?.isEmpty == false ? dto.name! : tag),
                body: dto.body ?? "",
                htmlURL: htmlURL,
                downloadURL: dlURL
            )
            return .available(info)
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
