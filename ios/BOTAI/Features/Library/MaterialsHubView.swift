import SwiftUI

struct MaterialsHubView: View {
    @Environment(MaterialStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var addMaterial = false

    var body: some View {
        NavigationStack {
            ZStack {
                DigitalHubBackground()
                ScrollView { VStack(spacing: 16) { sourceGrid; myMaterials }.padding(16) }
            }
            .navigationTitle("Мои материалы").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
            .sheet(isPresented: $addMaterial) { AddMaterialView() }
        }
    }

    private var sourceGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ДОБАВИТЬ МАТЕРИАЛ").font(.caption.bold()).foregroundStyle(.cyan)
            HStack { source("ОТКРЫТЬ", "Готовый пакет BOTAI", "shippingbox.fill", false); source("СОЗДАТЬ", "CSV или таблица", "square.and.pencil", true) }
            HStack { source("КЛАСС", "Подключиться", "person.3.fill", false); source("БИБЛИОТЕКА", "Готовые материалы", "books.vertical.fill", false) }
        }
    }

    private func source(_ title: String, _ subtitle: String, _ icon: String, _ enabled: Bool) -> some View {
        Button { if enabled { addMaterial = true } } label: {
            VStack(alignment: .leading, spacing: 8) { Image(systemName: icon).font(.title2).foregroundStyle(.cyan); Text(title).font(.headline); Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.65)); if !enabled { Text("СКОРО").font(.system(size: 8, weight: .bold)).foregroundStyle(.purple) } }
                .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading).padding(12).background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(enabled ? .cyan.opacity(0.45) : .white.opacity(0.12)))
        }.buttonStyle(.plain).disabled(!enabled)
    }

    private var myMaterials: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text("МОИ МАТЕРИАЛЫ").font(.caption.bold()).foregroundStyle(.cyan); Spacer(); Text("\(store.materials.count)").foregroundStyle(.white.opacity(0.6)) }
            if store.materials.isEmpty { Text("Здесь появятся созданные, импортированные и назначенные материалы.").font(.subheadline).foregroundStyle(.white.opacity(0.62)).padding(.vertical, 20) }
            ForEach(store.materials) { material in
                HStack { Image(systemName: material.kind == .reference ? "tablecells" : "questionmark.bubble").foregroundStyle(.mint); VStack(alignment: .leading) { Text(material.title).font(.headline); Text([material.subject, material.topic].compactMap{$0}.joined(separator: " · ")).font(.caption).foregroundStyle(.white.opacity(0.6)) }; Spacer(); Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.35)) }.padding(12).background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
            }
        }.foregroundStyle(.white)
    }
}

private struct DigitalHubBackground: View { var body: some View { LinearGradient(colors: [Color(red:0.015,green:0.035,blue:0.12), Color(red:0.03,green:0.08,blue:0.18), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea() } }
