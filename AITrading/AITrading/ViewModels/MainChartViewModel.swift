//
//  MainChartViewModel.swift
//  AITrading
//
//  Created by Jin Salon on 6/20/25.
//

import Foundation
import Combine

/// 메인 차트 뷰모델
/// 차트 데이터 로드 및 기술적 지표 계산을 담당
@MainActor
class MainChartViewModel: ObservableObject {
    /// 선택된 코인
    let coin: Coin
    
    /// 캔들스틱 데이터
    @Published var candles: [Candle] = []
    
    /// 지표가 포함된 차트 데이터
    @Published var chartData: [ChartDataPoint] = []
    
    /// 로딩 상태
    @Published var isLoading: Bool = false
    
    /// 에러 메시지
    @Published var errorMessage: String?
    
    /// 차트 데이터 포인트 구조체
    struct ChartDataPoint {
        let timestamp: Date
        let candle: Candle
        var mfi: Double?
        var rsi: Double?
        var macd: Double?
        var macdSignal: Double?
        var macdHistogram: Double?
    }
    
    /// 초기화
    /// - Parameter coin: 분석할 코인
    init(coin: Coin) {
        self.coin = coin
    }
    
    /// 차트 데이터를 로드합니다
    /// - Parameter timeframe: 시간 단위 (예: "1h", "1d")
    func loadChartData(timeframe: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("📊 차트 데이터 로딩 시작: \(coin.symbol) - \(timeframe)")
                
                // 캔들스틱 데이터 가져오기
                let fetchedCandles = try await BithumbAPI.shared.fetchCandlestick(
                    market: coin.market,
                    timeframe: timeframe
                )
                
                guard !fetchedCandles.isEmpty else {
                    errorMessage = "차트 데이터가 없습니다."
                    isLoading = false
                    return
                }
                
                // 최근 200개 캔들만 사용 (성능 최적화)
                let recentCandles = Array(fetchedCandles.suffix(200))
                
                // 기술적 지표 계산
                let mfiValues = TechnicalIndicators.calculateMFI(candles: recentCandles)
                let rsiValues = TechnicalIndicators.calculateRSI(candles: recentCandles)
                let macdData = TechnicalIndicators.calculateMACD(candles: recentCandles)
                
                // 차트 데이터 포인트 생성
                var chartPoints: [ChartDataPoint] = []
                
                for (index, candle) in recentCandles.enumerated() {
                    let dataPoint = ChartDataPoint(
                        timestamp: candle.timestamp,
                        candle: candle,
                        mfi: index < mfiValues.count ? mfiValues[index] : nil,
                        rsi: index < rsiValues.count ? rsiValues[index] : nil,
                        macd: index < macdData.macd.count ? macdData.macd[index] : nil,
                        macdSignal: index < macdData.signal.count ? macdData.signal[index] : nil,
                        macdHistogram: index < macdData.histogram.count ? macdData.histogram[index] : nil
                    )
                    chartPoints.append(dataPoint)
                }
                
                // UI 업데이트
                candles = recentCandles
                chartData = chartPoints
                isLoading = false
                
                print("✅ 차트 데이터 로딩 완료: \(recentCandles.count)개 캔들")
                
                // 최신 지표 값 로그
                if let latestMFI = mfiValues.last, let mfi = latestMFI {
                    print("📈 최신 MFI: \(String(format: "%.2f", mfi))")
                }
                if let latestRSI = rsiValues.last, let rsi = latestRSI {
                    print("📈 최신 RSI: \(String(format: "%.2f", rsi))")
                }
                
            } catch {
                errorMessage = "차트 데이터를 불러올 수 없습니다. 네트워크 연결을 확인해주세요."
                isLoading = false
                print("❌ 차트 데이터 로딩 실패: \(error)")
            }
        }
    }
    
    /// 실시간 데이터 업데이트
    /// WebSocket을 통한 실시간 가격 업데이트 (추후 구현)
    func startRealTimeUpdates() {
        // TODO: WebSocket 연결을 통한 실시간 업데이트 구현
        print("🔄 실시간 업데이트 시작: \(coin.symbol)")
    }
    
    /// 실시간 업데이트 중지
    func stopRealTimeUpdates() {
        // TODO: WebSocket 연결 해제
        print("⏹️ 실시간 업데이트 중지: \(coin.symbol)")
    }
    
    /// 특정 시점의 데이터 포인트 정보를 반환
    /// - Parameter timestamp: 조회할 시간
    /// - Returns: 해당 시점의 차트 데이터 포인트
    func getDataPoint(at timestamp: Date) -> ChartDataPoint? {
        return chartData.first { dataPoint in
            Calendar.current.isDate(dataPoint.timestamp, equalTo: timestamp, toGranularity: .minute)
        }
    }
    
    /// 현재 표시 중인 차트의 통계 정보
    var chartStatistics: ChartStatistics? {
        guard !candles.isEmpty else { return nil }
        
        let prices = candles.map { $0.close }
        let volumes = candles.map { $0.volume }
        
        return ChartStatistics(
            highestPrice: prices.max() ?? 0,
            lowestPrice: prices.min() ?? 0,
            averagePrice: prices.reduce(0, +) / Double(prices.count),
            totalVolume: volumes.reduce(0, +),
            priceChange: candles.last!.close - candles.first!.close,
            priceChangePercent: ((candles.last!.close - candles.first!.close) / candles.first!.close) * 100
        )
    }
    
    /// 차트 통계 정보 구조체
    struct ChartStatistics {
        let highestPrice: Double
        let lowestPrice: Double
        let averagePrice: Double
        let totalVolume: Double
        let priceChange: Double
        let priceChangePercent: Double
    }
}

// MARK: - 확장 메서드

extension MainChartViewModel {
    
    /// 현재 MFI 신호 상태
    var currentMFISignal: SignalType {
        guard let latestMFI = chartData.last?.mfi else { return .neutral }
        
        if latestMFI <= 20 {
            return .buy  // 과매도 - 매수 신호
        } else if latestMFI >= 80 {
            return .sell // 과매수 - 매도 신호
        } else {
            return .neutral
        }
    }
    
    /// 현재 RSI 신호 상태
    var currentRSISignal: SignalType {
        guard let latestRSI = chartData.last?.rsi else { return .neutral }
        
        if latestRSI <= 30 {
            return .buy  // 과매도 - 매수 신호
        } else if latestRSI >= 70 {
            return .sell // 과매수 - 매도 신호
        } else {
            return .neutral
        }
    }
    
    /// 현재 MACD 신호 상태
    var currentMACDSignal: SignalType {
        guard let latestMACD = chartData.last?.macd,
              let latestSignal = chartData.last?.macdSignal else { return .neutral }
        
        if latestMACD > latestSignal {
            return .buy   // MACD가 시그널 라인 위 - 매수 신호
        } else if latestMACD < latestSignal {
            return .sell  // MACD가 시그널 라인 아래 - 매도 신호
        } else {
            return .neutral
        }
    }
    
    /// 신호 타입 열거형
    enum SignalType {
        case buy
        case sell
        case neutral
        
        var displayName: String {
            switch self {
            case .buy: return "매수"
            case .sell: return "매도"
            case .neutral: return "중립"
            }
        }
        
        var color: String {
            switch self {
            case .buy: return "green"
            case .sell: return "red"
            case .neutral: return "gray"
            }
        }
    }
}