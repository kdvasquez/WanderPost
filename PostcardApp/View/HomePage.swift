//
//  HomePage.swift
//  PostcardApp — WanderPost
//

import SwiftUI

struct HomePage: View {
    @EnvironmentObject var viewModel: PostcardViewModel
    @Environment(\.navPath) var navPath

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color("ParchmentBG"), Color("ParchmentBG").opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("WanderPost")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(Color("InkBrown"))
                        Text("\(viewModel.postcards.count) memories collected")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color("InkBrown").opacity(0.45))
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color("AccentTan").opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color("AccentTan"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 14)

                Divider().background(Color("InkBrown").opacity(0.1))

                if viewModel.postcards.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(viewModel.postcards) { postcard in
                            Button {
                                navPath.wrappedValue.append(.editor(postcard))
                            } label: {
                                PostcardRowCard(postcard: postcard)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                        .onDelete(perform: deletePostcards)

                        Color.clear.frame(height: 90)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                }
            }

            // Floating Create Button
            Button {
                navPath.wrappedValue.append(.photoPicker)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("New Postcard")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color("AccentTan"), Color("InkBrown")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color("InkBrown").opacity(0.35), radius: 14, y: 6)
            }
            .padding(.bottom, 32)
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.load() }
    }

    func deletePostcards(at offsets: IndexSet) {
        offsets.forEach { index in
            viewModel.removePostcard(viewModel.postcards[index])
        }
    }

    var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color("AccentTan").opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "globe.americas")
                    .font(.system(size: 48))
                    .foregroundColor(Color("AccentTan").opacity(0.6))
            }
            Text("No postcards yet")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color("InkBrown"))
            Text("Tap \"New Postcard\" to start collecting\nyour travel memories.")
                .font(.system(size: 14, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(Color("InkBrown").opacity(0.45))
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Row Card

struct PostcardRowCard: View {
    let postcard: Postcard

    var body: some View {
        HStack(spacing: 14) {
            if let uiImage = UIImage(data: postcard.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color("InkBrown").opacity(0.12), radius: 4, y: 2)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(postcard.cityName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color("InkBrown"))

                if let weather = postcard.weatherDescription {
                    HStack(spacing: 4) {
                        Image(systemName: "cloud.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color("AccentTan"))
                        Text(weather.capitalized)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color("AccentTan"))
                    }
                }

                Text(postcard.dateCreated, style: .date)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(Color("InkBrown").opacity(0.35))
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color("InkBrown").opacity(0.07), radius: 8, y: 3)
        )
    }
}
