import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Ink
import HTMLString

struct Discover: Decodable {
    let articles: [Article]
    
    struct Article: Decodable {
        let id: UUID
        let datePosted: Date
        let shareURL: URL
        
        let localizations: [String: Localization]
        
        struct Localization: Decodable {
            let id: UUID
            let summaryComponents: [Component]
            let detailComponents: [Component]
        }
        
        struct Component: Decodable {
            let id: UUID
            let type: String
            let content: Content
            
            enum CodingKeys: String, CodingKey {
                case id
                case type
                case category
                case image
                case title
                case date
                case text
                case header
                case pullQuote
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                id = try container.decode(UUID.self, forKey: .id)
                type = try container.decode(String.self, forKey: .type)
                
                switch type {
                case "category":
                    content = .category
                case "image":
                    content = .image
                case "title":
                    content = .title(try container.decode(String.self, forKey: .title))
                case "date":
                    content = .date
                case "text":
                    content = .text(try container.decode(String.self, forKey: .text))
                case "separator": 
                    content = .separator
                case "header":
                    content = .header(try container.decode(String.self, forKey: .header))
                case "activity":
                    content = .activity
                case "pullQuote":
                    content = .pullQuote(try container.decode(PullQuote.self, forKey: .pullQuote))
                case "codeSnippet":
                    content = .codeSnippet
                case "resource":
                    content = .resource
                case "detailLink":
                    content = .detailLink
                default:
                    throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Found unexpected component type \(type)")
                }
            }
            
            enum Content: CustomStringConvertible {
                case category
                case image
                case title(String)
                case date
                case text(String)
                case separator
                case header(String)
                case activity
                case pullQuote(PullQuote)
                case codeSnippet
                case resource
                case detailLink
                
                var description: String {
                    switch self {
                    case .category:
                        return ""
                    case .image:
                        return ""
                    case .title(let title):
                        return title
                    case .date:
                        return ""
                    case .text(let text):
                        return text
                    case .separator:
                        return "<hr/>"
                    case .header(let header):
                        return header
                    case .activity:
                        return ""
                    case .pullQuote(let pullQuote):
                        return "<blockquote>\(pullQuote.quote)</blockquote><p>&mdash; \(pullQuote.author)</p>"
                    case .codeSnippet:
                        return ""
                    case .resource:
                        return ""
                    case .detailLink:
                        return ""
                    }
                }
            }
            
            struct PullQuote: Decodable {
                let quote: String
                let author: String
            }
        }
    }
}

let discoverJSONURL = URL(string: "https://devimages-cdn.apple.com/wwdc-services/n233a99f/5D23F1E9-9551-4768-ACF3-E3920F9C572D/discover.json")!
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601 
let rfc822DateFormatter = DateFormatter()
rfc822DateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
rfc822DateFormatter.locale = Locale(identifier: "en_US_POSIX")
let markdownParser = MarkdownParser()

func templateHeader(lastBuildDate: String) -> String { 
    """
    <?xml version="1.0"?>
    <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
        <channel>
            <title>Apple Developer - Discover</title>
            <link>http://developer.apple.com/discover</link>
            <description>A feed scraped from the JSON that backs the Apple Developer iOS app.</description>
            <language>en-us</language>
            <lastBuildDate>\(lastBuildDate)</lastBuildDate>
            <docs>https://github.com/interstateone/AppleDeveloperDiscover</docs>
            <ttl>1440</ttl>
            <atom:link href="https://interstateone.github.io/AppleDeveloperDiscover/feed.xml" rel="self" type="application/rss+xml" />
    """
}
func item(title: String, link: String, description: String, pubDate: String, guid: String) -> String {
    """
            <item>
                <title>\(title)</title>
                <link>\(link)</link>
                <description>\(description)</description>
                <pubDate>\(pubDate)</pubDate>
                <guid isPermaLink="false">\(guid)</guid>
            </item>
    """
}
let templateFooter = """
    </channel>
</rss>
"""

URLSession.shared.dataTask(with: discoverJSONURL) { possibleData, _, possibleError in
    if let error = possibleError {
        print(String(describing: error))
        exit(1)
    }
    guard let data = possibleData else {
        print("Received no data and no error")
        exit(1)
    }
    
    do {
        let discover = try decoder.decode(Discover.self, from: data)
        var output = templateHeader(lastBuildDate: rfc822DateFormatter.string(from: Date()))
        output += "\n"
        
        discover.articles.forEach {
            guard
                let englishLocalization = $0.localizations["eng"],
                let titleComponent = englishLocalization.detailComponents.first(where: { $0.type == "title" }) ??
                    englishLocalization.summaryComponents.first(where: { $0.type == "title" })
            else { return }

            let title = titleComponent.content.description.addingASCIIEntities
            let link = $0.shareURL.description
            var description = englishLocalization.detailComponents
                .reduce("") { description, component in
                    description + "\n" + component.content.description
                }
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if description.isEmpty {
                description = englishLocalization.summaryComponents
                    .reduce("") { description, component in
                        description + "\n" + component.content.description
                    }
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let html = markdownParser.html(from: description)
            let escapedHTML = html.addingASCIIEntities
            let pubDate = rfc822DateFormatter.string(from: $0.datePosted)
            let guid = $0.id.uuidString
            
            output += item(title: title, link: link, description: escapedHTML, pubDate: pubDate, guid: guid)
            output += "\n"
        }
        
        output += templateFooter
        
        try FileManager.default.createDirectory(atPath: "./output", withIntermediateDirectories: true, attributes: nil)
        try output.write(toFile: "./output/feed.xml", atomically: true, encoding: .utf8)
    } 
    catch {
        print(String(describing: error))
        exit(1)
    }

    print("./output/feed.xml")
    exit(0)
}.resume()

RunLoop.main.run()
