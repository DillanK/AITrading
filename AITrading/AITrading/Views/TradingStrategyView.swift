//
//  TradingStrategyView.swift
//  AITrading
//
//  Created by Jin Salon on 6/20/25.
//

import SwiftUI
import SwiftData

/// 매수/매도 설정 화면
/// 보조지표 기반 거래 전략을 설정하고 백테스팅을 실행
struct TradingStrategyView: View {
    /// SwiftData 모델 컨텍스트
    @Environment(\.modelContext) private var modelContext
    
    /// 뒤로가기를 위한 프레젠테이션 모드
    @Environment(\.presentationMode) var presentationMode
    
    /// 저장된 전략들
    @Query private var strategies: [TradingStrategy]
    
    /// 뷰모델
    @StateObject private var viewModel = TradingStrategyViewModel()
    
    /// 현재 편집 중인 전략
    @State private var currentStrategy = TradingStrategy.conservativeTemplate()
    
    /// 백테스팅 진행 중 여부
    @State private var isBacktesting = false
    
    /// 백테스팅 결과 표시 여부
    @State private var showBacktestResult = false
    
    /// 전략 저장 알림 표시 여부
    @State private var showSaveAlert = false
    
    /// 전략 이름 입력 필드
    @State private var strategyName = ""
    
    /// 선택된 템플릿
    @State private var selectedTemplate: StrategyTemplate?
    
    /// 전략 템플릿 열거형
    enum StrategyTemplate: String, CaseIterable {
        case conservative = "보수적 전략"
        case aggressive = "공격적 전략"
        case macd = "MACD 기본 전략"
        case combined = "복합 지표 전략"
        
        var strategy: TradingStrategy {
            switch self {
            case .conservative: return TradingStrategy.conservativeTemplate()
            case .aggressive: return TradingStrategy.aggressiveTemplate()
            case .macd: return TradingStrategy.macdTemplate()
            case .combined: return TradingStrategy.combinedTemplate()
            }
        }
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
                    // 헤더 섹션
                    headerSection
                    
                    // 메인 콘텐츠
                    ScrollView {
                        VStack(spacing: 20) {
                            // 전략 이름 입력
                            strategyNameSection
                            
                            // 템플릿 선택
                            templateSelectionSection
                            
                            // 지표 선택
                            indicatorSelectionSection
                            
                            // MFI 설정
                            if currentStrategy.indicators.contains("MFI") {
                                mfiSettingsSection
                            }
                            
                            // RSI 설정
                            if currentStrategy.indicators.contains("RSI") {
                                rsiSettingsSection
                            }
                            
                            // MACD 설정
                            if currentStrategy.indicators.contains("MACD") {
                                macdSettingsSection
                            }
                            
                            // 리스크 관리 설정
                            riskManagementSection
                            
                            // 백테스팅 설정
                            backtestingSection
                            
                            // 액션 버튼들
                            actionButtonsSection
                            
                            // 저장된 전략 목록
                            savedStrategiesSection
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("전략 저장", isPresented: $showSaveAlert) {
            TextField("전략 이름", text: $strategyName)
            Button("저장") {
                saveStrategy()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("전략 이름을 입력해주세요.")
        }
        .sheet(isPresented: $showBacktestResult) {
            BacktestResultView(result: viewModel.backtestResult)
        }
        .onAppear {
            strategyName = currentStrategy.name
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
                
                Text("거래 전략 설정")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
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
    
    // MARK: - 전략 이름 섹션
    
    private var strategyNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("전략 이름")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            TextField("새 전략", text: $strategyName)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .onChange(of: strategyName) { _, newValue in
                    currentStrategy.name = newValue
                }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - 템플릿 선택 섹션
    
    private var templateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("전략 템플릿")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(StrategyTemplate.allCases, id: \.self) { template in
                    Button(action: {
                        selectedTemplate = template
                        currentStrategy = template.strategy
                        strategyName = template.strategy.name
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("손절: \(Int(template.strategy.stopLossPercent))%")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.red)
                                    
                                    Text("익절: \(Int(template.strategy.takeProfitPercent))%")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.green)
                                }
                                Spacer()
                            }
                        }
                        .padding(16)
                        .background(
                            selectedTemplate == template 
                            ? LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]), startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.05)]), startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedTemplate == template ? Color.blue : Color.white.opacity(0.1), lineWidth: selectedTemplate == template ? 2 : 1)
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - 지표 선택 섹션
    
    private var indicatorSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("보조지표 선택")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(["MFI", "RSI", "MACD"], id: \.self) { indicator in
                    Button(action: {
                        toggleIndicator(indicator)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: currentStrategy.indicators.contains(indicator) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18))
                                .foregroundColor(currentStrategy.indicators.contains(indicator) ? .blue : .white.opacity(0.5))
                            
                            Text(indicator)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            currentStrategy.indicators.contains(indicator) 
                            ? Color.blue.opacity(0.2) 
                            : Color.white.opacity(0.1)
                        )
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    currentStrategy.indicators.contains(indicator) ? Color.blue : Color.white.opacity(0.2), 
                                    lineWidth: 1
                                )
                        )
                    }
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - MFI 설정 섹션
    
    private var mfiSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MFI 설정")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                settingSlider(
                    title: "매수 임계값",
                    value: $currentStrategy.mfiBuyThreshold,
                    range: 0...50,
                    step: 1,
                    color: .green,
                    suffix: ""
                )
                
                settingSlider(
                    title: "매도 임계값",
                    value: $currentStrategy.mfiSellThreshold,
                    range: 50...100,
                    step: 1,
                    color: .red,
                    suffix: ""
                )
                
                settingSlider(
                    title: "계산 기간",
                    value: Binding(
                        get: { Double(currentStrategy.mfiPeriod) },
                        set: { currentStrategy.mfiPeriod = Int($0) }
                    ),
                    range: 5...30,
                    step: 1,
                    color: .blue,
                    suffix: "일"
                )
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - RSI 설정 섹션
    
    private var rsiSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RSI 설정")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                settingSlider(
                    title: "매수 임계값",
                    value: $currentStrategy.rsiBuyThreshold,
                    range: 0...50,
                    step: 1,
                    color: .green,
                    suffix: ""
                )
                
                settingSlider(
                    title: "매도 임계값",
                    value: $currentStrategy.rsiSellThreshold,
                    range: 50...100,
                    step: 1,
                    color: .red,
                    suffix: ""
                )
                
                settingSlider(
                    title: "계산 기간",
                    value: Binding(
                        get: { Double(currentStrategy.rsiPeriod) },
                        set: { currentStrategy.rsiPeriod = Int($0) }
                    ),
                    range: 5...30,
                    step: 1,
                    color: .blue,
                    suffix: "일"
                )
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - MACD 설정 섹션
    
    private var macdSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MACD 설정")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                settingSlider(
                    title: "단기 EMA",
                    value: Binding(
                        get: { Double(currentStrategy.macdShortPeriod) },
                        set: { currentStrategy.macdShortPeriod = Int($0) }
                    ),
                    range: 5...20,
                    step: 1,
                    color: .green,
                    suffix: "일"
                )
                
                settingSlider(
                    title: "장기 EMA",
                    value: Binding(
                        get: { Double(currentStrategy.macdLongPeriod) },
                        set: { currentStrategy.macdLongPeriod = Int($0) }
                    ),
                    range: 20...50,
                    step: 1,
                    color: .red,
                    suffix: "일"
                )
                
                settingSlider(
                    title: "시그널 라인",
                    value: Binding(
                        get: { Double(currentStrategy.macdSignalPeriod) },
                        set: { currentStrategy.macdSignalPeriod = Int($0) }
                    ),
                    range: 5...15,
                    step: 1,
                    color: .blue,
                    suffix: "일"
                )
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - 리스크 관리 섹션
    
    private var riskManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("리스크 관리")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                settingSlider(
                    title: "손절 비율",
                    value: $currentStrategy.stopLossPercent,
                    range: 1...20,
                    step: 0.5,
                    color: .red,
                    suffix: "%"
                )
                
                settingSlider(
                    title: "익절 비율",
                    value: $currentStrategy.takeProfitPercent,
                    range: 1...30,
                    step: 0.5,
                    color: .green,
                    suffix: "%"
                )
                
                settingSlider(
                    title: "자금 배분",
                    value: $currentStrategy.allocationPercent,
                    range: 1...50,
                    step: 0.5,
                    color: .blue,
                    suffix: "%"
                )
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - 백테스팅 섹션
    
    private var backtestingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("백테스팅 설정")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("테스트 기간")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(viewModel.backtestPeriod)개월")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("초기 자금")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text("₩\(Int(viewModel.initialAmount / 10000))만원")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                settingSlider(
                    title: "기간",
                    value: Binding(
                        get: { Double(viewModel.backtestPeriod) },
                        set: { viewModel.backtestPeriod = Int($0) }
                    ),
                    range: 1...12,
                    step: 1,
                    color: .blue,
                    suffix: "개월"
                )
                
                settingSlider(
                    title: "초기 자금",
                    value: $viewModel.initialAmount,
                    range: 1000000...100000000,
                    step: 1000000,
                    color: .green,
                    suffix: "원"
                )
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - 액션 버튼들
    
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            // 백테스팅 실행 버튼
            Button(action: {
                runBacktest()
            }) {
                HStack(spacing: 8) {
                    if isBacktesting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(isBacktesting ? "백테스팅 중..." : "백테스팅 실행")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    isBacktesting || currentStrategy.indicators.isEmpty 
                    ? LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)]), startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(25)
            }
            .disabled(isBacktesting || currentStrategy.indicators.isEmpty)
            
            // 전략 저장 버튼
            Button(action: {
                showSaveAlert = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .semibold))
                    Text("전략 저장")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    currentStrategy.indicators.isEmpty 
                    ? LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)]), startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(gradient: Gradient(colors: [Color.green, Color.teal]), startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(25)
            }
            .disabled(currentStrategy.indicators.isEmpty)
        }
    }
    
    // MARK: - 저장된 전략 목록
    
    private var savedStrategiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("저장된 전략")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            if strategies.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("저장된 전략이 없습니다.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(strategies) { strategy in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(strategy.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Button(action: {
                                    loadStrategy(strategy)
                                }) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text(strategy.indicators.joined(separator: ", "))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                            
                            HStack {
                                Text("손절: \(Int(strategy.stopLossPercent))%")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.red)
                                
                                Spacer()
                                
                                Text("익절: \(Int(strategy.takeProfitPercent))%")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .onTapGesture {
                            loadStrategy(strategy)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - 슬라이더 컴포넌트
    
    private func settingSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        color: Color,
        suffix: String
    ) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(String(format: "%.1f", value.wrappedValue))\(suffix)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }
            
            Slider(value: value, in: range, step: step)
                .tint(color)
        }
    }
    
    // MARK: - 메서드들
    
    /// 지표 토글
    private func toggleIndicator(_ indicator: String) {
        if currentStrategy.indicators.contains(indicator) {
            currentStrategy.indicators.removeAll { $0 == indicator }
        } else {
            currentStrategy.indicators.append(indicator)
        }
    }
    
    /// 전략 저장
    private func saveStrategy() {
        currentStrategy.name = strategyName
        currentStrategy.updatedAt = Date()
        
        modelContext.insert(currentStrategy)
        
        do {
            try modelContext.save()
            print("✅ 전략 저장 완료: \(strategyName)")
        } catch {
            print("❌ 전략 저장 실패: \(error)")
        }
    }
    
    /// 전략 불러오기
    private func loadStrategy(_ strategy: TradingStrategy) {
        currentStrategy = strategy.copy()
        strategyName = strategy.name
        selectedTemplate = nil
    }
    
    /// 백테스팅 실행
    private func runBacktest() {
        isBacktesting = true
        
        Task {
            await viewModel.runBacktest(strategy: currentStrategy)
            
            await MainActor.run {
                isBacktesting = false
                showBacktestResult = true
            }
        }
    }
}

// MARK: - 백테스팅 결과 뷰

struct BacktestResultView: View {
    let result: BacktestResult?
    @Environment(\.dismiss) private var dismiss
    
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
                
                VStack(spacing: 24) {
                    if let result = result {
                        VStack(spacing: 20) {
                            Text("백테스팅 결과")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 16) {
                                HStack(spacing: 20) {
                                    resultCard(
                                        title: "총 수익률",
                                        value: "\(String(format: "%.2f", result.totalReturn))%",
                                        color: result.totalReturn >= 0 ? .green : .red
                                    )
                                    
                                    resultCard(
                                        title: "MDD",
                                        value: "\(String(format: "%.2f", result.maxDrawdown))%",
                                        color: .red
                                    )
                                }
                                
                                HStack(spacing: 20) {
                                    resultCard(
                                        title: "승률",
                                        value: "\(String(format: "%.1f", result.winRate))%",
                                        color: .blue
                                    )
                                    
                                    resultCard(
                                        title: "거래 횟수",
                                        value: "\(result.totalTrades)회",
                                        color: .white
                                    )
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("백테스팅 결과가 없습니다.")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    Button("닫기") {
                        dismiss()
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func resultCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - 미리보기

#Preview {
    TradingStrategyView()
        .modelContainer(for: TradingStrategy.self, inMemory: true)
}