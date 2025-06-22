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
            // 주요 코인들
            Coin(market: "KRW-BTC", symbol: "BTC", name: "Bitcoin", price: 94500000, changePercent: 2.34, mfi: 45.0, rsi: 62.5, isFavorite: true),
            Coin(market: "KRW-ETH", symbol: "ETH", name: "Ethereum", price: 4850000, changePercent: -1.24, mfi: 38.2, rsi: 55.8, isFavorite: false),
            Coin(market: "KRW-XRP", symbol: "XRP", name: "Ripple", price: 950, changePercent: 5.67, mfi: 65.1, rsi: 72.3, isFavorite: true),
            Coin(market: "KRW-ADA", symbol: "ADA", name: "Cardano", price: 750, changePercent: -0.89, mfi: 42.7, rsi: 48.9, isFavorite: false),
            Coin(market: "KRW-DOT", symbol: "DOT", name: "Polkadot", price: 8500, changePercent: 3.21, mfi: 58.4, rsi: 66.2, isFavorite: false),
            
            // 추가 코인들
            Coin(market: "KRW-LINK", symbol: "LINK", name: "Chainlink", price: 23500, changePercent: 1.45, mfi: 51.2, rsi: 59.7, isFavorite: false),
            Coin(market: "KRW-LTC", symbol: "LTC", name: "Litecoin", price: 135000, changePercent: -2.18, mfi: 35.8, rsi: 44.3, isFavorite: false),
            Coin(market: "KRW-BCH", symbol: "BCH", name: "Bitcoin Cash", price: 650000, changePercent: 0.76, mfi: 47.9, rsi: 52.1, isFavorite: false),
            Coin(market: "KRW-EOS", symbol: "EOS", name: "EOS", price: 950, changePercent: -1.34, mfi: 29.6, rsi: 41.8, isFavorite: false),
            Coin(market: "KRW-TRX", symbol: "TRX", name: "TRON", price: 280, changePercent: 4.12, mfi: 69.3, rsi: 74.5, isFavorite: false),
            
            // 인기 알트코인들
            Coin(market: "KRW-SOL", symbol: "SOL", name: "Solana", price: 285000, changePercent: 6.84, mfi: 73.2, rsi: 78.9, isFavorite: false),
            Coin(market: "KRW-MATIC", symbol: "MATIC", name: "Polygon", price: 1250, changePercent: -3.45, mfi: 31.7, rsi: 38.2, isFavorite: false),
            Coin(market: "KRW-AVAX", symbol: "AVAX", name: "Avalanche", price: 58000, changePercent: 2.89, mfi: 56.8, rsi: 63.4, isFavorite: false),
            Coin(market: "KRW-ATOM", symbol: "ATOM", name: "Cosmos", price: 12500, changePercent: -0.67, mfi: 44.1, rsi: 49.7, isFavorite: false),
            Coin(market: "KRW-NEAR", symbol: "NEAR", name: "NEAR Protocol", price: 7800, changePercent: 1.23, mfi: 52.6, rsi: 57.8, isFavorite: false),
            
            // 기타 코인들
            Coin(market: "KRW-ALGO", symbol: "ALGO", name: "Algorand", price: 450, changePercent: -1.89, mfi: 36.4, rsi: 43.1, isFavorite: false),
            Coin(market: "KRW-VET", symbol: "VET", name: "VeChain", price: 65, changePercent: 3.78, mfi: 61.9, rsi: 68.5, isFavorite: false),
            Coin(market: "KRW-ICP", symbol: "ICP", name: "Internet Computer", price: 15500, changePercent: -2.34, mfi: 33.2, rsi: 40.6, isFavorite: false),
            Coin(market: "KRW-FIL", symbol: "FIL", name: "Filecoin", price: 8900, changePercent: 0.98, mfi: 48.7, rsi: 53.9, isFavorite: false),
            Coin(market: "KRW-SAND", symbol: "SAND", name: "The Sandbox", price: 890, changePercent: 5.23, mfi: 67.8, rsi: 71.2, isFavorite: false),
            
            // 메타버스/게이밍 코인들
            Coin(market: "KRW-MANA", symbol: "MANA", name: "Decentraland", price: 780, changePercent: -1.45, mfi: 41.3, rsi: 46.8, isFavorite: false),
            Coin(market: "KRW-APT", symbol: "APT", name: "Aptos", price: 14500, changePercent: 4.67, mfi: 59.6, rsi: 65.3, isFavorite: false),
            Coin(market: "KRW-STX", symbol: "STX", name: "Stacks", price: 2850, changePercent: -0.78, mfi: 45.8, rsi: 51.4, isFavorite: false),
            Coin(market: "KRW-GRT", symbol: "GRT", name: "The Graph", price: 350, changePercent: 2.45, mfi: 54.2, rsi: 60.7, isFavorite: false),
            Coin(market: "KRW-UNI", symbol: "UNI", name: "Uniswap", price: 12800, changePercent: 1.89, mfi: 49.7, rsi: 56.2, isFavorite: false),
            
            // 밈코인
            Coin(market: "KRW-DOGE", symbol: "DOGE", name: "Dogecoin", price: 450, changePercent: 8.92, mfi: 75.4, rsi: 81.6, isFavorite: false)
        ]
    }
}
