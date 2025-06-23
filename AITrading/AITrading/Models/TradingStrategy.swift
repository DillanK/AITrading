//
//  TradingStrategy.swift
//  AITrading
//
//  Created by Jin Salon on 6/20/25.
//

import Foundation
import SwiftData

/// 거래 전략 모델
/// 사용자가 설정한 매수/매도 조건을 저장
@Model
class TradingStrategy {
    /// 고유 식별자
    var id: UUID = UUID()
    
    /// 전략 이름
    var name: String = ""
    
    /// 사용할 지표들
    var indicators: [String] = [] // ["MFI", "RSI", "MACD"]
    
    /// MFI 매수 임계값
    var mfiBuyThreshold: Double = 20.0
    
    /// MFI 매도 임계값
    var mfiSellThreshold: Double = 80.0
    
    /// MFI 계산 기간
    var mfiPeriod: Int = 14
    
    /// RSI 매수 임계값
    var rsiBuyThreshold: Double = 30.0
    
    /// RSI 매도 임계값
    var rsiSellThreshold: Double = 70.0
    
    /// RSI 계산 기간
    var rsiPeriod: Int = 14
    
    /// MACD 단기 EMA 기간
    var macdShortPeriod: Int = 12
    
    /// MACD 장기 EMA 기간
    var macdLongPeriod: Int = 26
    
    /// MACD 시그널 라인 기간
    var macdSignalPeriod: Int = 9
    
    /// 손절 비율 (%)
    var stopLossPercent: Double = 5.0
    
    /// 익절 비율 (%)
    var takeProfitPercent: Double = 10.0
    
    /// 자금 배분 비율 (%)
    var allocationPercent: Double = 10.0
    
    /// 생성 일시
    var createdAt: Date = Date()
    
    /// 수정 일시
    var updatedAt: Date = Date()
    
    /// 활성화 여부
    var isActive: Bool = false
    
    /// 초기화
    /// - Parameters:
    ///   - name: 전략 이름
    ///   - indicators: 사용할 지표 배열
    init(name: String, indicators: [String] = ["MFI"]) {
        self.name = name
        self.indicators = indicators
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// 전략 복사
    /// - Returns: 복사된 전략 인스턴스
    func copy() -> TradingStrategy {
        let newStrategy = TradingStrategy(name: "\(name) 복사본", indicators: indicators)
        newStrategy.mfiBuyThreshold = mfiBuyThreshold
        newStrategy.mfiSellThreshold = mfiSellThreshold
        newStrategy.mfiPeriod = mfiPeriod
        newStrategy.rsiBuyThreshold = rsiBuyThreshold
        newStrategy.rsiSellThreshold = rsiSellThreshold
        newStrategy.rsiPeriod = rsiPeriod
        newStrategy.macdShortPeriod = macdShortPeriod
        newStrategy.macdLongPeriod = macdLongPeriod
        newStrategy.macdSignalPeriod = macdSignalPeriod
        newStrategy.stopLossPercent = stopLossPercent
        newStrategy.takeProfitPercent = takeProfitPercent
        newStrategy.allocationPercent = allocationPercent
        return newStrategy
    }
    
    /// 매수 신호 확인
    /// - Parameters:
    ///   - mfi: 현재 MFI 값
    ///   - rsi: 현재 RSI 값
    ///   - macd: 현재 MACD 값
    ///   - macdSignal: 현재 MACD 시그널 값
    /// - Returns: 매수 신호 여부
    func shouldBuy(mfi: Double?, rsi: Double?, macd: Double?, macdSignal: Double?) -> Bool {
        var buySignals = 0
        var totalSignals = 0
        
        if indicators.contains("MFI"), let mfiValue = mfi {
            totalSignals += 1
            if mfiValue <= mfiBuyThreshold {
                buySignals += 1
            }
        }
        
        if indicators.contains("RSI"), let rsiValue = rsi {
            totalSignals += 1
            if rsiValue <= rsiBuyThreshold {
                buySignals += 1
            }
        }
        
        if indicators.contains("MACD"), let macdValue = macd, let signalValue = macdSignal {
            totalSignals += 1
            if macdValue > signalValue {
                buySignals += 1
            }
        }
        
        // 모든 활성화된 지표가 매수 신호를 보내야 함
        return totalSignals > 0 && buySignals == totalSignals
    }
    
    /// 매도 신호 확인
    /// - Parameters:
    ///   - mfi: 현재 MFI 값
    ///   - rsi: 현재 RSI 값
    ///   - macd: 현재 MACD 값
    ///   - macdSignal: 현재 MACD 시그널 값
    /// - Returns: 매도 신호 여부
    func shouldSell(mfi: Double?, rsi: Double?, macd: Double?, macdSignal: Double?) -> Bool {
        var sellSignals = 0
        var totalSignals = 0
        
        if indicators.contains("MFI"), let mfiValue = mfi {
            totalSignals += 1
            if mfiValue >= mfiSellThreshold {
                sellSignals += 1
            }
        }
        
        if indicators.contains("RSI"), let rsiValue = rsi {
            totalSignals += 1
            if rsiValue >= rsiSellThreshold {
                sellSignals += 1
            }
        }
        
        if indicators.contains("MACD"), let macdValue = macd, let signalValue = macdSignal {
            totalSignals += 1
            if macdValue < signalValue {
                sellSignals += 1
            }
        }
        
        // 하나라도 매도 신호를 보내면 매도
        return sellSignals > 0
    }
}

// MARK: - 전략 템플릿

extension TradingStrategy {
    
    /// 보수적 전략 템플릿
    /// - Returns: 보수적 전략 인스턴스
    static func conservativeTemplate() -> TradingStrategy {
        let strategy = TradingStrategy(name: "보수적 전략", indicators: ["MFI"])
        strategy.mfiBuyThreshold = 20.0
        strategy.mfiSellThreshold = 80.0
        strategy.stopLossPercent = 5.0
        strategy.takeProfitPercent = 10.0
        strategy.allocationPercent = 10.0
        return strategy
    }
    
    /// 공격적 전략 템플릿
    /// - Returns: 공격적 전략 인스턴스
    static func aggressiveTemplate() -> TradingStrategy {
        let strategy = TradingStrategy(name: "공격적 전략", indicators: ["MFI"])
        strategy.mfiBuyThreshold = 30.0
        strategy.mfiSellThreshold = 70.0
        strategy.stopLossPercent = 10.0
        strategy.takeProfitPercent = 15.0
        strategy.allocationPercent = 20.0
        return strategy
    }
    
    /// MACD 기본 전략 템플릿
    /// - Returns: MACD 전략 인스턴스
    static func macdTemplate() -> TradingStrategy {
        let strategy = TradingStrategy(name: "MACD 기본 전략", indicators: ["MACD"])
        strategy.stopLossPercent = 5.0
        strategy.takeProfitPercent = 10.0
        strategy.allocationPercent = 15.0
        return strategy
    }
    
    /// 복합 지표 전략 템플릿
    /// - Returns: 복합 지표 전략 인스턴스
    static func combinedTemplate() -> TradingStrategy {
        let strategy = TradingStrategy(name: "복합 지표 전략", indicators: ["MFI", "RSI"])
        strategy.mfiBuyThreshold = 25.0
        strategy.mfiSellThreshold = 75.0
        strategy.rsiBuyThreshold = 35.0
        strategy.rsiSellThreshold = 65.0
        strategy.stopLossPercent = 7.0
        strategy.takeProfitPercent = 12.0
        strategy.allocationPercent = 15.0
        return strategy
    }
}
