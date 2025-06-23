//
//  Candle.swift
//  AITrading
//
//  Created by Jin Salon on 6/20/25.
//

import Foundation
import SwiftData

/// 캔들스틱 차트 데이터 모델
/// OHLCV (Open, High, Low, Close, Volume) 데이터를 포함
@Model
class Candle {
    /// 고유 식별자
    var id: UUID = UUID()
    
    /// 캔들 타임스탬프
    var timestamp: Date = Date()
    
    /// 시가 (Opening Price)
    var open: Double = 0.0
    
    /// 고가 (High Price)
    var high: Double = 0.0
    
    /// 저가 (Low Price)
    var low: Double = 0.0
    
    /// 종가 (Closing Price)
    var close: Double = 0.0
    
    /// 거래량 (Volume)
    var volume: Double = 0.0
    
    /// 시장 코드 (예: "KRW-BTC")
    var market: String = ""
    
    /// 시간 단위 (예: "1h", "1d")
    var timeframe: String = ""
    
    /// 캔들 데이터 초기화
    /// - Parameters:
    ///   - timestamp: 캔들 시간
    ///   - open: 시가
    ///   - high: 고가
    ///   - low: 저가
    ///   - close: 종가
    ///   - volume: 거래량
    ///   - market: 시장 코드 (기본값: "")
    ///   - timeframe: 시간 단위 (기본값: "")
    init(timestamp: Date, open: Double, high: Double, low: Double, close: Double, volume: Double, market: String = "", timeframe: String = "") {
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.market = market
        self.timeframe = timeframe
    }
    
    /// 캔들이 상승인지 확인
    /// - Returns: 종가가 시가보다 높으면 true
    var isRising: Bool {
        return close > open
    }
    
    /// 캔들의 몸통 크기
    /// - Returns: 시가와 종가의 차이 (절댓값)
    var bodySize: Double {
        return abs(close - open)
    }
    
    /// 캔들의 위꼬리 크기
    /// - Returns: 고가에서 시가/종가 중 높은 값을 뺀 크기
    var upperShadow: Double {
        return high - max(open, close)
    }
    
    /// 캔들의 아래꼬리 크기
    /// - Returns: 시가/종가 중 낮은 값에서 저가를 뺀 크기
    var lowerShadow: Double {
        return min(open, close) - low
    }
}
