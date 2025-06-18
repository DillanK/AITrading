//
//  CoinListViewModel.swift
//  AITrading
//
//  Created by Jin Salon on 6/18/25.
//


import Foundation
import Combine
import SwiftData

@MainActor
class CoinListViewModel: ObservableObject {
    @Published var coins: [Coin] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var container: ModelContainer? = nil
    private var cancellables = Set<AnyCancellable>()

    init() {
        do {
            // ModelContainer를 안전하게 초기화
            container = try ModelContainer(for: Coin.self)
            loadMockData()
            setupSearch()
            return
        } catch {
            errorMessage = "Failed to initialize data container: \(error.localizedDescription)"
            print("Initialization error: \(error)")
        }
    }

    // Load mock data
    private func loadMockData() {
        isLoading = true
        Task {
            do {
                let mockCoins = MockCoinData.generateMockCoins()
                await saveCoins(mockCoins)
                coins = mockCoins.sorted { $0.isFavorite ? true : $1.isFavorite ? false : $0.symbol < $1.symbol }
                isLoading = false
            } catch {
                errorMessage = "Unable to load coin list. Check your connection and try again."
                isLoading = false
            }
        }
    }

    // Save coins to SwiftData
    private func saveCoins(_ coins: [Coin]) async {
        guard let container = container else {
            errorMessage = "Failed to init ModelContainer"
            return
        }
        
        do {
            let context = ModelContext(container)
            for coin in coins {
                context.insert(coin)
            }
            try context.save()
        } catch {
            print("Failed to save coins: \(error)")
            errorMessage = "Failed to save coins: \(error.localizedDescription)"
        }
    }

    // Toggle favorite status
    func toggleFavorite(for coin: Coin) {
        guard let container = container else {
            errorMessage = "Failed to init ModelContainer"
            return
        }
        
        coin.isFavorite.toggle()
        Task {
            do {
                let context = ModelContext(container)
                context.insert(coin)
                try context.save()
                coins.sort { $0.isFavorite ? true : $1.isFavorite ? false : $0.symbol < $1.symbol }
            } catch {
                print("Failed to update favorite: \(error)")
            }
        }
    }

    // Search functionality
    private func setupSearch() {
        $searchText
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                self?.filterCoins(searchText)
            }
            .store(in: &cancellables)
    }

    private func filterCoins(_ text: String) {
        if text.isEmpty {
            coins = coins.sorted { $0.isFavorite ? true : $1.isFavorite ? false : $0.symbol < $1.symbol }
        } else {
            coins = coins.filter { $0.symbol.lowercased().contains(text.lowercased()) || $0.name.lowercased().contains(text.lowercased()) }
                .sorted { $0.isFavorite ? true : $1.isFavorite ? false : $0.symbol < $1.symbol }
        }
    }

    // Retry loading data
    func retryLoad() {
        errorMessage = nil
        loadMockData()
    }
}
