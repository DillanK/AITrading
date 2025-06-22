//
//  BacktestDataView.swift
//  AITrading
//
//  Created by Jin Salon on 6/21/25.
//

import SwiftUI
import SwiftData

struct BacktestDataView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataService = BacktestDataService.shared
    @State private var selectedMarket = "KRW-BTC"
    @State private var collectedMarkets: [String] = []
    @State private var marketDataCounts: [String: Int] = [:]
    @State private var isLoading = false
    @State private var hasDataForSelectedMarket = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteConfirmationMessage = ""
    @State private var pendingDeleteAction: (() async -> Void)?
    @State private var lastDataTimestamp: Date?
    @State private var firstDataTimestamp: Date?
    @State private var customStartDate = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
    @State private var showCustomDatePicker = false
    
    private let availableMarkets = [
        "KRW-BTC", "KRW-ETH", "KRW-XRP", "KRW-ADA", "KRW-DOT",
        "KRW-LINK", "KRW-LTC", "KRW-BCH", "KRW-EOS", "KRW-TRX",
        "KRW-SOL", "KRW-MATIC", "KRW-AVAX", "KRW-ATOM", "KRW-NEAR"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerSection
                
                if dataService.isCollecting {
                    collectingSection
                } else {
                    controlSection
                }
                
                if isLoading {
                    ProgressView("데이터 상태 로딩 중...")
                } else {
                    dataStatusSection
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("백테스팅 데이터")
            .navigationBarTitleDisplayMode(.large)
            .alert("데이터 삭제 확인", isPresented: $showingDeleteConfirmation) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    if let action = pendingDeleteAction {
                        Task {
                            await action()
                        }
                    }
                }
            } message: {
                Text(deleteConfirmationMessage)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !collectedMarkets.isEmpty {
                    Button(action: {
                        confirmDeleteAllData()
                    }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .onAppear {
            setupDataService()
            Task {
                isLoading = true
                await loadDataStatus()
                await updateMarketDataInfo()
                isLoading = false
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("과거 데이터 수집")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("백테스팅을 위한 과거 1분봉 데이터를 수집합니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // 선택된 마켓의 데이터 정보 표시
            if hasDataForSelectedMarket {
                VStack(alignment: .leading, spacing: 4) {
                    Text("현재 데이터 범위:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        if let first = firstDataTimestamp, let last = lastDataTimestamp {
                            Text("\(formatDate(first)) ~ \(formatDate(last))")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        if let count = marketDataCounts[selectedMarket] {
                            Text("\(count.formatted())개")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var collectingSection: some View {
        VStack(spacing: 16) {
            Text(dataService.progressMessage)
                .font(.headline)
                .foregroundColor(.primary)
            
            ProgressView(value: dataService.progress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(y: 2)
            
            Text("\(Int(dataService.progress * 100))% 완료")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 취소 버튼 추가
            Button(action: {
                dataService.cancelCollection()
            }) {
                HStack {
                    Image(systemName: "stop.circle.fill")
                    Text("수집 취소")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!dataService.isCollecting)
            
            if let errorMessage = dataService.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var controlSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("마켓 선택:")
                    .fontWeight(.medium)
                
                Spacer()
                
                Picker("마켓", selection: $selectedMarket) {
                    ForEach(availableMarkets, id: \.self) { market in
                        Text(market).tag(market)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedMarket) { _, newValue in
                    Task {
                        hasDataForSelectedMarket = await dataService.hasDataForMarket(newValue)
                        if hasDataForSelectedMarket {
                            lastDataTimestamp = await dataService.getLastDataTimestamp(for: newValue)
                            firstDataTimestamp = await dataService.getFirstDataTimestamp(for: newValue)
                            // 이어받기를 위해 마지막 데이터 시점을 기본 시작점으로 설정
                            if let lastTime = lastDataTimestamp {
                                customStartDate = lastTime
                            }
                        } else {
                            // 데이터가 없으면 2년 전으로 설정
                            customStartDate = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
                            lastDataTimestamp = nil
                            firstDataTimestamp = nil
                        }
                    }
                }
            }
            
            VStack(spacing: 12) {
                // 사용자 지정 시작 날짜 선택
                HStack {
                    Text("시작 날짜:")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button(action: {
                        showCustomDatePicker.toggle()
                    }) {
                        Text(formatDate(customStartDate))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                }
                
                if showCustomDatePicker {
                    VStack(spacing: 12) {
                        DatePicker("시작 날짜 선택", selection: $customStartDate, displayedComponents: [.date])
                            .datePickerStyle(WheelDatePickerStyle())
                            .frame(height: 120)
                        
                        Button(action: {
                            showCustomDatePicker = false
                        }) {
                            Text("완료")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                
                Button(action: {
                    Task {
                        await dataService.collectTwoYearData(for: selectedMarket, startDate: customStartDate)
                        await loadDataStatus()
                        await updateMarketDataInfo()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("데이터 수집 시작")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(dataService.isCollecting)
                
                // 이어받기 버튼 추가
                if hasDataForSelectedMarket {
                    Button(action: {
                        Task {
                            // 이어받기의 경우 마지막 데이터 시점을 시작점으로 설정
                            if let lastTimestamp = await dataService.getLastDataTimestamp(for: selectedMarket) {
                                await dataService.collectTwoYearData(for: selectedMarket, startDate: lastTimestamp)
                            } else {
                                await dataService.collectTwoYearData(for: selectedMarket, resume: true)
                            }
                            await loadDataStatus()
                            await updateMarketDataInfo()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text("데이터 이어받기")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(dataService.isCollecting)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var dataStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("수집된 데이터")
                .font(.headline)
                .fontWeight(.bold)
            
            if collectedMarkets.isEmpty {
                Text("아직 수집된 데이터가 없습니다.")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(collectedMarkets, id: \.self) { market in
                        marketDataRow(market: market)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func marketDataRow(market: String) -> some View {
        NavigationLink(destination: CollectedDataView(selectedMarket: market)) {
            HStack {
                Text(market)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let count = marketDataCounts[market] {
                    Text("\(count.formatted()) 개")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                // 삭제 버튼 추가
                Button(action: {
                    confirmDeleteMarketData(market: market)
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(4)
                }
                .buttonStyle(PlainButtonStyle())
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func setupDataService() {
        dataService.setContainer(modelContext.container)
    }
    
    private func loadDataStatus() async {
        print("📊 [START] Loading data status")
        collectedMarkets = await dataService.getCollectedMarkets()
        print("📊 [COLLECTED] Markets: \(collectedMarkets)")
        
        await withTaskGroup(of: (String, Int).self) { group in
            for market in collectedMarkets {
                group.addTask {
                    let count = await dataService.getDataCount(for: market)
                    print("📊 [COUNT] \(market): \(count)")
                    return (market, count)
                }
            }
            
            for await (market, count) in group {
                marketDataCounts[market] = count
            }
        }
        print("📊 [END] Data status loaded")
    }
    
    // MARK: - Delete Functions
    
    private func confirmDeleteMarketData(market: String) {
        deleteConfirmationMessage = "\(market)의 모든 데이터를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."
        
        pendingDeleteAction = {
            let success = await self.dataService.deleteAllData(for: market)
            if success {
                await self.loadDataStatus()
                if market == self.selectedMarket {
                    await self.updateMarketDataInfo()
                }
            }
        }
        
        showingDeleteConfirmation = true
    }
    
    private func confirmDeleteAllData() {
        deleteConfirmationMessage = "모든 마켓의 데이터를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."
        
        pendingDeleteAction = {
            let success = await self.dataService.deleteAllData()
            if success {
                await self.loadDataStatus()
                await self.updateMarketDataInfo()
            }
        }
        
        showingDeleteConfirmation = true
    }
    
    private func updateMarketDataInfo() async {
        hasDataForSelectedMarket = await dataService.hasDataForMarket(selectedMarket)
        if hasDataForSelectedMarket {
            lastDataTimestamp = await dataService.getLastDataTimestamp(for: selectedMarket)
            firstDataTimestamp = await dataService.getFirstDataTimestamp(for: selectedMarket)
            // 이어받기를 위해 마지막 데이터 시점을 기본 시작점으로 설정
            if let lastTime = lastDataTimestamp {
                customStartDate = lastTime
            }
        } else {
            // 데이터가 없으면 2년 전으로 설정
            customStartDate = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
            lastDataTimestamp = nil
            firstDataTimestamp = nil
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

#Preview {
    BacktestDataView()
        .modelContainer(for: [CandleDataModel.self])
}
