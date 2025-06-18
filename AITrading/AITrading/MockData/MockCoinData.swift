//
//  MockCoinData.swift
//  AITrading
//
//  Created by Jin Salon on 6/18/25.
//

// File: AITrading/MockData/MockCoinData.swift
// Purpose: Generate mock data for testing
import Foundation

struct MockCoinData {
    static func generateMockCoins() -> [Coin] {
        return [
            Coin(market: "KRW-BTC", symbol: "BTC", name: "Bitcoin", price: 2463.4, changePercent: 8.56, mfi: 45.0, isFavorite: true),
            Coin(market: "KRW-ETH", symbol: "ETH", name: "Ethereum", price: 1477.9, changePercent: -2.54, mfi: 75.0),
            Coin(market: "KRW-XRP", symbol: "XRP", name: "Ripple", price: 985.29, changePercent: 8.56, mfi: 25.0)
        ]
    }
}
