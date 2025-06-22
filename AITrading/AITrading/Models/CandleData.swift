//
//  CandleData.swift
//  AITrading
//
//  Created by Jin Salon on 6/21/25.
//

import Foundation
import SwiftData

/// 백테스팅용 1분봉 캔들 데이터 모델
@Model
@preconcurrency
class CandleDataModel {
    var id: String = ""
    var market: String = ""
    var timestamp: Date = Date()
    var openPrice: Double = 0.0
    var highPrice: Double = 0.0
    var lowPrice: Double = 0.0
    var closePrice: Double = 0.0
    var volume: Double = 0.0
    var accTradePrice: Double = 0.0
    
    init(market: String, timestamp: Date, openPrice: Double, highPrice: Double, lowPrice: Double, closePrice: Double, volume: Double, accTradePrice: Double) {
        self.id = "\(market)_\(timestamp.timeIntervalSince1970)"
        self.market = market
        self.timestamp = timestamp
        self.openPrice = openPrice
        self.highPrice = highPrice
        self.lowPrice = lowPrice
        self.closePrice = closePrice
        self.volume = volume
        self.accTradePrice = accTradePrice
    }
}

/// API 응답용 캔들 데이터 구조체
struct CandleResponse: @preconcurrency Codable, Sendable {
    let market: String
    let candleDateTimeUtc: String
    let candleDateTimeKst: String
    let openingPrice: Double
    let highPrice: Double
    let lowPrice: Double
    let tradePrice: Double
    let timestamp: Int64
    let candleAccTradePrice: Double
    let candleAccTradeVolume: Double
    let unit: Int
    
    enum CodingKeys: String, @preconcurrency CodingKey {
        case market
        case candleDateTimeUtc = "candle_date_time_utc"
        case candleDateTimeKst = "candle_date_time_kst"
        case openingPrice = "opening_price"
        case highPrice = "high_price"
        case lowPrice = "low_price"
        case tradePrice = "trade_price"
        case timestamp
        case candleAccTradePrice = "candle_acc_trade_price"
        case candleAccTradeVolume = "candle_acc_trade_volume"
        case unit
    }
    
    /// API 응답을 CandleDataModel로 변환 (MainActor context에서 호출)
    @MainActor
    func toCandleDataModel() -> CandleDataModel {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = dateFormatter.date(from: candleDateTimeKst) ?? Date()
        
        return CandleDataModel(
            market: market,
            timestamp: date,
            openPrice: openingPrice,
            highPrice: highPrice,
            lowPrice: lowPrice,
            closePrice: tradePrice,
            volume: candleAccTradeVolume,
            accTradePrice: candleAccTradePrice
        )
    }
}