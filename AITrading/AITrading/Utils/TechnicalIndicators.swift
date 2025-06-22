//
//  TechnicalIndicators.swift
//  AITrading
//
//  Created by Jin Salon on 6/20/25.
//

import Foundation

/// 기술적 지표 계산 유틸리티
/// MFI, RSI, MACD 등의 보조지표를 계산합니다
struct TechnicalIndicators {
    
    // MARK: - MFI (Money Flow Index) 계산
    
    /// MFI 지표를 계산합니다
    /// - Parameters:
    ///   - candles: 캔들 데이터 배열
    ///   - period: 계산 기간 (기본값: 14)
    /// - Returns: MFI 값 배열
    static func calculateMFI(candles: [Candle], period: Int = 14) -> [Double?] {
        guard candles.count >= period else { return Array(repeating: nil, count: candles.count) }
        
        var mfiValues: [Double?] = Array(repeating: nil, count: period - 1)
        
        for i in period..<candles.count {
            let periodCandles = Array(candles[(i - period + 1)...i])
            
            var positiveMoneyFlow: Double = 0
            var negativeMoneyFlow: Double = 0
            
            for j in 1..<periodCandles.count {
                let currentCandle = periodCandles[j]
                let previousCandle = periodCandles[j - 1]
                
                // Typical Price = (High + Low + Close) / 3
                let currentTP = (currentCandle.high + currentCandle.low + currentCandle.close) / 3
                let previousTP = (previousCandle.high + previousCandle.low + previousCandle.close) / 3
                
                // Money Flow = Typical Price * Volume
                let moneyFlow = currentTP * currentCandle.volume
                
                if currentTP > previousTP {
                    positiveMoneyFlow += moneyFlow
                } else if currentTP < previousTP {
                    negativeMoneyFlow += moneyFlow
                }
            }
            
            // Money Flow Ratio = Positive Money Flow / Negative Money Flow
            let moneyFlowRatio = negativeMoneyFlow != 0 ? positiveMoneyFlow / negativeMoneyFlow : 0
            
            // MFI = 100 - (100 / (1 + Money Flow Ratio))
            let mfi = 100 - (100 / (1 + moneyFlowRatio))
            
            mfiValues.append(mfi)
        }
        
        return mfiValues
    }
    
    // MARK: - RSI (Relative Strength Index) 계산
    
    /// RSI 지표를 계산합니다
    /// - Parameters:
    ///   - candles: 캔들 데이터 배열
    ///   - period: 계산 기간 (기본값: 14)
    /// - Returns: RSI 값 배열
    static func calculateRSI(candles: [Candle], period: Int = 14) -> [Double?] {
        guard candles.count >= period + 1 else { return Array(repeating: nil, count: candles.count) }
        
        var rsiValues: [Double?] = Array(repeating: nil, count: period)
        
        // 첫 번째 RSI 계산을 위한 초기 평균 계산
        var gains: [Double] = []
        var losses: [Double] = []
        
        for i in 1...period {
            let change = candles[i].close - candles[i - 1].close
            if change > 0 {
                gains.append(change)
                losses.append(0)
            } else {
                gains.append(0)
                losses.append(-change)
            }
        }
        
        var avgGain = gains.reduce(0, +) / Double(period)
        var avgLoss = losses.reduce(0, +) / Double(period)
        
        // 첫 번째 RSI
        if avgLoss != 0 {
            let rs = avgGain / avgLoss
            let rsi = 100 - (100 / (1 + rs))
            rsiValues.append(rsi)
        } else {
            rsiValues.append(100)
        }
        
        // 나머지 RSI 계산 (평활화된 이동평균 사용)
        for i in (period + 1)..<candles.count {
            let change = candles[i].close - candles[i - 1].close
            let gain = change > 0 ? change : 0
            let loss = change < 0 ? -change : 0
            
            // 평활화된 이동평균
            avgGain = (avgGain * Double(period - 1) + gain) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + loss) / Double(period)
            
            if avgLoss != 0 {
                let rs = avgGain / avgLoss
                let rsi = 100 - (100 / (1 + rs))
                rsiValues.append(rsi)
            } else {
                rsiValues.append(100)
            }
        }
        
        return rsiValues
    }
    
    // MARK: - MACD (Moving Average Convergence Divergence) 계산
    
    /// MACD 지표를 계산합니다
    /// - Parameters:
    ///   - candles: 캔들 데이터 배열
    ///   - shortPeriod: 단기 EMA 기간 (기본값: 12)
    ///   - longPeriod: 장기 EMA 기간 (기본값: 26)
    ///   - signalPeriod: 시그널 라인 EMA 기간 (기본값: 9)
    /// - Returns: (MACD, Signal, Histogram) 값 배열의 튜플
    static func calculateMACD(candles: [Candle], shortPeriod: Int = 12, longPeriod: Int = 26, signalPeriod: Int = 9) -> (macd: [Double?], signal: [Double?], histogram: [Double?]) {
        let prices = candles.map { $0.close }
        
        let shortEMA = calculateEMA(prices: prices, period: shortPeriod)
        let longEMA = calculateEMA(prices: prices, period: longPeriod)
        
        // MACD Line = Short EMA - Long EMA
        var macdLine: [Double?] = []
        for i in 0..<prices.count {
            if let short = shortEMA[i], let long = longEMA[i] {
                macdLine.append(short - long)
            } else {
                macdLine.append(nil)
            }
        }
        
        // Signal Line = EMA of MACD Line
        let macdPrices = macdLine.compactMap { $0 }
        let signalEMA = calculateEMA(prices: macdPrices, period: signalPeriod)
        
        // Signal Line 배열을 원래 크기에 맞춤
        var signalLine: [Double?] = Array(repeating: nil, count: macdLine.count)
        var signalIndex = 0
        for i in 0..<macdLine.count {
            if macdLine[i] != nil {
                if signalIndex < signalEMA.count, let signal = signalEMA[signalIndex] {
                    signalLine[i] = signal
                }
                signalIndex += 1
            }
        }
        
        // Histogram = MACD Line - Signal Line
        var histogram: [Double?] = []
        for i in 0..<macdLine.count {
            if let macd = macdLine[i], let signal = signalLine[i] {
                histogram.append(macd - signal)
            } else {
                histogram.append(nil)
            }
        }
        
        return (macd: macdLine, signal: signalLine, histogram: histogram)
    }
    
    // MARK: - EMA (Exponential Moving Average) 계산
    
    /// EMA를 계산합니다
    /// - Parameters:
    ///   - prices: 가격 배열
    ///   - period: 계산 기간
    /// - Returns: EMA 값 배열
    private static func calculateEMA(prices: [Double], period: Int) -> [Double?] {
        guard prices.count >= period else { return Array(repeating: nil, count: prices.count) }
        
        var emaValues: [Double?] = Array(repeating: nil, count: period - 1)
        
        // 첫 번째 EMA = SMA
        let firstSMA = prices[0..<period].reduce(0, +) / Double(period)
        emaValues.append(firstSMA)
        
        // 평활화 상수
        let multiplier = 2.0 / Double(period + 1)
        
        // 나머지 EMA 계산
        var previousEMA = firstSMA
        for i in period..<prices.count {
            let ema = (prices[i] * multiplier) + (previousEMA * (1 - multiplier))
            emaValues.append(ema)
            previousEMA = ema
        }
        
        return emaValues
    }
    
    // MARK: - 단순 이동평균 (SMA) 계산
    
    /// 단순 이동평균을 계산합니다
    /// - Parameters:
    ///   - prices: 가격 배열
    ///   - period: 계산 기간
    /// - Returns: SMA 값 배열
    static func calculateSMA(prices: [Double], period: Int) -> [Double?] {
        guard prices.count >= period else { return Array(repeating: nil, count: prices.count) }
        
        var smaValues: [Double?] = Array(repeating: nil, count: period - 1)
        
        for i in period...prices.count {
            let sum = prices[(i - period)..<i].reduce(0, +)
            let sma = sum / Double(period)
            smaValues.append(sma)
        }
        
        return smaValues
    }
}