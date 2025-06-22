//
//  BithumbTickerResponse.swift
//  AITrading
//
//  Created by Jin Salon on 6/18/25.
//

import Foundation

// MARK: - Bithumb API v1 응답 모델들

/// Bithumb API v1 마켓 코드 응답 배열
typealias BithumbTickerResponse = [BithumbMarketInfo]

/// Bithumb 마켓 정보
nonisolated struct BithumbMarketInfo: Codable {
    let market: String
    let koreanName: String
    let englishName: String
    let marketWarning: String?
    
    enum CodingKeys: String, @preconcurrency CodingKey {
        case market
        case koreanName = "korean_name"
        case englishName = "english_name"
        case marketWarning = "market_warning"
    }
}

// MARK: - Upbit API v1 응답 모델들 (기존)

/// 마켓 정보 구조체
nonisolated struct MarketInfo: Decodable {
    let market: String
    let koreanName: String
    let englishName: String
    let marketWarning: String  // Optional로 변경
    
    enum CodingKeys: String, @preconcurrency CodingKey {
        case market = "market"
        case koreanName = "korean_name"
        case englishName = "english_name"
        case marketWarning = "market_warning"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.market = (try? container.decode(String.self, forKey: .market)) ?? ""
        self.koreanName = (try? container.decode(String.self, forKey: .koreanName)) ?? ""
        self.englishName = (try? container.decode(String.self, forKey: .englishName)) ?? ""
        self.marketWarning = (try? container.decodeIfPresent(String.self, forKey: .marketWarning)) ?? ""
    }
}

/// 현재가 정보 구조체
nonisolated struct TickerInfo: Decodable {
    let market: String
    let tradePrice: Double
    let openingPrice: Double
    let highPrice: Double
    let lowPrice: Double
    let change: String // "EVEN", "RISE", "FALL"
    let changePrice: Double
    let changeRate: Double
    let accTradeVolume24h: Double
    let timestamp: Int64
    
    enum CodingKeys: String, @preconcurrency CodingKey {
        case market
        case tradePrice = "trade_price"
        case openingPrice = "opening_price"
        case highPrice = "high_price"
        case lowPrice = "low_price"
        case change
        case changePrice = "change_price"
        case changeRate = "change_rate"
        case accTradeVolume24h = "acc_trade_volume_24h"
        case timestamp
    }
}

/// 캔들 데이터 구조체
nonisolated struct CandleData: Decodable {
    let market: String
    let candleDateTimeUtc: Date
    let candleDateTimeKst: Date
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        market = try container.decode(String.self, forKey: .market)
        openingPrice = try container.decode(Double.self, forKey: .openingPrice)
        highPrice = try container.decode(Double.self, forKey: .highPrice)
        lowPrice = try container.decode(Double.self, forKey: .lowPrice)
        tradePrice = try container.decode(Double.self, forKey: .tradePrice)
        timestamp = try container.decode(Int64.self, forKey: .timestamp)
        candleAccTradePrice = try container.decode(Double.self, forKey: .candleAccTradePrice)
        candleAccTradeVolume = try container.decode(Double.self, forKey: .candleAccTradeVolume)
        unit = try container.decode(Int.self, forKey: .unit)
        
        // 날짜 문자열을 Date로 변환
        let utcString = try container.decode(String.self, forKey: .candleDateTimeUtc)
        let kstString = try container.decode(String.self, forKey: .candleDateTimeKst)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        candleDateTimeUtc = formatter.date(from: utcString) ?? Date()
        candleDateTimeKst = formatter.date(from: kstString) ?? Date()
    }
}
