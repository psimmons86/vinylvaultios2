import SwiftUI

struct RecordDetailView: View {
    @EnvironmentObject var recordStore: RecordStore
    @Environment(\.presentationMode) var presentationMode
    
    let record: Record
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    @State private var animateHeart = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Album Cover
                albumCoverSection
                
                // Record Info
                recordInfoSection
                
                // Stats Section
                statsSection
                
                // Notes Section
                if let notes = record.notes, !notes.isEmpty {
                    notesSection(notes: notes)
                }
                
                // Action Buttons
                actionButtonsSection
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        isEditing = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .alert("Delete Record", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                recordStore.deleteRecord(record)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete '\(record.title)' by \(record.artist)? This action cannot be undone.")
        }
        .sheet(isPresented: $isEditing) {
            Text("Edit Record View")
                .presentationDetents([.large])
        }
    }
    
    // MARK: - View Components
    
    private var albumCoverSection: some View {
        ZStack(alignment: .bottom) {
            // Album Cover
            AsyncImage(url: URL(string: record.imageUrl)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(AppColors.secondary.opacity(0.1))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 60))
                                .foregroundColor(AppColors.secondary)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(AppColors.secondary.opacity(0.1))
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 60))
                                .foregroundColor(AppColors.secondary)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 350)
            .clipped()
            
            // Gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 150)
            
            // Title and artist
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(AppFonts.titleLarge)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text(record.artist)
                    .font(AppFonts.titleSmall)
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                HStack {
                    if let year = record.year {
                        Text("\(year)")
                            .font(AppFonts.bodyMedium)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    FormatBadge(format: record.format)
                        .padding(.leading, 4)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }
    
    private var recordInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let label = record.label, !label.isEmpty {
                infoRow(title: "Label", value: label)
            }
            
            if !record.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(record.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(AppFonts.bodySmall)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.secondary.opacity(0.1))
                                    .foregroundColor(AppColors.secondary)
                                    .cornerRadius(AppShapes.cornerRadiusSmall)
                            }
                        }
                    }
                }
            }
            
            if let discogsId = record.discogsId {
                infoRow(title: "Discogs ID", value: discogsId)
            }
        }
        .padding(20)
        .background(AppColors.cardBackground)
    }
    
    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
            
            Text(value)
                .font(AppFonts.bodyLarge)
                .foregroundColor(AppColors.textPrimary)
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 0) {
            statItem(
                value: "\(record.plays)",
                label: "Plays",
                icon: "play.circle.fill",
                color: AppColors.accent1
            )
            
            Divider()
                .frame(height: 40)
                .padding(.vertical, 10)
            
            statItem(
                value: record.formattedLastPlayed,
                label: "Last Played",
                icon: "calendar",
                color: AppColors.accent3
            )
            
            Divider()
                .frame(height: 40)
                .padding(.vertical, 10)
            
            statItem(
                value: "$\(String(format: "%.2f", record.value))",
                label: "Value",
                icon: "dollarsign.circle.fill",
                color: AppColors.tertiary
            )
        }
        .padding(.vertical, 16)
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(value)
                    .font(AppFonts.bodyLarge.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text(label)
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(AppFonts.titleSmall)
                .foregroundColor(AppColors.textPrimary)
            
            Text(notes)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: "Mark as Played", icon: "play.fill") {
                var updatedRecord = record
                updatedRecord.incrementPlays()
                recordStore.updateRecord(updatedRecord)
                
                // Animate heart
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    animateHeart = true
                }
                
                // Reset animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    animateHeart = false
                }
            }
            
            SecondaryButton(title: "Add to Playlist", icon: "music.note.list") {
                // Add to playlist functionality
            }
        }
        .padding(20)
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusLarge)
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .overlay(
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primary.opacity(0.8))
                .scaleEffect(animateHeart ? 1.5 : 0.1)
                .opacity(animateHeart ? 1 : 0)
                .position(x: UIScreen.main.bounds.width / 2, y: 20)
        )
    }
}

// MARK: - Preview
struct RecordDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RecordDetailView(record: Record(
                title: "Nevermind",
                artist: "Nirvana",
                year: 1991,
                format: .lp,
                tags: ["Grunge", "Rock", "Alternative"],
                plays: 42,
                lastPlayed: Date(),
                imageUrl: "https://example.com/image.jpg",
                notes: "One of the most influential albums of the 90s.",
                value: 29.99,
                label: "DGC Records"
            ))
            .environmentObject(RecordStore())
        }
    }
}
