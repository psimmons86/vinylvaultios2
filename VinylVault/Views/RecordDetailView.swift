import SwiftUI

struct RecordDetailView: View {
    @EnvironmentObject var recordStore: RecordStore
    @Environment(\.dismiss) var dismiss
    
    @State private var record: Record
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    @State private var newTag = ""
    
    init(record: Record) {
        _record = State(initialValue: record)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Album Art
                AsyncImage(url: URL(string: record.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 5)
                
                // Title and Artist
                VStack(spacing: 8) {
                    if isEditing {
                        TextField("Title", text: $record.title)
                            .font(.title)
                            .multilineTextAlignment(.center)
                        
                        TextField("Artist", text: $record.artist)
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(record.title)
                            .font(.title)
                            .multilineTextAlignment(.center)
                        
                        Text(record.artist)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Details
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("\(record.format.rawValue)", systemImage: "record.circle")
                        Spacer()
                        if let year = record.year {
                            Label("\(year)", systemImage: "calendar")
                        }
                    }
                    
                    if record.plays > 0 {
                        HStack {
                            Label("\(record.plays) plays", systemImage: "play.circle")
                            Spacer()
                            Text(record.timeSinceLastPlayed)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if isEditing {
                        Toggle("In Heavy Rotation", isOn: $record.inHeavyRotation)
                    } else if record.inHeavyRotation {
                        Label("In Heavy Rotation", systemImage: "flame.fill")
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 2)
                
                // Tags
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                    
                    if isEditing {
                        HStack {
                            TextField("Add tag", text: $newTag)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: {
                                if !newTag.isEmpty {
                                    record.addTag(newTag)
                                    newTag = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                            }
                        }
                    }
                    
                    FlowLayout(
                        spacing: 8,
                        items: record.tags,
                        isEditing: isEditing,
                        onDelete: { tag in
                            record.removeTag(tag)
                        }
                    )
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 2)
                
                // Notes
                if isEditing || record.notes != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        
                        if isEditing {
                            TextEditor(text: Binding(
                                get: { record.notes ?? "" },
                                set: { record.notes = $0.isEmpty ? nil : $0 }
                            ))
                            .frame(height: 100)
                            .padding(4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        } else if let notes = record.notes {
                            Text(notes)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 2)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        recordStore.updateRecord(record)
                    }
                    isEditing.toggle()
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        recordStore.incrementPlays(for: record)
                    } label: {
                        Image(systemName: "play.circle")
                    }
                }
            }
        }
        .alert("Delete Record", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                recordStore.deleteRecord(record)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this record? This action cannot be undone.")
        }
    }
}

struct FlowLayout: View {
    let spacing: CGFloat
    let items: [String]
    let isEditing: Bool
    let onDelete: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            var width = CGFloat.zero
            var height = CGFloat.zero
            var lastHeight = CGFloat.zero
            
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Text(item)
                            if isEditing {
                                Button {
                                    onDelete(item)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                        .alignmentGuide(.leading) { dimension in
                            if abs(width - dimension.width) > geometry.size.width {
                                width = 0
                                height -= lastHeight
                            }
                            lastHeight = dimension.height
                            let result = width
                            if item == items.last {
                                width = 0
                            } else {
                                width -= dimension.width + spacing
                            }
                            return result
                        }
                        .alignmentGuide(.top) { dimension in
                            let result = height
                            if item == items.last {
                                height = 0
                            }
                            return result
                        }
                    }
                }
            }
        }
    }
}

#if DEBUG
struct RecordDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let store = RecordStore()
        let record = Record(
            title: "Dark Side of the Moon",
            artist: "Pink Floyd",
            year: 1973,
            format: .lp,
            tags: ["Progressive Rock", "Psychedelic"],
            plays: 42,
            imageUrl: "default-album",
            notes: "One of the greatest albums ever made.",
            inHeavyRotation: true
        )
        NavigationView {
            RecordDetailView(record: record)
                .environmentObject(store)
        }
    }
}
#endif
