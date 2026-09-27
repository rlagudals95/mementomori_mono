import SwiftUI
import UniformTypeIdentifiers
import MementoCore
import MementoScenes

struct SettingsView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var birthday = ""
    @State private var years = "83.7"
    @State private var thought = ""
    @State private var error: String?
    @State private var importing = false
    @State private var exporting = false
    @State private var pending: SettingsFile?
    @State private var confirmImport = false
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("나의 시간을\n기억하기 위해.").font(Design.font(32, weight: .bold)).tracking(-1)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("생년월일").font(Design.font(12, weight: .bold))
                        TextField("YYYY-MM-DD", text: $birthday).keyboardType(.numbersAndPunctuation)
                            .textContentType(.birthdate).accessibilityIdentifier("birthday")
                            .padding(14).overlay { Rectangle().stroke(Design.ink.opacity(0.3), lineWidth: 1) }
                        Text("예: 1995-01-01").font(Design.font(11)).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("시간의 가늠자 · 기준 나이").font(Design.font(12, weight: .bold))
                        HStack {
                            TextField("83.7", text: $years).keyboardType(.decimalPad).accessibilityIdentifier("years")
                            Text("세").foregroundStyle(.secondary)
                        }.padding(14).overlay { Rectangle().stroke(Design.ink.opacity(0.3), lineWidth: 1) }
                        Text("기본값 83.7세는 대한민국 2024년 출생 시 기대수명입니다. 현재 나이의 기대여명이나 개인의 사망 시점을 뜻하지 않습니다.")
                            .font(Design.font(11)).foregroundStyle(.secondary).lineSpacing(4)
                        Link("통계청 자료 보기 ↗", destination: URL(string: "https://www.kostat.go.kr/boardDownload.es?bid=208&list_no=439533&seq=1")!)
                            .font(Design.font(11))
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("오늘, 기억할 한 문장").font(Design.font(12, weight: .bold))
                        TextField("이 1초는 돌아오지 않습니다.", text: $thought, axis: .vertical)
                            .lineLimit(2...4).padding(14).accessibilityIdentifier("thought")
                            .overlay { Rectangle().stroke(Design.ink.opacity(0.3), lineWidth: 1) }
                        Text("오늘만 표시됩니다. 최대 100자.").font(Design.font(11)).foregroundStyle(.secondary)
                    }
                    if let error { Text(error).font(Design.font(12, weight: .bold)).accessibilityIdentifier("validation-error") }
                    Button("나의 시간 저장하기", action: save).buttonStyle(PrimaryButton()).accessibilityIdentifier("save-profile")
                    Divider()
                    Text("시간을 바라보는 방식").font(Design.font(16, weight: .bold))
                    Picker("시간 테마", selection: $store.scene) {
                        ForEach(TimeScene.allCases) { Text($0.title).tag($0) }
                    }.accessibilityIdentifier("settings-scene-picker")
                    Text(store.scene.message).font(Design.font(13))
                    Text("앱의 그림을 터치하면 \(store.scene.action). 홈 화면 위젯에도 선택한 그림이 표시됩니다.")
                        .font(Design.font(12)).foregroundStyle(.secondary)
                    Toggle("모션 켜기", isOn: $store.motionEnabled)
                    Text("동작 줄이기 설정을 따릅니다. 위젯의 그림은 정지 화면이며 초 카운트는 계속 흐릅니다.")
                        .font(Design.font(11)).foregroundStyle(.secondary)
                    Divider()
                    Text("설정 파일로 이어보기").font(Design.font(16, weight: .bold))
                    Text("웹·Mac에서 내보낸 JSON을 가져오거나, 이 iPhone의 설정을 파일로 보관하세요.")
                        .font(Design.font(12)).foregroundStyle(.secondary)
                    HStack(spacing: 24) {
                        Button("가져오기") { importing = true }
                        Button("내보내기") { exporting = true }
                    }.font(Design.font(13, weight: .bold))
                    Text("생년월일과 문장은 이 기기에만 저장됩니다. 자동 동기화하지 않습니다.")
                        .font(Design.font(11)).foregroundStyle(.secondary)
                    Button("이 iPhone의 기록 지우기") { confirmReset = true }.font(Design.font(11)).padding(.top, 12)
                }.padding(24).frame(maxWidth: 620)
            }.scrollDismissesKeyboard(.interactively).background(Design.paper).navigationTitle("나의 시간 설정").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } } }
                .onAppear(perform: load)
                .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                    do {
                        let url = try result.get()
                        let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
                        if let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 65536 {
                            throw LifeError.invalid("설정 파일은 64KB 이하여야 합니다.")
                        }
                        pending = try SettingsFile.decode(Data(contentsOf: url)); confirmImport = true
                    } catch { self.error = error.localizedDescription }
                }
                .fileExporter(isPresented: $exporting, document: SettingsDocument(settings: store.settings), contentType: .json, defaultFilename: "mementomori-settings") { result in
                    if case .failure(let failure) = result { error = failure.localizedDescription }
                }
                .alert("가져온 설정으로 바꿀까요?", isPresented: $confirmImport) {
                    Button("취소", role: .cancel) { pending = nil }
                    Button("바꾸기") {
                        do { if let pending { try store.save(pending); load() }; pending = nil }
                        catch { self.error = error.localizedDescription }
                    }
                } message: { Text("현재 생년월일과 문장이 바뀝니다. 위젯 설정은 위젯에서 따로 변경해 주세요.") }
                .alert("이 iPhone의 기록을 지울까요?", isPresented: $confirmReset) {
                    Button("취소", role: .cancel) { }
                    Button("지우기", role: .destructive) { store.reset(); dismiss() }
                } message: { Text("앱의 설정만 지웁니다. 홈·잠금화면에 추가한 위젯은 별도로 삭제해 주세요.") }
        }.font(Design.font(15)).tint(Design.ink)
    }
    private func load() {
        birthday = store.settings.state.profile?.birthday ?? ""
        years = String(store.settings.state.profile?.years ?? 83.7)
        thought = store.settings.state.intention.flatMap { $0.date == Life.dayKey() ? $0.text : nil } ?? ""
        error = nil
    }
    private func save() {
        do {
            guard let value = Double(years.replacingOccurrences(of: ",", with: ".")) else { throw LifeError.invalid("기준 나이는 숫자로 입력해 주세요.") }
            let profile = Profile(birthday: birthday.trimmingCharacters(in: .whitespacesAndNewlines), years: value)
            try Life.validate(profile)
            var settings = store.settings; settings.state.profile = profile
            let text = thought.trimmingCharacters(in: .whitespacesAndNewlines)
            settings.state.intention = text.isEmpty ? nil : Intention(text: text, date: Life.dayKey())
            try store.save(settings); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
