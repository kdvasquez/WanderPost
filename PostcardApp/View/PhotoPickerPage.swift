//
//  PhotoPickerPage.swift
//  PostcardApp — WanderPost
//

import SwiftUI

struct PhotoPickerPage: View {
    @EnvironmentObject var viewModel: PostcardViewModel
    @Environment(\.navPath) var navPath
    @State private var showImagePicker = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("ParchmentBG"), Color("ParchmentBG").opacity(0.8)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .shadow(color: Color("InkBrown").opacity(0.1), radius: 12, y: 5)

                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color("AccentTan").opacity(0.1))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 36))
                                    .foregroundColor(Color("AccentTan").opacity(0.6))
                            }
                            Text("Choose a travel photo")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(Color("InkBrown").opacity(0.4))
                        }
                    }
                }
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    Button { showImagePicker = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.selectedImage == nil
                                  ? "photo.badge.plus" : "arrow.triangle.2.circlepath")
                            Text(viewModel.selectedImage == nil ? "Select Photo" : "Change Photo")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Color("InkBrown"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.85))
                                .shadow(color: Color("InkBrown").opacity(0.08), radius: 6, y: 2)
                        )
                    }

                    if viewModel.selectedImage != nil {
                        Button {
                            navPath.wrappedValue.append(.editor(nil))
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "pencil.circle.fill")
                                Text("Continue to Edit")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color("AccentTan"), Color("InkBrown")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color("InkBrown").opacity(0.3), radius: 8, y: 4)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 30)
        }
        .navigationTitle("New Postcard")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $viewModel.selectedImage)
        }
    }
}
