//
//  CoinListView.swift
//  AITrading
//
//  Created by Jin Salon on 6/18/25.
//

import SwiftUI

struct CoinListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = CoinListViewModel()

    @State private var isShowingAddCoin = false

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    TextField("Search coins...", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .opacity(viewModel.searchText.isEmpty ? 0 : 1)
                }

                // Coin List
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text(errorMessage)
                            .foregroundColor(.red)
                        Button("Retry") {
                            viewModel.retryLoad()
                        }
                        .padding()
                    }
                } else {
                    List {
                        ForEach(viewModel.coins, id: \.id) { coin in
                            NavigationLink(destination: Text("Main Screen for \(coin.symbol)")) {
                                HStack(spacing: 10) {
                                    // Symbol and Name
                                    VStack(alignment: .leading) {
                                        Text(coin.symbol)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                        Text(coin.name)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    // Price and Change
                                    VStack(alignment: .trailing) {
                                        Text(String(format: "$%.2f", coin.price))
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                        Text(String(format: "%.2f%%", coin.changePercent))
                                            .font(.system(size: 12))
                                            .foregroundColor(coin.changePercent >= 0 ? .green : .red)
                                    }
                                    // MFI Indicator
                                    Text("MFI: \(coin.mfi ?? 0)")
                                        .font(.system(size: 12))
                                        .foregroundColor(coin.mfi.map { $0 <= 20 ? .green : $0 >= 80 ? .red : .white } ?? .white)
                                    // Favorite Button
                                    Button(action: { viewModel.toggleFavorite(for: coin) }) {
                                        Image(systemName: coin.isFavorite ? "star.fill" : "star")
                                            .foregroundColor(coin.isFavorite ? .yellow : .white)
                                            .imageScale(.medium)
                                    }
                                }
                                .padding(.vertical, 10)
                                .frame(height: 60)
                                .background(Color(.darkGray))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Coin List")
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingAddCoin = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $isShowingAddCoin) {
                Text("Add Coin Screen")
            }
        }
    }
}

#Preview {
    CoinListView()
}
