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

    private var container: ModelContainer?
    private var cancellables = Set<AnyCancellable>()

    init(container: ModelContainer? = nil) {
        self.container = container
        setupSearch()
        if container != nil {
            loadData()
        }
    }
    
    func setContainer(_ container: ModelContainer) {
        self.container = container
        loadData()
    }

    // Load data (Bithumb API 사용, 실패시 MockData)
    private func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("🔄 Bithumb API에서 데이터를 가져오는 중...")
                let fetchedCoins = try await BithumbAPI.shared.fetchTicker()
                
                coins = fetchedCoins.sorted { coin1, coin2 in
                    if coin1.isFavorite && !coin2.isFavorite { return true }
                    if !coin1.isFavorite && coin2.isFavorite { return false }
                    return coin1.symbol < coin2.symbol
                }
                
                isLoading = false
                print("✅ Bithumb API 로드 완료: \(coins.count)개")
                
            } catch {
                print("⚠️ Bithumb API 실패, MockData 사용: \(error)")
                
                let mockCoins = MockCoinData.generateMockCoins()
                coins = mockCoins.sorted { coin1, coin2 in
                    if coin1.isFavorite && !coin2.isFavorite { return true }
                    if !coin1.isFavorite && coin2.isFavorite { return false }
                    return coin1.symbol < coin2.symbol
                }
                
                isLoading = false
                errorMessage = "실시간 데이터를 불러올 수 없어 임시 데이터를 표시합니다."
                print("✅ MockData 로드 완료: \(coins.count)개")
            }
        }
    }

    // Save coins to SwiftData
    private func saveCoins(_ coins: [Coin], context: ModelContext? = nil) async {
        guard let container = container else {
            errorMessage = "Failed to init ModelContainer"
            return
        }
        
        do {
            let modelContext = context ?? ModelContext(container)
            for coin in coins {
                modelContext.insert(coin)
            }
            try modelContext.save()
        } catch {
            print("Failed to save coins: \(error)")
            errorMessage = "Failed to save coins: \(error.localizedDescription)"
        }
    }

    // Toggle favorite status
    func toggleFavorite(for coin: Coin, context: ModelContext? = nil) {
        guard let container = container else {
            errorMessage = "Failed to init ModelContainer"
            return
        }
        
        coin.isFavorite.toggle()
        Task {
            do {
                let modelContext = context ?? ModelContext(container)
                modelContext.insert(coin)
                try modelContext.save()
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
        loadData()
    }
}
