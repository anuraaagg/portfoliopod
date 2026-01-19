//
//  ContentModel.swift
//  portfoliopod
//
//  Scalable content architecture
//

import Foundation
import Combine

enum ContentType: String, Codable {
    case text
    case project
    case experiment
    case writing
    case media
    case menu
}

struct MenuNode: Identifiable, Codable {
    let id: String
    let title: String
    var children: [MenuNode]?
    let contentType: ContentType
    let payloadID: String?
    
    init(id: String, title: String, children: [MenuNode]? = nil, contentType: ContentType, payloadID: String? = nil) {
        self.id = id
        self.title = title
        self.children = children
        self.contentType = contentType
        self.payloadID = payloadID
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
    let estimatedReadingTime: Int? // in minutes
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
                    id: "about",
                    title: "About",
                    children: [
                        MenuNode(id: "hello", title: "Hello", contentType: .text, payloadID: "hello"),
                        MenuNode(id: "what-i-do", title: "What I Do", contentType: .text, payloadID: "what-i-do"),
                        MenuNode(id: "how-i-think", title: "How I Think", contentType: .text, payloadID: "how-i-think"),
                        MenuNode(id: "timeline", title: "Timeline", contentType: .menu, payloadID: "timeline", children: [
                            MenuNode(id: "timeline-2025", title: "2025 – Present", contentType: .text, payloadID: "timeline-2025"),
                            MenuNode(id: "timeline-2023", title: "2023 – 2025", contentType: .text, payloadID: "timeline-2023"),
                            MenuNode(id: "timeline-2021", title: "2021 – 2023", contentType: .text, payloadID: "timeline-2021")
                        ])
                    ],
                    contentType: .menu
                ),
                MenuNode(
                    id: "work",
                    title: "Work",
                    children: [
                        MenuNode(
                            id: "selected-work",
                            title: "Selected Work",
                            children: [
                                MenuNode(id: "sales-dashboard", title: "Sales Dashboard", contentType: .project, payloadID: "sales-dashboard"),
                                MenuNode(id: "ai-crm", title: "AI CRM Experiments", contentType: .project, payloadID: "ai-crm"),
                                MenuNode(id: "summarify", title: "Summarify", contentType: .project, payloadID: "summarify")
                            ],
                            contentType: .menu
                        ),
                        MenuNode(id: "impact", title: "Impact", contentType: .text, payloadID: "impact")
                    ],
                    contentType: .menu
                ),
                MenuNode(
                    id: "experiments",
                    title: "Experiments",
                    children: [
                        MenuNode(id: "shuffle", title: "Shuffle", contentType: .experiment, payloadID: "shuffle"),
                        MenuNode(id: "interactive", title: "Interactive", contentType: .menu),
                        MenuNode(id: "visual", title: "Visual", contentType: .menu),
                        MenuNode(id: "systems", title: "Systems", contentType: .menu)
                    ],
                    contentType: .menu
                ),
                MenuNode(
                    id: "writing",
                    title: "Writing",
                    children: [
                        MenuNode(id: "notes", title: "Notes", contentType: .menu),
                        MenuNode(id: "essays", title: "Essays", children: [
                            MenuNode(id: "designing-for-feeling", title: "Designing for Feeling", contentType: .writing, payloadID: "designing-for-feeling"),
                            MenuNode(id: "play-as-process", title: "Play as a Process", contentType: .writing, payloadID: "play-as-process"),
                            MenuNode(id: "systems-over-screens", title: "Systems Over Screens", contentType: .writing, payloadID: "systems-over-screens")
                        ], contentType: .menu),
                        MenuNode(id: "ideas", title: "Ideas", contentType: .menu)
                    ],
                    contentType: .menu
                ),
                MenuNode(
                    id: "music",
                    title: "Music",
                    children: [
                        MenuNode(id: "now-playing", title: "Now Playing", contentType: .text, payloadID: "now-playing"),
                        MenuNode(id: "library", title: "Library", contentType: .menu),
                        MenuNode(id: "playlists", title: "Playlists", contentType: .menu),
                        MenuNode(id: "recently-played", title: "Recently Played", contentType: .menu)
                    ],
                    contentType: .menu
                ),
                MenuNode(
                    id: "settings",
                    title: "Settings",
                    children: [
                        MenuNode(id: "about-device", title: "About Device", contentType: .text, payloadID: "about-device"),
                        MenuNode(id: "resume", title: "Resume", contentType: .text, payloadID: "resume"),
                        MenuNode(id: "contact", title: "Contact", contentType: .text, payloadID: "contact"),
                        MenuNode(id: "preferences", title: "Preferences", contentType: .menu)
                    ],
                    contentType: .menu
                )
            ],
            contentType: .menu
        )
    }
    
    func getTextContent(id: String) -> TextContent? {
        let content: [String: TextContent] = [
            "hello": TextContent(
                id: "hello",
                title: nil,
                body: "designer. artist. human.\n\nI design digital products and systems.\nI like exploring ideas through code, AI, and play.\n\nThis is a small window into how I think.",
                bullets: nil
            ),
            "what-i-do": TextContent(
                id: "what-i-do",
                title: "What I Do",
                body: "",
                bullets: [
                    "Product Design",
                    "Prototyping with Code",
                    "AI-Driven Experiments",
                    "UX Systems & Interaction"
                ]
            ),
            "how-i-think": TextContent(
                id: "how-i-think",
                title: "How I Think",
                body: "",
                bullets: [
                    "Start with intent, not screens",
                    "Systems over features",
                    "Build to feel, not just function",
                    "Learn by making"
                ]
            ),
            "timeline-2025": TextContent(
                id: "timeline-2025",
                title: "2025 – Present",
                body: "Role: Lead Product Designer\nContext: Developing next-gen design systems and interactive environments.",
                bullets: [
                    "Leading the transition to spatial computing interfaces.",
                    "Defining global design tokens for multi-platform products."
                ]
            ),
            "timeline-2023": TextContent(
                id: "timeline-2023",
                title: "2023 – 2025",
                body: "Role: Senior Product Designer\nContext: Scaling AI infrastructure for creative tools.",
                bullets: [
                    "Designed and shipped 10+ AI-driven feature sets.",
                    "Mentored junior designers on system-level thinking."
                ]
            ),
            "timeline-2021": TextContent(
                id: "timeline-2021",
                title: "2021 – 2023",
                body: "Role: Product Designer\nContext: E-commerce and logistics platforms.",
                bullets: [
                    "Reduced operational friction by 40%.",
                    "Implemented the first unified component library."
                ]
            ),
            "about-device": TextContent(
                id: "about-device",
                title: "About Device",
                body: "Name: Anurag\nModel: iPod\nOS: PortfolioOS",
                bullets: nil
            ),
            "impact": TextContent(
                id: "impact",
                title: "Impact",
                body: "Designing systems that help teams move faster and think clearer.",
                bullets: nil
            ),
            "now-playing": TextContent(
                id: "now-playing",
                title: "Now Playing",
                body: "Exploring ideas quietly.\nDesigning slowly.\n\n(Actual song metadata would appear here via MusicKit.)",
                bullets: nil
            ),
            "contact": TextContent(
                id: "contact",
                title: "Contact",
                body: "Let's connect.\n\nEmail: hello@anurag.design\nWebsite: anurag.design",
                bullets: nil
            ),
            "resume": TextContent(
                id: "resume",
                title: "Resume",
                body: "A brief look at my professional journey.",
                bullets: nil
            )
        ]
        return content[id]
    }
    
    func getProjectContent(id: String) -> ProjectContent? {
        let content: [String: ProjectContent] = [
            "sales-dashboard": ProjectContent(
                id: "sales-dashboard",
                title: "Sales Dashboard",
                overview: "Redesigning a sales dashboard to help teams act faster, understand performance clearly, and reduce operational friction.",
                outcome: [
                    "Revenue doubled",
                    "Faster lead follow-ups",
                    "Better monitoring & control"
                ]
            ),
            "ai-crm": ProjectContent(
                id: "ai-crm",
                title: "AI CRM Experiments",
                overview: "Exploring how AI can enhance customer relationship management through intelligent automation and insights.",
                outcome: [
                    "Improved response times",
                    "Better customer insights",
                    "Streamlined workflows"
                ]
            ),
            "summarify": ProjectContent(
                id: "summarify",
                title: "Summarify",
                overview: "A tool for quickly understanding long-form content through intelligent summarization.",
                outcome: [
                    "Faster information processing",
                    "Improved comprehension",
                    "Time saved"
                ]
            )
        ]
        return content[id]
    }
    
    func getExperimentContent(id: String) -> ExperimentContent? {
        let content: [String: ExperimentContent] = [
            "shuffle": ExperimentContent(
                id: "shuffle",
                title: "Shuffle",
                description: "A random experiment.\nMostly unfinished.\nAlways learning."
            )
        ]
        return content[id]
    }
    
    func getWritingContent(id: String) -> WritingContent? {
        let content: [String: WritingContent] = [
            "designing-for-feeling": WritingContent(
                id: "designing-for-feeling",
                title: "Designing for Feeling",
                body: "Design isn't just about how things look or function. It's about how they feel. The weight of an interaction, the resistance of a gesture, the calm of a system.\n\nWhen we design for feeling, we're designing for the human experience. We're creating moments that resonate, systems that feel natural, interactions that make sense.\n\nThis is the difference between decoration and design. Between features and systems. Between function and feeling.",
                estimatedReadingTime: 3
            ),
            "play-as-process": WritingContent(
                id: "play-as-process",
                title: "Play as a Process",
                body: "Play isn't the opposite of work. It's a way of working.\n\nWhen we play, we explore. We experiment. We learn by making. We're free to fail, free to try, free to discover.\n\nThis is how innovation happens. Not through rigid processes or fixed plans, but through curiosity, experimentation, and the willingness to see what happens.\n\nPlay is a process. A way of thinking. A path to discovery.",
                estimatedReadingTime: 2
            ),
            "systems-over-screens": WritingContent(
                id: "systems-over-screens",
                title: "Systems Over Screens",
                body: "We don't design screens. We design systems.\n\nA screen is a moment. A system is a way of thinking. A screen solves a problem. A system creates possibilities.\n\nWhen we think in systems, we think about relationships. About how things connect. About how interactions flow. About how the whole is greater than the sum of its parts.\n\nThis is the difference between designing features and designing experiences. Between building products and building platforms. Between screens and systems.",
                estimatedReadingTime: 4
            )
        ]
        return content[id]
    }
}

