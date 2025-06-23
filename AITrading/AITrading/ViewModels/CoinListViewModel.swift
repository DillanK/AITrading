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
    @Published var isRefreshing: Bool = false
    @Published var hasData: Bool = false

    private var container: ModelContainer?
    private var cancellables = Set<AnyCancellable>()
    private var allCoins: [Coin] = []

    init(container: ModelContainer? = nil) {
        self.container = container
        setupSearch()
        if container != nil {
            loadInitialData()
        }
    }
    
    func setContainer(_ container: ModelContainer) {
        self.container = container
        loadInitialData()
    }

    // Load initial data (cached first, then refresh)
    private func loadInitialData() {
        Task {
            await loadCachedData()
            
            if hasData {
                // Show cached data first, then refresh in background
                print("📱 캐시된 데이터 표시: \(coins.count)개")
                await refreshDataInBackground()
            } else {
                // No cached data, show loading and fetch
                await loadFreshData()
            }
        }
    }
    
    // Load cached data from SwiftData
    private func loadCachedData() async {
        guard let container = container else { return }
        
        do {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<Coin>()
            let cachedCoins = try context.fetch(descriptor)
            
            if !cachedCoins.isEmpty {
                allCoins = cachedCoins
                coins = sortCoins(cachedCoins)
                hasData = true
                print("📦 캐시된 데이터 로드: \(cachedCoins.count)개")
            }
        } catch {
            print("❌ 캐시된 데이터 로드 실패: \(error)")
        }
    }
    
    // Refresh data in background
    private func refreshDataInBackground() async {
        isRefreshing = true
        
        do {
            print("🔄 백그라운드에서 데이터 업데이트 중...")
            let fetchedCoins = try await BithumbAPI.shared.fetchTicker()
            
            // Update existing coins with new data
            await updateCoinsData(fetchedCoins)
            
            isRefreshing = false
            print("✅ 백그라운드 업데이트 완료: \(coins.count)개")
            
        } catch {
            print("⚠️ 백그라운드 업데이트 실패: \(error)")
            isRefreshing = false
        }
    }
    
    // Load fresh data with loading UI
    private func loadFreshData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 새로운 데이터 로딩 중...")
            let fetchedCoins = try await BithumbAPI.shared.fetchTicker()
            
            allCoins = fetchedCoins
            coins = sortCoins(fetchedCoins)
            hasData = true
            
            // Save to cache
            await saveCoins(fetchedCoins)
            
            isLoading = false
            print("✅ 새로운 데이터 로드 완료: \(coins.count)개")
            
        } catch {
            print("⚠️ API 실패, MockData 사용: \(error)")
            
            let mockCoins = MockCoinData.generateMockCoins()
            allCoins = mockCoins
            coins = sortCoins(mockCoins)
            hasData = true
            
            await saveCoins(mockCoins)
            
            isLoading = false
            errorMessage = "실시간 데이터를 불러올 수 없어 임시 데이터를 표시합니다."
            print("✅ MockData 로드 완료: \(coins.count)개")
        }
    }
    
    // Update existing coins with new data while preserving favorites
    private func updateCoinsData(_ newCoins: [Coin]) async {
        guard let container = container else { return }
        
        do {
            let context = ModelContext(container)
            
            // Create a map of existing favorites
            let favoriteSymbols = Set(allCoins.filter { $0.isFavorite }.map { $0.symbol })
            
            // Update new coins with favorite status
            for coin in newCoins {
                if favoriteSymbols.contains(coin.symbol) {
                    coin.isFavorite = true
                }
            }
            
            // Clear existing data and insert new
            try context.delete(model: Coin.self)
            for coin in newCoins {
                context.insert(coin)
            }
            try context.save()
            
            // Update UI
            allCoins = newCoins
            coins = sortCoins(newCoins)
            
        } catch {
            print("❌ 데이터 업데이트 실패: \(error)")
        }
    }
    
    // Sort coins helper
    private func sortCoins(_ coins: [Coin]) -> [Coin] {
        return coins.sorted { coin1, coin2 in
            if coin1.isFavorite && !coin2.isFavorite { return true }
            if !coin1.isFavorite && coin2.isFavorite { return false }
            return coin1.symbol < coin2.symbol
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
            coins = sortCoins(allCoins)
        } else {
            let filtered = allCoins.filter { 
                $0.symbol.lowercased().contains(text.lowercased()) || 
                $0.name.lowercased().contains(text.lowercased()) 
            }
            coins = sortCoins(filtered)
        }
    }

    // Retry loading data
    func retryLoad() {
        errorMessage = nil
        hasData = false
        allCoins = []
        coins = []
        Task {
            await loadFreshData()
        }
    }
    
    // Manual refresh
    func refresh() {
        Task {
            await refreshDataInBackground()
        }
    }
}
