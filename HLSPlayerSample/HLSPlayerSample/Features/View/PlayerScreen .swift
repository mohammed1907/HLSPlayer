//
//  ContentView.swift
//  HLSPlayerSample
//
//  Created by mohamed hassan on 26/04/2025.
//

import SwiftUI

import SwiftUI

struct PlayerScreen: View {
    @StateObject private var viewModel = PlayerViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Text("HLS Player")
                .font(.title2)
                .bold()
                .padding(.top, 16)

            PlayerView(player: viewModel.player)
                .aspectRatio(9/16, contentMode: .fit)
                .cornerRadius(16)
                .shadow(radius: 5)
                .padding(.horizontal)

            Button(action: {
                viewModel.toggleQuality()
            }) {
                HStack {
                    Image(systemName: viewModel.isHighQuality ? "arrow.down.square" : "arrow.up.square")
                    Text(viewModel.isHighQuality ? "Switch to Low Quality" : "Switch to High Quality")
                        .bold()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Button(action: {
                viewModel.toggleAudioTrack()
            }) {
                HStack {
                    Image(systemName: "music.note.list")
                    Text("Switch Audio Track")
                        .bold()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Text("Current Audio: \(viewModel.currentAudioTrackName)")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.bottom, 16)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            viewModel.setupPlayer()
        }
    }
}

#Preview {
    PlayerScreen()
}
