//
//  ContentModel.swift
//  portfoliopod
//
//  Scalable content architecture
//

import Combine
import Foundation

enum ContentType: String, Codable {
  case text
  case project
  case experiment
  case writing
  case utility
  case media
  case video
  case menu
}

struct MenuNode: Identifiable, Codable {
  let id: String
  let title: String
  var children: [MenuNode]?
  let contentType: ContentType
  let payloadID: String?
  let imageName: String?  // Added for custom preview images
  let iconPath: String?  // Added for icon-based navigation

  init(
    id: String, title: String, children: [MenuNode]? = nil, contentType: ContentType,
    payloadID: String? = nil, imageName: String? = nil, iconPath: String? = nil
  ) {
    self.id = id
    self.title = title
    self.children = children
    self.contentType = contentType
    self.payloadID = payloadID
    self.imageName = imageName
    self.iconPath = iconPath
  }
}

struct TextContent: Codable {
  let id: String
  let title: String?
  let body: String
  let bullets: [String]?
}

struct ProjectContent: Codable {
  let id: String
  let title: String
  let overview: String
  let outcome: [String]
}

struct ExperimentContent: Codable {
  let id: String
  let title: String
  let description: String
}

struct WritingContent: Codable {
  let id: String
  let title: String
  let body: String
  let estimatedReadingTime: Int?  // in minutes
}

struct TimelineEntry: Codable {
  let period: String
  let role: String
  let context: String
  let bullets: [String]
}

// Content store
class ContentStore: ObservableObject {
  @Published var rootMenu: MenuNode

  var allNodes: [MenuNode] {
    var result: [MenuNode] = []
    func flatten(_ node: MenuNode) {
      if node.contentType != .menu {
        result.append(node)
      }
      node.children?.forEach { flatten($0) }
    }
    flatten(rootMenu)
    return result
  }

  init() {
    self.rootMenu = ContentStore.createDefaultContent()
  }

  static func createDefaultContent() -> MenuNode {
    return MenuNode(
      id: "root",
      title: "INITIALIZING...",
      children: [
        MenuNode(
          id: "music-library",
          title: "music",
          contentType: .media,
          payloadID: "library"
        ),
        MenuNode(
          id: "works",
          title: "work",
          children: [
            MenuNode(
              id: "ninjacart", title: "NinjaCart Repayment", contentType: .project,
              payloadID: "ninjacart"),
            MenuNode(
              id: "airtribe-sales", title: "Airtribe Sales System", contentType: .project,
              payloadID: "airtribe-sales"),
            MenuNode(
              id: "summarify", title: "Summarify.me", contentType: .project, payloadID: "summarify"),
            MenuNode(
              id: "loops", title: "Loops: Music Site", contentType: .project, payloadID: "loops"),
            MenuNode(
              id: "taxes", title: "Taxes iOS App", contentType: .project, payloadID: "taxes"),
          ],
          contentType: .menu
        ),
        MenuNode(
          id: "about",
          title: "about",
          children: [
            MenuNode(id: "who-am-i", title: "who am i?", contentType: .text, payloadID: "who-am-i"),
            MenuNode(
              id: "experience", title: "experience", contentType: .text, payloadID: "experience"),
            MenuNode(
              id: "philosophy", title: "philosophy", contentType: .text, payloadID: "philosophy"),
          ],
          contentType: .menu,
          imageName: "preview_about"
        ),
        MenuNode(
          id: "playground",
          title: "playground",
          children: [
            MenuNode(
              id: "experiments", title: "experiments", contentType: .text,
              payloadID: "about-experiments"),
            MenuNode(
              id: "podbreaker", title: "PodBreaker", contentType: .experiment,
              payloadID: "podbreaker"
            ),
            MenuNode(
              id: "coverflow", title: "Cover Flow", contentType: .experiment,
              payloadID: "coverflow"
            ),
            MenuNode(
              id: "nowplaying", title: "Now Playing", contentType: .media,
              payloadID: "nowplaying"
            ),
          ],
          contentType: .menu,
          imageName: "preview_experiments"
        ),
        MenuNode(
          id: "musings",
          title: "musings",
          children: [
            MenuNode(
              id: "design-systems", title: "On Design Systems", contentType: .writing,
              payloadID: "design-systems"),
            MenuNode(
              id: "interaction", title: "Micro-Interactions", contentType: .writing,
              payloadID: "interaction"),
          ],
          contentType: .menu
        ),
        MenuNode(
          id: "resume",
          title: "resume",
          contentType: .text,
          payloadID: "resume"
        ),
        MenuNode(
          id: "extras",
          title: "extras",
          children: [
            MenuNode(id: "clock", title: "Clock", contentType: .utility, payloadID: "clock"),
            MenuNode(id: "notes", title: "Notes", contentType: .utility, payloadID: "notes"),
            MenuNode(
              id: "browser", title: "Safari (Framer)", contentType: .utility, payloadID: "browser"),
          ],
          contentType: .menu
        ),
        MenuNode(
          id: "search",
          title: "search",
          contentType: .utility,
          payloadID: "search"
        ),
        MenuNode(
          id: "settings",
          title: "settings",
          children: [
            MenuNode(id: "haptics", title: "Haptics", contentType: .utility, payloadID: "haptics"),
            MenuNode(
              id: "clicker", title: "Clicker Sound", contentType: .utility, payloadID: "clicker"),
            MenuNode(
              id: "theme", title: "Legal & Legal", contentType: .utility, payloadID: "legal"),  // Settings/About hybrid
          ],
          contentType: .menu
        ),
      ],
      contentType: .menu
    )
  }

  func getTextContent(id: String) -> TextContent? {
    let content: [String: TextContent] = [
      "who-am-i": TextContent(
        id: "who-am-i",
        title: "who am i?",
        body:
          "i ask, i explore, i tinker.\n\nhey, i’m anurag. a product designer exploring how systems, behavior, and design come together to make technology feel more human.",
        bullets: [
          "currently building learning tools at Airtribe",
          "earlier: Newton School, NinjaCart",
          "pixels → systems → emotion → play",
        ]
      ),
      "experience": TextContent(
        id: "experience",
        title: "experience",
        body: "i’ve worked across edtech and fintech to build tools that solve real problems.",
        bullets: [
          "Airtribe (Sep 2024 - present)",
          "Newton School (May 2024 - Aug 2024)",
          "Ninjacart (Jan 2024 - May 2024)",
          "Cognizant (Nov 2020 - March 2024)",
        ]
      ),
      "philosophy": TextContent(
        id: "philosophy",
        title: "philosophy",
        body:
          "design isn’t just about pixels. it’s about understanding how people think.\n\nthis intersection of systems, behavior, and design is where my process lives—making products that feel simple, human, and delightful.",
        bullets: nil
      ),
      "about-experiments": TextContent(
        id: "about-experiments",
        title: "playground",
        body:
          "INITIALIZING... ID: AN0THER DE3IGNER\n\na collection of interactive experiments. creative coding, swiftUI, and interactions exploring the edges of what's possible.",
        bullets: nil
      ),
      "resume": TextContent(
        id: "resume",
        title: "resume",
        body:
          "product designer. artist. human.\n\ndownload the full version: anuraaagg.framer.website/resume",
        bullets: nil
      ),
    ]
    return content[id]
  }

  func getProjectContent(id: String) -> ProjectContent? {
    let content: [String: ProjectContent] = [
      "ninjacart": ProjectContent(
        id: "ninjacart",
        title: "Ninja Trade Card",
        overview:
          "Redesigned the repayment experience at NinjaCart to make fintech more calm and predictable.",
        outcome: [
          "Fintech, Payments, Mobile UX",
          "2024 Project",
        ]
      ),
      "airtribe-sales": ProjectContent(
        id: "airtribe-sales",
        title: "Sales opportunity system",
        overview:
          "B2B CRM and dashboard design for Airtribe to streamline tracking and follow-ups.",
        outcome: [
          "B2B, CRM, Dashboard Design",
          "2024 - Current",
        ]
      ),
      "summarify": ProjectContent(
        id: "summarify",
        title: "Summarify.me",
        overview:
          "A lightweight tool to turn long content into clear summaries using AI.",
        outcome: [
          "AI Tools, Web App, UX design",
          "Personal Project",
        ]
      ),
      "loops": ProjectContent(
        id: "loops",
        title: "Loops",
        overview:
          "A music website exploring interaction and creative coding in Framer.",
        outcome: [
          "Interaction, Creative Coding",
          "Experimental Site",
        ]
      ),
      "taxes": ProjectContent(
        id: "taxes",
        title: "Taxes iOS App",
        overview:
          "Building an iOS app with AI to handle personal finance and taxes.",
        outcome: [
          "Fintech, Personal Finance",
          "SwiftUI + AI Exploration",
        ]
      ),
    ]
    return content[id]
  }

  func getExperimentContent(id: String) -> ExperimentContent? {
    let content: [String: ExperimentContent] = [
      "shuffle": ExperimentContent(
        id: "shuffle",
        title: "Shuffle",
        description: "A random experiment.\nMostly unfinished.\nAlways learning."
      ),
      "podbreaker": ExperimentContent(
        id: "podbreaker",
        title: "PodBreaker",
        description: "Brick Breaker game.\nControlled by Click Wheel."
      ),
      "coverflow": ExperimentContent(
        id: "coverflow",
        title: "Cover Flow",
        description: "3D Perspective Gallery."
      ),
    ]
    return content[id]
  }

  func getWritingContent(id: String) -> WritingContent? {
    let content: [String: WritingContent] = [
      "designing-for-feeling": WritingContent(
        id: "designing-for-feeling",
        title: "Designing for Feeling",
        body:
          "Design isn't just about how things look or function. It's about how they feel. The weight of an interaction, the resistance of a gesture, the calm of a system.\n\nWhen we design for feeling, we're designing for the human experience. We're creating moments that resonate, systems that feel natural, interactions that make sense.\n\nThis is the difference between decoration and design. Between features and systems. Between function and feeling.",
        estimatedReadingTime: 3
      ),
      "play-as-process": WritingContent(
        id: "play-as-process",
        title: "Play as a Process",
        body:
          "Play isn't the opposite of work. It's a way of working.\n\nWhen we play, we explore. We experiment. We learn by making. We're free to fail, free to try, free to discover.\n\nThis is how innovation happens. Not through rigid processes or fixed plans, but through curiosity, experimentation, and the willingness to see what happens.\n\nPlay is a process. A way of thinking. A path to discovery.",
        estimatedReadingTime: 2
      ),
      "systems-over-screens": WritingContent(
        id: "systems-over-screens",
        title: "Systems Over Screens",
        body:
          "We don't design screens. We design systems.\n\nA screen is a moment. A system is a way of thinking. A screen solves a problem. A system creates possibilities.\n\nWhen we think in systems, we think about relationships. About how things connect. About how interactions flow. About how the whole is greater than the sum of its parts.\n\nThis is the difference between designing features and designing experiences. Between building products and building platforms. Between screens and systems.",
        estimatedReadingTime: 4
      ),
    ]
    return content[id]
  }
}
