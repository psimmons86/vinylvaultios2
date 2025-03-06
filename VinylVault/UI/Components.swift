import SwiftUI

// MARK: - Record Card Views
struct RecordCardLarge: View {
    let record: Record
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Album Cover
            AsyncImage(url: URL(string: record.imageUrl)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: AppShapes.cornerRadiusMedium)
                        .fill(AppColors.secondary.opacity(0.1))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 40))
                                .foregroundColor(AppColors.secondary)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    RoundedRectangle(cornerRadius: AppShapes.cornerRadiusMedium)
                        .fill(AppColors.secondary.opacity(0.1))
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(AppColors.secondary)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: AppShapes.cornerRadiusMedium))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // Record Info
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(AppFonts.titleSmall)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                Text(record.artist)
                    .font(AppFonts.bodyLarge)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                
                HStack {
                    if let year = record.year {
                        Text("\(year)")
                            .font(AppFonts.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    FormatBadge(format: record.format)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusLarge)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct RecordCardMedium: View {
    let record: Record
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Album Cover
            AsyncImage(url: URL(string: record.imageUrl)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: AppShapes.cornerRadiusSmall)
                        .fill(AppColors.secondary.opacity(0.1))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 30))
                                .foregroundColor(AppColors.secondary)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    RoundedRectangle(cornerRadius: AppShapes.cornerRadiusSmall)
                        .fill(AppColors.secondary.opacity(0.1))
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 30))
                                .foregroundColor(AppColors.secondary)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: AppShapes.cornerRadiusSmall))
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Record Info
            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(AppFonts.bodyLarge)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                Text(record.artist)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 150)
        }
        .padding(8)
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct RecordCardRow: View {
    let record: Record
    
    var body: some View {
        HStack(spacing: 16) {
            // Album Cover
            AsyncImage(url: URL(string: record.imageUrl)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: AppShapes.cornerRadiusSmall)
                        .fill(AppColors.secondary.opacity(0.1))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.secondary)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    RoundedRectangle(cornerRadius: AppShapes.cornerRadiusSmall)
                        .fill(AppColors.secondary.opacity(0.1))
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.secondary)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: AppShapes.cornerRadiusSmall))
            
            // Record Info
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(AppFonts.bodyLarge)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                Text(record.artist)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                
                HStack {
                    if let year = record.year {
                        Text("\(year)")
                            .font(AppFonts.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    FormatBadge(format: record.format)
                }
            }
        }
        .padding(12)
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Supporting Components
struct FormatBadge: View {
    let format: RecordFormat
    
    var body: some View {
        Text(format.rawValue)
            .font(AppFonts.caption)
            .foregroundColor(badgeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.1))
            .cornerRadius(AppShapes.cornerRadiusSmall)
    }
    
    var badgeColor: Color {
        switch format {
        case .lp:
            return AppColors.tertiary
        case .ep:
            return AppColors.accent1
        case .single:
            return AppColors.accent3
        }
    }
}

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(AppFonts.bodyLarge.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.primary)
            .foregroundColor(AppColors.textLight)
            .cornerRadius(AppShapes.cornerRadiusMedium)
            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(AppFonts.bodyLarge.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.secondary)
            .foregroundColor(AppColors.textLight)
            .cornerRadius(AppShapes.cornerRadiusMedium)
            .shadow(color: AppColors.secondary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

struct OutlineButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(AppFonts.bodyLarge.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.clear)
            .foregroundColor(AppColors.primary)
            .overlay(
                RoundedRectangle(cornerRadius: AppShapes.cornerRadiusMedium)
                    .stroke(AppColors.primary, lineWidth: 2)
            )
        }
    }
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(AppColors.cardBackground)
            .cornerRadius(AppShapes.cornerRadiusMedium)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
}
