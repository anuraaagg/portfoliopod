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

  init(
    id: String, title: String, children: [MenuNode]? = nil, contentType: ContentType,
    payloadID: String? = nil, imageName: String? = nil
  ) {
    self.id = id
    self.title = title
    self.children = children
    self.contentType = contentType
    self.payloadID = payloadID
    self.imageName = imageName
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

  init() {
    self.rootMenu = ContentStore.createDefaultContent()
  }

  static func createDefaultContent() -> MenuNode {
    return MenuNode(
      id: "root",
      title: "Main Menu",
      children: [
        MenuNode(
          id: "nowplaying-root",
          title: "Now Playing",
          contentType: .text,  // Will be intercepted by contains("nowplaying")
          payloadID: "now-playing"
        ),
        MenuNode(
          id: "music",
          title: "Music",
          children: [
            MenuNode(
              id: "on-repeat", title: "On Repeat", contentType: .text, payloadID: "on-repeat"),
            MenuNode(
              id: "artists", title: "Artists I Love", contentType: .text, payloadID: "artists"),
            MenuNode(
              id: "playlists", title: "Playlists", contentType: .text, payloadID: "playlists"),
          ],
          contentType: .menu
        ),
        MenuNode(
          id: "hobby",
          title: "Hobby",
          children: [
            MenuNode(
              id: "ninjacart", title: "NinjaCart Repayment", contentType: .project,
              payloadID: "ninjacart"),
            MenuNode(
              id: "crm", title: "CRM – Sales System", contentType: .project,
              payloadID: "crm"),
            MenuNode(
              id: "summarify", title: "Summarify", contentType: .project, payloadID: "summarify"
            ),
          ],
          contentType: .menu,
          imageName: "preview_hobby"
        ),
        MenuNode(
          id: "about",
          title: "About Me",
          children: [
            MenuNode(id: "who-am-i", title: "Who Am I?", contentType: .text, payloadID: "who-am-i"),
            MenuNode(
              id: "what-i-do", title: "What I Do", contentType: .text, payloadID: "what-i-do"),
            MenuNode(
              id: "how-i-work", title: "How I Work", contentType: .text, payloadID: "how-i-work"),
            MenuNode(
              id: "on-the-side", title: "On The Side", contentType: .text, payloadID: "on-the-side"),
            MenuNode(
              id: "people-i-admire", title: "People I Admire", contentType: .text,
              payloadID: "people-i-admire"),
          ],
          contentType: .menu,
          imageName: "preview_about"
        ),
        MenuNode(
          id: "experiments",
          title: "Experiments",
          children: [
            MenuNode(
              id: "about-experiments", title: "What Lives Here?", contentType: .text,
              payloadID: "about-experiments"),
            MenuNode(
              id: "coverflow", title: "Cover Flow", contentType: .experiment, payloadID: "coverflow"
            ),
          ],
          contentType: .menu,
          imageName: "preview_experiments"
        ),
        MenuNode(
          id: "social",
          title: "Social",
          children: [
            MenuNode(id: "twitter", title: "Twitter", contentType: .text, payloadID: "twitter"),
            MenuNode(id: "linkedin", title: "LinkedIn", contentType: .text, payloadID: "linkedin"),
          ],
          contentType: .menu,
          imageName: "preview_social"
        ),
        MenuNode(
          id: "writings",
          title: "Writings",
          children: [
            MenuNode(
              id: "about-writing", title: "About Writing", contentType: .text,
              payloadID: "about-writing"),
            MenuNode(
              id: "design-systems", title: "On Design Systems", contentType: .writing,
              payloadID: "design-systems"),
            MenuNode(
              id: "interaction", title: "Micro-Interactions", contentType: .writing,
              payloadID: "interaction"),
          ],
          contentType: .menu,
          imageName: "preview_writings"
        ),
        MenuNode(
          id: "settings",
          title: "Settings",
          children: [
            MenuNode(
              id: "about-device", title: "About Device", contentType: .text,
              payloadID: "about-device"),
            MenuNode(id: "resume", title: "Resume", contentType: .text, payloadID: "resume"),
            MenuNode(id: "contact", title: "Contact", contentType: .text, payloadID: "contact"),
            MenuNode(id: "preferences", title: "Preferences", contentType: .menu),
          ],
          contentType: .menu
        ),
      ],
      contentType: .menu
    )
  }

  func getTextContent(id: String) -> TextContent? {
    let content: [String: TextContent] = [
      // ===== MUSIC =====
      "on-repeat": TextContent(
        id: "on-repeat",
        title: "On Repeat",
        body:
          "This section is visual-first.\nMinimal text. Motion, sound, and interaction respond to music.\n\nAlways in motion.",
        bullets: nil
      ),
      "artists": TextContent(
        id: "artists",
        title: "Artists I Love",
        body: "Artists I keep coming back to:",
        bullets: [
          "Radiohead",
          "Frank Ocean",
          "Aphex Twin",
          "Four Tet",
          "Nils Frahm",
          "Burial",
        ]
      ),
      "playlists": TextContent(
        id: "playlists",
        title: "Playlists",
        body: "",
        bullets: [
          "late night walks",
          "coding but make it emotional",
          "slow mornings",
          "things i'd play live",
        ]
      ),
      // ===== ABOUT =====
      "who-am-i": TextContent(
        id: "who-am-i",
        title: "Who Am I?",
        body:
          "I'm Anurag.\n\nI ask questions, explore ideas, and tinker with systems.\n\nHow can technology feel a little more human?",
        bullets: nil
      ),
      "what-i-do": TextContent(
        id: "what-i-do",
        title: "What I Do",
        body:
          "Currently at Airtribe.\n\nHow can edtech tools better support growth?\n\nI work across learning, sales, and AI.",
        bullets: nil
      ),
      "how-i-work": TextContent(
        id: "how-i-work",
        title: "How I Work",
        body:
          "Through product design, systems thinking, and close collaboration.\n\nWhat happens when teams align around real user problems?",
        bullets: nil
      ),
      "on-the-side": TextContent(
        id: "on-the-side",
        title: "On The Side",
        body:
          "Code, AI, and prototyping.\n\nHow can small experiments quietly improve my design practice?",
        bullets: [
          "Creative coding",
          "DJing",
          "Photography",
          "Dancing",
        ]
      ),
      "people-i-admire": TextContent(
        id: "people-i-admire",
        title: "People I Admire",
        body: "",
        bullets: [
          "Dieter Rams — clarity and restraint",
          "Jamie Hewlett — expressive, playful worlds",
          "Brian Eno — systems, chance, and art",
        ]
      ),
      // ===== EXPERIMENTS =====
      "about-experiments": TextContent(
        id: "about-experiments",
        title: "What Lives Here?",
        body:
          "Interactive sketches, creative coding, AI explorations, half-finished ideas.\n\nWhat happens when curiosity leads instead of requirements?\n\nNew tools, interactions, and workflows.\n\nHow fast can an idea move from thought to prototype?",
        bullets: nil
      ),
      // ===== WRITING =====
      "about-writing": TextContent(
        id: "about-writing",
        title: "About Writing",
        body:
          "How do I think when I slow down?\n\nShort reflections on design, systems, interaction, and feeling.\n\nNot tutorials. Not hot takes.",
        bullets: nil
      ),
      // ===== SETTINGS / CONTACT =====
      "about-device": TextContent(
        id: "about-device",
        title: "About Device",
        body: "Name: Anurag\nModel: iPod\nOS: PortfolioOS\n\nI design systems that feel human.",
        bullets: nil
      ),
      "now-playing": TextContent(
        id: "now-playing",
        title: "Now Playing",
        body:
          "Exploring ideas quietly.\nDesigning slowly.\n\n(Actual song metadata would appear here via MusicKit.)",
        bullets: nil
      ),
      "contact": TextContent(
        id: "contact",
        title: "Contact",
        body:
          "Let's connect.\n\nEmail: hello@anuraaagg.com\nTwitter: @anuraaagg\nLinkedIn: linkedin.com/in/anuraaagg\nGitHub: github.com/anuraaagg\nWebsite: anuraaagg.framer.website",
        bullets: nil
      ),
      "resume": TextContent(
        id: "resume",
        title: "Resume",
        body:
          "Product Designer\n\nCurrently at Airtribe.\nPreviously: NinjaCart.\n\nI design systems that feel human.",
        bullets: nil
      ),
    ]
    return content[id]
  }

  func getProjectContent(id: String) -> ProjectContent? {
    let content: [String: ProjectContent] = [
      "ninjacart": ProjectContent(
        id: "ninjacart",
        title: "NinjaCart Repayment",
        overview:
          "Redesigned the repayment experience to make payments clearer, calmer, and more predictable.\n\nUsers struggled to understand repayment amounts, timelines, and required actions. I redesigned the end-to-end repayment flow to improve clarity and reduce errors.",
        outcome: [
          "Reduced support tickets by ~35%",
          "Improved completion by ~22%",
          "Reduced drop-offs by ~18%",
        ]
      ),
      "crm": ProjectContent(
        id: "crm",
        title: "CRM – Sales System",
        overview:
          "Built a role-based CRM to help sales teams act faster and managers track performance clearly.\n\nSales teams lacked visibility into lead quality, follow-ups, and performance. I designed a system focused on prioritisation, clear actions, and real-time monitoring.",
        outcome: [
          "Reduced follow-up time by ~30%",
          "Improved tracking accuracy by ~40%",
          "Contributed to 2× sales revenue",
        ]
      ),
      "summarify": ProjectContent(
        id: "summarify",
        title: "Summarify",
        overview:
          "A lightweight tool to turn long content into clear summaries.\n\nPeople often avoid long content due to time constraints. Summarify helps users quickly grasp key information.",
        outcome: [
          "Reduced reading time by ~60%",
          "Improved recall by ~25%",
          "Enabled faster consumption",
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
