//
//  Coin.swift
//  AITrading
//
//  Created by Jin Salon on 6/18/25.
//

import Foundation
import SwiftData

@Model
class Coin {
    var id: UUID = UUID()
    var market: String = "" // e.g., "KRW-BTC"
    var symbol: String = "" // e.g., "BTC"
    var name: String = "" // e.g., "Bitcoin"
    var price: Double = 0.0
    var changePercent: Double = 0.0
    var mfi: Double?
    var rsi: Double?
    var isFavorite: Bool = false

    init(market: String, symbol: String, name: String, price: Double, changePercent: Double, mfi: Double? = nil, rsi: Double? = nil, isFavorite: Bool = false) {
        self.market = market
        self.symbol = symbol
        self.name = name
        self.price = price
        self.changePercent = changePercent
        self.mfi = mfi
        self.rsi = rsi
        self.isFavorite = isFavorite
    }
}
