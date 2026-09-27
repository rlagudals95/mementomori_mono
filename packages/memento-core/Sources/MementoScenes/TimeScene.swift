import SwiftUI
import MementoCore

public enum TimeScene: String, CaseIterable, Identifiable {
    case hourglass, record, book, tree, game
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .hourglass: return "모래시계"
        case .record: return "음악 · 레코드"
        case .book: return "독서 · 인생의 책"
        case .tree: return "자연 · 나이테"
        case .game: return "게임 · 한 번의 생명"
        }
    }
    public var message: String {
        switch self {
        case .hourglass: return "흘러간 시간은 돌아오지 않습니다."
        case .record: return "당신의 삶은 한 번만 재생됩니다."
        case .book: return "오늘의 페이지는 아직 쓰는 중입니다."
        case .tree: return "살아낸 시간은 당신 안에 남습니다."
        case .game: return "이 생명에는 다시 시작이 없습니다."
        }
    }
    public var action: String {
        switch self {
        case .hourglass: return "틀 뒤집기"
        case .record: return "레코드 멈춤 / 재생"
        case .book: return "책갈피 꽂기 / 빼기"
        case .tree: return "나이테 확대 / 축소"
        case .game: return "점프"
        }
    }
}

// Native vector artwork. All scenes share the same real lifetime ratio.
public struct TimeSceneView: View {
    let scene: TimeScene
    let progress: Double
    let years: Double
    let ink: Color
    let background: Color
    let motionEnabled: Bool
    public init(scene: TimeScene, progress: Double, years: Double, ink: Color, background: Color, motionEnabled: Bool) {
        self.scene = scene; self.progress = min(1, max(0, progress)); self.years = min(120, max(1, years))
        self.ink = ink; self.background = background; self.motionEnabled = motionEnabled
    }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var alternate = false
    @State private var jumpStarted = Date.distantPast
    @State private var flipStarted = Date.distantPast
    @State private var platterAngle = 0.0
    @State private var platterStarted = Date()
    private var animated: Bool { motionEnabled && !reduceMotion }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animated)) { timeline in
            Canvas { context, size in
                draw(context: &context, size: size, date: timeline.date)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { interact() }
        .accessibilityLabel(scene.title)
        .accessibilityAction(named: Text(scene.action)) { interact() }
        .help(scene == .hourglass ? "뒤집히는 것은 틀뿐입니다. 시간은 계속 흐릅니다." : scene.action)
        .onChange(of: scene) { _ in alternate = false; platterAngle = 0; platterStarted = .now; jumpStarted = .distantPast }
        .onChange(of: animated) { _ in platterStarted = .now }
    }
    private func draw(context: inout GraphicsContext, size: CGSize, date: Date) {
        let time = animated ? date.timeIntervalSince1970 : 0
                let scale = min(size.width / 440, size.height / 340)
                context.translateBy(x: (size.width - 440 * scale) / 2, y: (size.height - 340 * scale) / 2)
                context.scaleBy(x: scale, y: scale)
                context.translateBy(x: -180, y: 0)
                func line(_ points: [CGPoint], opacity: Double = 1, width: CGFloat = 1.8) {
                    guard let first = points.first else { return }
                    var path = Path(); path.move(to: first)
                    for point in points.dropFirst() { path.addLine(to: point) }
                    context.stroke(path, with: .color(ink.opacity(opacity)), lineWidth: width)
                }
                func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, opacity: Double = 1) {
                    context.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(ink.opacity(opacity)))
                }
                func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, opacity: Double = 1, fill: Bool = false) {
                    let path = Path(ellipseIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2))
                    if fill { context.fill(path, with: .color(ink.opacity(opacity))) }
                    else { context.stroke(path, with: .color(ink.opacity(opacity)), lineWidth: 1.2) }
                }
                func text(_ value: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat = 14, opacity: Double = 1) {
                    context.draw(Text(value).font(moriFont(size)).foregroundColor(ink.opacity(opacity)), at: CGPoint(x: x, y: y))
                }
                let remaining = 1 - progress
                switch scene {
                case .hourglass:
                    var frame = context
                    let flipElapsed = max(0, date.timeIntervalSince(flipStarted))
                    let fraction = animated ? min(1, flipElapsed / 0.45) : 1
                    let eased = fraction * fraction * (3 - 2 * fraction)
                    let angle = alternate ? 180 * eased : 180 * (1 - eased)
                    frame.translateBy(x: 400, y: 182); frame.rotate(by: .degrees(angle)); frame.translateBy(x: -400, y: -182)
                    var glass = Path(); glass.move(to: CGPoint(x: 325, y: 60)); glass.addLine(to: CGPoint(x: 475, y: 60))
                    glass.addCurve(to: CGPoint(x: 400, y: 184), control1: CGPoint(x: 475, y: 142), control2: CGPoint(x: 400, y: 153))
                    glass.addCurve(to: CGPoint(x: 475, y: 305), control1: CGPoint(x: 400, y: 210), control2: CGPoint(x: 475, y: 231))
                    glass.addLine(to: CGPoint(x: 325, y: 305))
                    glass.addCurve(to: CGPoint(x: 400, y: 184), control1: CGPoint(x: 325, y: 231), control2: CGPoint(x: 400, y: 210))
                    glass.addCurve(to: CGPoint(x: 325, y: 60), control1: CGPoint(x: 400, y: 153), control2: CGPoint(x: 325, y: 142))
                    frame.stroke(glass, with: .color(ink.opacity(0.6)), lineWidth: 1.8)
                    for y: CGFloat in [43, 49, 315, 321] { var p = Path(); p.move(to: CGPoint(x: 311, y: y)); p.addLine(to: CGPoint(x: 489, y: y)); frame.stroke(p, with: .color(ink), lineWidth: 2) }
                    line([CGPoint(x:315,y:59),CGPoint(x:315,y:305)],opacity:0.3)
                    line([CGPoint(x:485,y:59),CGPoint(x:485,y:305)],opacity:0.3)
                    let h = 115 * sqrt(remaining), b = 95 * sqrt(progress)
                    var sand = Path(); sand.move(to: CGPoint(x:400-h*0.65,y:185-h)); sand.addLine(to: CGPoint(x:400+h*0.65,y:185-h)); sand.addLine(to: CGPoint(x:400,y:185)); sand.closeSubpath()
                    context.fill(sand, with: .color(ink.opacity(0.85)))
                    var mound = Path(); mound.move(to: CGPoint(x:327,y:304)); mound.addQuadCurve(to: CGPoint(x:400,y:304-b), control: CGPoint(x:355,y:298)); mound.addQuadCurve(to: CGPoint(x:473,y:304), control: CGPoint(x:445,y:298)); mound.closeSubpath(); context.fill(mound, with: .color(ink.opacity(0.5)))
                    if remaining > 0 { circle(400, 190 + pow(time.truncatingRemainder(dividingBy: 1),1.6) * max(0,110-b), 2, fill:true) }
                case .record:
                    circle(365,175,145)
                    let needle = 52 + remaining * 86
                    for i in 0..<18 { let r = CGFloat(55+i*5); circle(365,175,r,opacity: r > needle ? 0.18 : 0.55) }
                    var platter = context; platter.translateBy(x:365,y:175)
                    let angle = platterAngle + (animated && !alternate ? date.timeIntervalSince(platterStarted)*24 : 0)
                    platter.rotate(by:.degrees(angle)); platter.fill(Path(ellipseIn:CGRect(x:-49,y:-49,width:98,height:98)),with:.color(ink.opacity(0.12)))
                    platter.draw(Text("THIS LIFE").font(moriFont(12,weight:.bold)).foregroundColor(ink),at:CGPoint(x:0,y:-15))
                    platter.draw(Text("SIDE A / ONCE").font(moriFont(8)).foregroundColor(ink),at:CGPoint(x:0,y:17))
                    circle(365,175,3,fill:true)
                    circle(571,67,20,opacity:0.6); circle(571,67,12,opacity:0.3)
                    let contact = CGPoint(x:365+cos(-0.6)*needle,y:175+sin(-0.6)*needle)
                    line([CGPoint(x:571,y:67),CGPoint(x:548,y:101),contact],width:5)
                    rect(contact.x-4,contact.y-3,16,9)
                case .book:
                    var pages = Path(); pages.move(to:CGPoint(x:235,y:80)); pages.addQuadCurve(to:CGPoint(x:400,y:93),control:CGPoint(x:318,y:67)); pages.addQuadCurve(to:CGPoint(x:565,y:80),control:CGPoint(x:482,y:67)); pages.addLine(to:CGPoint(x:565,y:266)); pages.addQuadCurve(to:CGPoint(x:400,y:276),control:CGPoint(x:482,y:254)); pages.addQuadCurve(to:CGPoint(x:235,y:266),control:CGPoint(x:318,y:254)); pages.closeSubpath(); context.stroke(pages,with:.color(ink),lineWidth:2)
                    line([CGPoint(x:400,y:93),CGPoint(x:400,y:276)],opacity:0.4)
                    line([CGPoint(x:226,y:87),CGPoint(x:226,y:276),CGPoint(x:400,y:287),CGPoint(x:574,y:276),CGPoint(x:574,y:87)],opacity:0.3)
                    text("살아낸 이야기",317,113,14,opacity:0.5)
                    for i in 0..<7 { line([CGPoint(x:255,y:145+i*15),CGPoint(x:365-(i%3)*12,y:145+i*15)],opacity:0.2) }
                    text("제\(min(Int(ceil(years)),Int(progress*years)+1))장",480,149,34)
                    text("이 페이지는 아직",480,196,14); text("쓰는 중입니다.",480,219,14)
                    rect(447,240,2,12,opacity: animated ? 0.6+0.3*sin(time*2) : 0.8)
                    if alternate { rect(521,77,14,51,opacity:0.65) }
                case .tree:
                    let count = max(1,Int(ceil(years)))
                    let zoom: CGFloat = alternate ? 1.1 : 1
                    for i in 1...count {
                        let radius = (12+CGFloat(i)/CGFloat(count)*122)*zoom
                        var ring = Path()
                        for step in 0...96 {
                            let a = Double(step)*Double.pi*2/96
                            let r = radius * (1+0.035*sin(3*a+0.5)+0.022*sin(7*a)+0.015*sin(11*a+0.3))
                            let p = CGPoint(x:400+cos(a)*r,y:175+sin(a)*r)
                            if step == 0 { ring.move(to:p) } else { ring.addLine(to:p) }
                        }
                        context.stroke(ring,with:.color(ink.opacity(Double(i) <= progress*years ? 0.55 : 0.12)),lineWidth:0.8)
                    }
                    circle(400+(12+progress*122)*zoom,175,3,opacity:animated ? 0.65+0.3*sin(time*2) : 1,fill:true)
                    context.fill(Path(ellipseIn:CGRect(x:366,y:148,width:68,height:54)),with:.color(background))
                    text(String(format:"%.1f",progress*years),400,167,24); text("살아온 해",400,191,10,opacity:0.6)
                case .game:
                    text("ONE LIFE",400,57,14)
                    for (row, columns) in [[1,2,5,6],[0,1,2,3,4,5,6,7],[0,1,2,3,4,5,6,7],[1,2,3,4,5,6],[2,3,4,5],[3,4]].enumerated() {
                        for column in columns { rect(CGFloat(184+column*3),CGFloat(95+row*3),3,3) }
                    }
                    for i in 0..<24 { rect(CGFloat(220+i*15),101,11,18,opacity: Double(i)/24 < remaining ? 0.9 : 0.12) }
                    line([CGPoint(x:210,y:91),CGPoint(x:590,y:91),CGPoint(x:590,y:129),CGPoint(x:210,y:129),CGPoint(x:210,y:91)],opacity:0.5)
                    let elapsed = date.timeIntervalSince(jumpStarted)
                    let jump = animated && elapsed >= 0 && elapsed < 0.44 ? sin(elapsed/0.44 * .pi)*28 : 0
                    let x = 218+progress*370, y = 270-jump
                    rect(x,y-30,12,12); rect(x-4,y-16,20,10)
                    let stride: CGFloat = animated && Int(time*2)%2 == 0 ? 5 : 0
                    rect(x-2-stride,y-6,6,6); rect(x+8+stride,y-6,6,6)
                    line([CGPoint(x:209,y:275),CGPoint(x:610,y:275)],opacity:0.5)
                    line([CGPoint(x:596,y:272),CGPoint(x:596,y:240),CGPoint(x:615,y:240),CGPoint(x:615,y:272)],opacity:0.6)
                    text("NO RESTART",400,307,10,opacity:0.5)
                }

    }
    private func interact() {
        if scene == .record {
            if animated && !alternate { platterAngle += Date().timeIntervalSince(platterStarted)*24 }
            platterStarted = .now
        }
        if scene == .hourglass { flipStarted = .now }
        if scene == .game { jumpStarted = .now } else { alternate.toggle() }
    }
}

private func moriFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    let face = weight == .bold ? "Bold" : "Regular"
    return .custom("PretendardVariable-\(face)", size: size)
}
