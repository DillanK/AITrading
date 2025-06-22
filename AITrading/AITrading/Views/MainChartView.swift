//
//  MainChartView.swift
//  AITrading
//
//  Created by Jin Salon on 6/20/25.
//

import SwiftUI
import Charts

/// 메인 차트 분석 화면
/// 선택한 코인의 상세 차트와 기술적 지표를 표시
struct MainChartView: View {
    /// 선택된 코인
    let coin: Coin
    
    /// 차트 뷰모델
    @StateObject private var viewModel: MainChartViewModel
    
    /// 뒤로가기를 위한 프레젠테이션 모드
    @Environment(\.presentationMode) var presentationMode
    
    /// 선택된 시간 단위
    @State private var selectedTimeframe: String = "1h"
    
    /// 선택된 지표
    @State private var selectedIndicators: Set<IndicatorType> = [.mfi]
    
    /// 시간 단위 옵션
    private let timeframeOptions = [
        ("1m", "1분"), ("5m", "5분"), ("15m", "15분"), ("30m", "30분"),
        ("1h", "1시간"), ("4h", "4시간"), ("1d", "1일"), ("1w", "1주")
    ]
    
    /// 지표 타입
    enum IndicatorType: String, CaseIterable {
        case mfi = "MFI"
        case rsi = "RSI" 
        case macd = "MACD"
        
        var displayName: String {
            return self.rawValue
        }
        
        var color: Color {
            switch self {
            case .mfi: return .blue
            case .rsi: return .orange
            case .macd: return .green
            }
        }
    }
    
    /// 초기화
    /// - Parameter coin: 분석할 코인
    init(coin: Coin) {
        self.coin = coin
        self._viewModel = StateObject(wrappedValue: MainChartViewModel(coin: coin))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.15, green: 0.15, blue: 0.2),
                        Color(red: 0.1, green: 0.1, blue: 0.15)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 상단 헤더
                    headerSection
                    
                    if viewModel.isLoading {
                        // 로딩 상태
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.white)
                            Text("차트 데이터 로딩 중...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                    } else if let errorMessage = viewModel.errorMessage {
                        // 에러 상태
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                            
                            Text(errorMessage)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            Button("재시도") {
                                viewModel.loadChartData(timeframe: selectedTimeframe)
                            }
                            .frame(width: 120, height: 44)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                            .cornerRadius(22)
                        }
                        Spacer()
                    } else {
                        // 차트 영역
                        ScrollView {
                            VStack(spacing: 20) {
                                // 캔들스틱 차트
                                candlestickChart
                                
                                // 지표 차트들
                                if selectedIndicators.contains(.mfi) {
                                    mfiChart
                                }
                                
                                if selectedIndicators.contains(.rsi) {
                                    rsiChart
                                }
                                
                                if selectedIndicators.contains(.macd) {
                                    macdChart
                                }
                                
                                // 백테스팅 미리보기 카드
                                backtestingPreviewCard
                                
                                Spacer(minLength: 100)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadChartData(timeframe: selectedTimeframe)
        }
    }
    
    // MARK: - 헤더 섹션
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            // 상단 네비게이션
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(coin.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            // 코인 정보 카드
            coinInfoCard
            
            // 시간 단위 선택
            timeframeSelector
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.6, green: 0.4, blue: 0.8),
                    Color(red: 0.9, green: 0.4, blue: 0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - 코인 정보 카드
    
    private var coinInfoCard: some View {
        HStack {
            // 코인 아이콘
            ZStack {
                Circle()
                    .fill(coinIconColor)
                    .frame(width: 50, height: 50)
                
                Text(coin.symbol.prefix(1))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(coin.symbol)/KRW")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text("₩\(String(format: "%.0f", coin.price))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: coin.changePercent >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                            .foregroundColor(coin.changePercent >= 0 ? .green : .red)
                        
                        Text("\(String(format: "%.2f", abs(coin.changePercent)))%")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(coin.changePercent >= 0 ? .green : .red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((coin.changePercent >= 0 ? Color.green : Color.red).opacity(0.2))
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - 시간 단위 선택기
    
    private var timeframeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(timeframeOptions, id: \.0) { timeframe, display in
                    Button(action: {
                        selectedTimeframe = timeframe
                        viewModel.loadChartData(timeframe: timeframe)
                    }) {
                        Text(display)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTimeframe == timeframe ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedTimeframe == timeframe 
                                ? Color.white 
                                : Color.white.opacity(0.2)
                            )
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }
    
    private var coinIconColor: Color {
        switch coin.symbol {
        case "BTC": return Color.orange
        case "ETH": return Color.blue
        case "XRP": return Color.cyan
        default: return Color.purple
        }
    }
    
    // MARK: - 캔들스틱 차트
    
    private var candlestickChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("가격 차트")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Chart(viewModel.candles.prefix(100), id: \.timestamp) { candle in
                // 캔들스틱 구현 (간단한 바 차트로 대체)
                BarMark(
                    x: .value("시간", candle.timestamp),
                    yStart: .value("저가", candle.low),
                    yEnd: .value("고가", candle.high)
                )
                .foregroundStyle(.white.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1))
                
                RectangleMark(
                    x: .value("시간", candle.timestamp),
                    yStart: .value("시가", candle.open),
                    yEnd: .value("종가", candle.close)
                )
                .foregroundStyle(candle.isRising ? .green : .red)
            }
            .frame(height: 250)
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let price = value.as(Double.self) {
                            Text("₩\(Int(price))")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.caption)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date.formatted(.dateTime.hour().minute()))
                                .foregroundColor(.white.opacity(0.7))
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - MFI 차트
    
    private var mfiChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MFI (Money Flow Index)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Chart(viewModel.chartData.filter { $0.mfi != nil }, id: \.timestamp) { data in
                LineMark(
                    x: .value("시간", data.timestamp),
                    y: .value("MFI", data.mfi ?? 0)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                // 과매수/과매도 기준선
                RuleMark(y: .value("과매수", 80))
                    .foregroundStyle(.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                
                RuleMark(y: .value("과매도", 20))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            }
            .frame(height: 120)
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let mfi = value.as(Double.self) {
                            Text("\(Int(mfi))")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - RSI 차트
    
    private var rsiChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RSI (Relative Strength Index)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Chart(viewModel.chartData.filter { $0.rsi != nil }, id: \.timestamp) { data in
                LineMark(
                    x: .value("시간", data.timestamp),
                    y: .value("RSI", data.rsi ?? 0)
                )
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                // 과매수/과매도 기준선
                RuleMark(y: .value("과매수", 70))
                    .foregroundStyle(.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                
                RuleMark(y: .value("과매도", 30))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            }
            .frame(height: 120)
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let rsi = value.as(Double.self) {
                            Text("\(Int(rsi))")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - MACD 차트
    
    private var macdChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MACD")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Chart(viewModel.chartData.filter { $0.macd != nil }, id: \.timestamp) { data in
                LineMark(
                    x: .value("시간", data.timestamp),
                    y: .value("MACD", data.macd ?? 0)
                )
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                if let signal = data.macdSignal {
                    LineMark(
                        x: .value("시간", data.timestamp),
                        y: .value("Signal", signal)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                }
                
                if let histogram = data.macdHistogram {
                    BarMark(
                        x: .value("시간", data.timestamp),
                        y: .value("Histogram", histogram)
                    )
                    .foregroundStyle(histogram >= 0 ? .green.opacity(0.6) : .red.opacity(0.6))
                }
            }
            .frame(height: 120)
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let macd = value.as(Double.self) {
                            Text(String(format: "%.2f", macd))
                                .foregroundColor(.white.opacity(0.7))
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - 백테스팅 미리보기 카드
    
    private var backtestingPreviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("백테스팅 미리보기")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MFI 전략")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text("+12.5%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("MDD")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text("-3.2%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("승률")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text("68%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            
            NavigationLink(destination: TradingStrategyView()) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16, weight: .semibold))
                    Text("전략 설정 & 백테스팅")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - 미리보기

#Preview {
    MainChartView(coin: Coin(
        market: "KRW-BTC",
        symbol: "BTC",
        name: "Bitcoin",
        price: 55000000,
        changePercent: 2.5,
        mfi: 45.0,
        rsi: 62.0,
        isFavorite: false
    ))
}