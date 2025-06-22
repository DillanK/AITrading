//
//  TradingStrategyViewModel.swift
//  AITrading
//
//  Created by Jin Salon on 6/20/25.
//

import Foundation
import Combine

/// 거래 전략 설정 뷰모델
/// 백테스팅 실행 및 전략 관리를 담당
@MainActor
class TradingStrategyViewModel: ObservableObject {
    /// 백테스팅 기간 (개월)
    @Published var backtestPeriod: Int = 6
    
    /// 초기 투자 금액
    @Published var initialAmount: Double = 10000000 // 1000만원
    
    /// 백테스팅 결과
    @Published var backtestResult: BacktestResult?
    
    /// 로딩 상태
    @Published var isLoading: Bool = false
    
    /// 에러 메시지
    @Published var errorMessage: String?
    
    /// 백테스팅을 실행합니다
    /// - Parameter strategy: 테스트할 거래 전략
    func runBacktest(strategy: TradingStrategy) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("📊 백테스팅 시작: \(strategy.name)")
            
            // 백테스팅 실행
            let result = try await performBacktest(strategy: strategy)
            
            backtestResult = result
            isLoading = false
            
            print("✅ 백테스팅 완료: 수익률 \(String(format: "%.2f", result.totalReturn))%")
            
        } catch {
            errorMessage = "백테스팅 실행 중 오류가 발생했습니다: \(error.localizedDescription)"
            isLoading = false
            print("❌ 백테스팅 실패: \(error)")
        }
    }
    
    /// 실제 백테스팅 로직을 수행합니다
    /// - Parameter strategy: 거래 전략
    /// - Returns: 백테스팅 결과
    private func performBacktest(strategy: TradingStrategy) async throws -> BacktestResult {
        // 테스트용 코인으로 BTC 사용
        let testCoin = "BTC"
        
        // 백테스팅 기간에 해당하는 캔들 데이터 가져오기
        let candles = try await BithumbAPI.shared.fetchCandlestick(
            market: testCoin,
            timeframe: "1h"
        )
        
        guard candles.count >= 100 else {
            throw BacktestError.insufficientData
        }
        
        // 최근 데이터만 사용 (실제로는 backtestPeriod에 맞춰 계산)
        let testCandles = Array(candles.suffix(min(720, candles.count))) // 약 30일치 1시간 캔들
        
        // 기술적 지표 계산
        let mfiValues = TechnicalIndicators.calculateMFI(candles: testCandles)
        let rsiValues = TechnicalIndicators.calculateRSI(candles: testCandles)
        let macdData = TechnicalIndicators.calculateMACD(candles: testCandles)
        
        // 백테스팅 시뮬레이션
        var currentCash = initialAmount
        var currentPosition: Double = 0 // 보유 코인 수량
        var positionValue: Double = 0 // 보유 코인 가치
        var totalTrades = 0
        var winningTrades = 0
        var maxValue = initialAmount
        var maxDrawdown: Double = 0
        
        var trades: [Trade] = []
        
        for (index, candle) in testCandles.enumerated() {
            // 지표 값 추출
            let mfi = index < mfiValues.count ? mfiValues[index] : nil
            let rsi = index < rsiValues.count ? rsiValues[index] : nil
            let macd = index < macdData.macd.count ? macdData.macd[index] : nil
            let macdSignal = index < macdData.signal.count ? macdData.signal[index] : nil
            
            let currentPrice = candle.close
            let currentTotalValue = currentCash + (currentPosition * currentPrice)
            
            // 매수 신호 확인
            if currentPosition == 0 && strategy.shouldBuy(mfi: mfi, rsi: rsi, macd: macd, macdSignal: macdSignal) {
                let investAmount = currentCash * (strategy.allocationPercent / 100)
                if investAmount > 0 {
                    currentPosition = investAmount / currentPrice
                    currentCash -= investAmount
                    positionValue = investAmount
                    
                    let trade = Trade(
                        type: .buy,
                        price: currentPrice,
                        amount: currentPosition,
                        timestamp: candle.timestamp,
                        mfi: mfi,
                        rsi: rsi,
                        macd: macd,
                        profit: nil
                    )
                    trades.append(trade)
                    totalTrades += 1
                    
                    print("💰 매수: \(String(format: "%.2f", currentPosition)) \(testCoin) @ ₩\(Int(currentPrice))")
                }
            }
            // 매도 신호 확인 또는 손절/익절
            else if currentPosition > 0 {
                let currentPositionValue = currentPosition * currentPrice
                let profitPercent = ((currentPositionValue - positionValue) / positionValue) * 100
                
                let shouldSellByIndicator = strategy.shouldSell(mfi: mfi, rsi: rsi, macd: macd, macdSignal: macdSignal)
                let shouldStopLoss = profitPercent <= -strategy.stopLossPercent
                let shouldTakeProfit = profitPercent >= strategy.takeProfitPercent
                
                if shouldSellByIndicator || shouldStopLoss || shouldTakeProfit {
                    currentCash += currentPositionValue
                    
                    if profitPercent > 0 {
                        winningTrades += 1
                    }
                    
                    let trade = Trade(
                        type: .sell,
                        price: currentPrice,
                        amount: currentPosition,
                        timestamp: candle.timestamp,
                        mfi: mfi,
                        rsi: rsi,
                        macd: macd,
                        profit: profitPercent
                    )
                    trades.append(trade)
                    
                    print("💸 매도: \(String(format: "%.2f", currentPosition)) \(testCoin) @ ₩\(Int(currentPrice)) (수익률: \(String(format: "%.2f", profitPercent))%)")
                    
                    currentPosition = 0
                    positionValue = 0
                }
            }
            
            // MDD 계산
            if currentTotalValue > maxValue {
                maxValue = currentTotalValue
            }
            let drawdown = ((maxValue - currentTotalValue) / maxValue) * 100
            if drawdown > maxDrawdown {
                maxDrawdown = drawdown
            }
        }
        
        // 마지막에 포지션이 있으면 정리
        if currentPosition > 0 {
            let finalPrice = testCandles.last!.close
            currentCash += currentPosition * finalPrice
            currentPosition = 0
        }
        
        // 결과 계산
        let finalValue = currentCash
        let totalReturn = ((finalValue - initialAmount) / initialAmount) * 100
        let winRate = totalTrades > 0 ? (Double(winningTrades) / Double(totalTrades)) * 100 : 0
        
        return BacktestResult(
            strategy: strategy.name,
            initialAmount: initialAmount,
            finalAmount: finalValue,
            totalReturn: totalReturn,
            maxDrawdown: maxDrawdown,
            totalTrades: totalTrades,
            winningTrades: winningTrades,
            winRate: winRate,
            startDate: testCandles.first?.timestamp ?? Date(),
            endDate: testCandles.last?.timestamp ?? Date(),
            trades: trades
        )
    }
}

// MARK: - 백테스팅 결과 모델

/// 백테스팅 결과 데이터
struct BacktestResult {
    let strategy: String
    let initialAmount: Double
    let finalAmount: Double
    let totalReturn: Double
    let maxDrawdown: Double
    let totalTrades: Int
    let winningTrades: Int
    let winRate: Double
    let startDate: Date
    let endDate: Date
    let trades: [Trade]
}

/// 거래 내역
struct Trade {
    let type: TradeType
    let price: Double
    let amount: Double
    let timestamp: Date
    let mfi: Double?
    let rsi: Double?
    let macd: Double?
    let profit: Double? // 매도 시에만 설정
    
    enum TradeType {
        case buy
        case sell
        
        var displayName: String {
            switch self {
            case .buy: return "매수"
            case .sell: return "매도"
            }
        }
    }
}

// MARK: - 백테스팅 에러

enum BacktestError: Error, @preconcurrency LocalizedError {
    case insufficientData
    case invalidStrategy
    case calculationError
    
    var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "백테스팅에 필요한 데이터가 부족합니다."
        case .invalidStrategy:
            return "유효하지 않은 전략입니다."
        case .calculationError:
            return "백테스팅 계산 중 오류가 발생했습니다."
        }
    }
}