import SwiftUI

struct RecordRowView: View {
    let record: Record
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: record.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "music.note")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(record.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    if let year = record.year {
                        Text(String(year))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(record.format.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if record.plays > 0 {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(record.plays) plays")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if record.inHeavyRotation {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
struct RecordRowView_Previews: PreviewProvider {
    static var previews: some View {
        let record = Record(
            title: "Dark Side of the Moon",
            artist: "Pink Floyd",
            year: 1973,
            format: .lp,
            plays: 42,
            imageUrl: "default-album",
            inHeavyRotation: true
        )
        RecordRowView(record: record)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
