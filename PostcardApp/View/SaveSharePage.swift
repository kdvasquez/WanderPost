//
//  SaveSharePage.swift
//  PostcardApp — WanderPost
//
//  FIX: "Back to Collection" now reliably dismisses sheet then pops to root
//

import SwiftUI

struct SaveSharePage: View {
    let postcardID: UUID

    @EnvironmentObject var viewModel: PostcardViewModel
    @Environment(\.resetToHome) var resetToHome
    @EnvironmentObject var tabRouter: TabRouter

    @State private var showConfirmation = false
    @State private var showShareSheet = false
    @State private var composedImage: UIImage? = nil
    @State private var uploadStatus: UploadStatus = .idle

    enum UploadStatus: Equatable {
        case idle, uploading, success, failure(String)
    }

    var postcard: Postcard? {
        viewModel.postcards.first { $0.id == postcardID }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("ParchmentBG"), Color("ParchmentBG").opacity(0.8)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            if let postcard = postcard {
                ScrollView {
                    VStack(spacing: 24) {

                        // Postcard preview
                        PostcardRenderedView(postcard: postcard)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color("InkBrown").opacity(0.2), radius: 20, y: 10)
                            .padding(.horizontal, 20)

                        // Action buttons
                        VStack(spacing: 12) {
                            Button {
                                composedImage = renderPostcardImage(postcard: postcard)
                                showShareSheet = true
                            } label: {
                                ActionRow(icon: "square.and.arrow.up", label: "Share Postcard",
                                          color: Color("InkBrown"))
                            }

                            Button {
                                let img = renderPostcardImage(postcard: postcard)
                                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                                showConfirmation = true
                            } label: {
                                ActionRow(icon: "photo.badge.arrow.down", label: "Save to Photos",
                                          color: Color("AccentTan"))
                            }

                            Button {
                                handleUpload(postcard: postcard)
                            } label: {
                                uploadButtonContent
                            }
                            .disabled(uploadStatus == .uploading)
                        }
                        .padding(.horizontal, 20)

                        // Back to home — works because SaveSharePage is now
                        // pushed onto the nav stack, so resetToHome() unwinds everything
                        Button {
                            withAnimation {
                                resetToHome()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 13))
                                Text("Back to Collection")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 28)
                            .background(
                                LinearGradient(
                                    colors: [Color("AccentTan"), Color("InkBrown")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color("InkBrown").opacity(0.3), radius: 10, y: 4)
                        }
                        .padding(.bottom, 48)
                    }
                    .padding(.top, 24)
                }
            } else {
                Text("⚠️ Postcard not found.")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("WanderPost")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let img = composedImage {
                ShareSheet(items: [img])
            }
        }
        .alert("Saved to Photos!", isPresented: $showConfirmation) {
            Button("Great!", role: .cancel) {}
        }
    }

    // MARK: - Upload button

    @ViewBuilder
    var uploadButtonContent: some View {
        switch uploadStatus {
        case .idle:
            ActionRow(icon: "icloud.and.arrow.up", label: "Upload to Cloud", color: .gray)
        case .uploading:
            ActionRow(icon: "arrow.triangle.2.circlepath", label: "Uploading…", color: .gray)
        case .success:
            ActionRow(icon: "checkmark.icloud", label: "Uploaded!", color: .green)
        case .failure(let msg):
            ActionRow(icon: "xmark.icloud", label: "Failed: \(msg)", color: .red)
        }
    }

    func handleUpload(postcard: Postcard) {
        uploadStatus = .uploading
        guard let baseImage = UIImage(data: postcard.imageData) else {
            uploadStatus = .failure("Could not load image")
            return
        }
        FirebaseManager.shared.uploadPostcard(
            image: baseImage,
            city: postcard.cityName,
            message: postcard.message,
            weather: postcard.weatherDescription ?? "Unknown"
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success: uploadStatus = .success
                case .failure(let error): uploadStatus = .failure(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Postcard image renderer (ocean blue palette)

    func renderPostcardImage(postcard: Postcard) -> UIImage {
        let cardW: CGFloat = 800
        let cardH: CGFloat = 560
        let photoH: CGFloat = 300
        let margin: CGFloat = 24

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cardW, height: cardH))
        return renderer.image { ctx in
            // Background — soft ocean mist
            UIColor(red: 0.94, green: 0.97, blue: 0.98, alpha: 1).setFill()
            UIRectFill(CGRect(origin: .zero, size: CGSize(width: cardW, height: cardH)))

            // Photo
            if let photo = UIImage(data: postcard.imageData) {
                photo.draw(in: CGRect(x: 0, y: 0, width: cardW, height: photoH))
                let gradientColors = [UIColor.clear.cgColor,
                                      UIColor(white: 0, alpha: 0.2).cgColor]
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                          colors: gradientColors as CFArray,
                                          locations: [0.6, 1.0])!
                ctx.cgContext.drawLinearGradient(gradient,
                    start: CGPoint(x: 0, y: photoH - 80),
                    end: CGPoint(x: 0, y: photoH), options: [])
            }

            // Divider
            UIColor(red: 0.08, green: 0.25, blue: 0.42, alpha: 0.2).setStroke()
            let divider = UIBezierPath()
            divider.move(to: CGPoint(x: margin, y: photoH + 10))
            divider.addLine(to: CGPoint(x: cardW - margin, y: photoH + 10))
            divider.lineWidth = 1
            divider.stroke()

            // City name — ocean dark blue
            let cityAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 26, weight: .bold),
                .foregroundColor: UIColor(red: 0.08, green: 0.25, blue: 0.42, alpha: 1)
            ]
            postcard.cityName.draw(at: CGPoint(x: margin, y: photoH + 20), withAttributes: cityAttrs)

            // Date
            let dateStr = DateFormatter.localizedString(from: postcard.dateCreated,
                                                        dateStyle: .medium, timeStyle: .none)
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor(red: 0.20, green: 0.45, blue: 0.60, alpha: 0.8)
            ]
            dateStr.draw(at: CGPoint(x: margin, y: photoH + 54), withAttributes: dateAttrs)

            // Message
            let msgRect = CGRect(x: margin, y: photoH + 82,
                                  width: cardW * 0.62, height: cardH - photoH - 100)
            let msgAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: UIColor(red: 0.08, green: 0.25, blue: 0.42, alpha: 0.85),
                .paragraphStyle: {
                    let ps = NSMutableParagraphStyle()
                    ps.lineSpacing = 5
                    return ps
                }()
            ]
            postcard.message.draw(in: msgRect, withAttributes: msgAttrs)

            // Stamp — mint teal
            let stampSize: CGFloat = 68
            let stampX = cardW - stampSize - margin
            let stampY = photoH + 20
            let stampRect = CGRect(x: stampX, y: stampY, width: stampSize, height: stampSize)
            UIColor.white.setFill()
            let stampPath = UIBezierPath(roundedRect: stampRect, cornerRadius: 6)
            stampPath.fill()
            UIColor(red: 0.20, green: 0.80, blue: 0.69, alpha: 0.5).setStroke()
            stampPath.lineWidth = 1.5
            stampPath.stroke()
            let stampEmoji = NSAttributedString(string: "🌊",
                attributes: [.font: UIFont.systemFont(ofSize: 32)])
            let emojiSize = stampEmoji.size()
            stampEmoji.draw(at: CGPoint(
                x: stampX + (stampSize - emojiSize.width) / 2,
                y: stampY + (stampSize - emojiSize.height) / 2
            ))

            // Postmark
            let pmCX = cardW - margin - stampSize / 2
            let pmCY = photoH + stampSize + 32
            let pmRadius: CGFloat = 26
            UIColor(red: 0.08, green: 0.25, blue: 0.42, alpha: 0.4).setStroke()
            let circle = UIBezierPath(ovalIn: CGRect(x: pmCX - pmRadius, y: pmCY - pmRadius,
                                                      width: pmRadius * 2, height: pmRadius * 2))
            circle.lineWidth = 1.5
            circle.stroke()

            // Weather tag
            if let weather = postcard.weatherDescription {
                let weatherAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor(red: 0.20, green: 0.45, blue: 0.60, alpha: 0.7)
                ]
                let weatherStr = "☁ \(weather.capitalized)"
                let size = (weatherStr as NSString).size(withAttributes: weatherAttrs)
                weatherStr.draw(at: CGPoint(x: cardW - margin - size.width,
                                             y: cardH - margin - size.height),
                                withAttributes: weatherAttrs)
            }

            // Vertical dashed divider
            UIColor(red: 0.08, green: 0.25, blue: 0.42, alpha: 0.15).setStroke()
            let vDivider = UIBezierPath()
            vDivider.move(to: CGPoint(x: cardW * 0.66, y: photoH + 16))
            vDivider.addLine(to: CGPoint(x: cardW * 0.66, y: cardH - margin))
            vDivider.setLineDash([4, 4], count: 2, phase: 0)
            vDivider.lineWidth = 1
            vDivider.stroke()
        }
    }
}

// MARK: - Action Row

struct ActionRow: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 36)
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Color("InkBrown"))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color("InkBrown").opacity(0.2))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color("InkBrown").opacity(0.07), radius: 6, y: 2)
        )
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - On-screen PostcardRenderedView

struct PostcardRenderedView: View {
    let postcard: Postcard

    var body: some View {
        VStack(spacing: 0) {
            if let image = UIImage(data: postcard.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
            }

            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(postcard.cityName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color("InkBrown"))
                    Text(postcard.dateCreated, style: .date)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(Color("InkBrown").opacity(0.35))
                    Spacer(minLength: 4)
                    Text(postcard.message)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(Color("InkBrown").opacity(0.75))
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(Color("InkBrown").opacity(0.1))
                    .frame(width: 1)
                    .padding(.vertical, 12)

                VStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .frame(width: 52, height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color("AccentTan").opacity(0.5), lineWidth: 1.5)
                            )
                        Text("🌊").font(.system(size: 26))
                    }
                    ZStack {
                        Circle()
                            .strokeBorder(Color("InkBrown").opacity(0.35), lineWidth: 1.2)
                            .frame(width: 44, height: 44)
                        Text("WANDER")
                            .font(.system(size: 6, weight: .bold, design: .rounded))
                            .foregroundColor(Color("InkBrown").opacity(0.4))
                    }
                    if let weather = postcard.weatherDescription {
                        Text(weather.capitalized)
                            .font(.system(size: 9, design: .rounded))
                            .foregroundColor(Color("AccentTan").opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .padding(12)
                .frame(width: 80)
            }
            .frame(minHeight: 130)
            .background(Color(red: 0.94, green: 0.97, blue: 0.98))
        }
    }
}
