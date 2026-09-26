import SwiftUI
import MementoCore

struct WidgetGuide: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("자주 보는 곳에,\n유한한 시간을.").font(Design.font(32, weight: .bold)).tracking(-1)
                    let profile = store.settings.state.profile
                    let now = Date()
                    WidgetFace(snapshot: profile.flatMap { try? Life.snapshot($0, now: now) }, date: now, timerStart: now)
                        .frame(height: 170).background(Design.ink)
                    Text("홈 화면").font(Design.font(20, weight: .bold))
                    Text("홈 화면의 빈 곳을 길게 누르세요. 편집 → 위젯 추가에서 ‘메멘토모리’를 찾아 작은 크기 또는 중간 크기로 추가하세요.")
                    Text("잠금화면").font(Design.font(20, weight: .bold))
                    Text("잠금화면을 길게 누르고 사용자화 → 잠금화면 → 시계 아래 위젯 영역을 누르세요. ‘메멘토모리’를 선택하세요.")
                    Divider()
                    Text("앱에서 한 번, 모든 위젯에").font(Design.font(18, weight: .bold))
                    Text("앱에서 저장한 생년월일과 기준 나이가 위젯에 자동으로 적용됩니다. 기존 위젯도 앱을 한 번 열면 나의 시간을 읽습니다.")
                    if let profile {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("생년월일  \(profile.birthday)")
                                Text("기준 나이  \(profile.years.formatted())세")
                            }.font(Design.font(13, weight: .bold))
                            Spacer()
                            Button("날짜 복사") { UIPasteboard.general.string = profile.birthday }
                                .font(Design.font(11, weight: .bold)).frame(minHeight: 44)
                        }.padding(16).overlay { Rectangle().stroke(Design.ink.opacity(0.2)) }
                    }
                    Text("나의 시간은 앱의 초·일 선택에 따라 표시됩니다. 위젯을 길게 눌러 ‘위젯 편집’에서 배경을 바꿀 수 있습니다. 다른 생년월일을 입력하면 그 위젯만 별도 시간을 표시합니다. 앱 설정을 다시 사용하려면 위젯의 생년월일을 비우세요.")
                    Text("‘흐르는 시간’은 시간:분:초로 표시됩니다. 표시 갱신은 iOS가 관리하며, 화면 꺼짐·저전력 모드에서는 매초 움직이지 않을 수 있습니다.")
                        .font(Design.font(12)).foregroundStyle(.secondary)
                    Text("숫자는 설정한 나이를 기준으로 한 가늠자입니다. 개인의 수명 예측이 아닙니다.")
                        .font(Design.font(11)).foregroundStyle(.secondary)
                }.font(Design.font(14)).lineSpacing(4).padding(24).frame(maxWidth: 620)
            }.background(Design.paper).navigationTitle("위젯 추가하기").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } } }
        }.tint(Design.ink)
    }
}
