//
//  BithumbTickerResponse.swift
//  AITrading
//
//  Created by Jin Salon on 6/18/25.
//

import Foundation

// API 응답의 최상위 구조
struct TickerResponse: Decodable, Sendable {
    let status: String
    let data: [String: TickerData]
}

// 개별 코인 데이터
struct TickerData: Decodable, Sendable {
    let openingPrice: String
    let closingPrice: String
    let minPrice: String
    let maxPrice: String
    let unitsTraded: String
    let accTradeValue: String
    let prevClosingPrice: String
    let unitsTraded24H: String
    let accTradeValue24H: String
    let fluctate24H: String
    let fluctateRate24H: String
    
    enum CodingKeys: String, @preconcurrency CodingKey {
        case openingPrice = "opening_price"
        case closingPrice = "closing_price"
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case unitsTraded = "units_traded"
        case accTradeValue = "acc_trade_value"
        case prevClosingPrice = "prev_closing_price"
        case unitsTraded24H = "units_traded_24H"
        case accTradeValue24H = "acc_trade_value_24H"
        case fluctate24H = "fluctate_24H"
        case fluctateRate24H = "fluctate_rate_24H"
    }
    
    // String 값을 Double로 변환하는 유틸리티
    var closingPriceDouble: Double? { Double(closingPrice) }
    var fluctateRate24HDouble: Double? { Double(fluctateRate24H) }
}
