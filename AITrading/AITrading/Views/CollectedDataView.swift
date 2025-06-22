//
//  CollectedDataView.swift
//  AITrading
//
//  Created by Jin Salon on 6/22/25.
//

import SwiftUI
import SwiftData

struct CollectedDataView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataService = BacktestDataService.shared
    
    let selectedMarket: String
    
    @State private var candleData: [CandleDataModel] = []
    @State private var isLoading = false
    @State private var currentPage = 0
    @State private var itemsPerPage = 50
    @State private var totalCount = 0
    @State private var dateRange: (start: Date?, end: Date?) = (nil, nil)
    @State private var showingDateFilter = false
    @State private var filterStartDate = Date()
    @State private var filterEndDate = Date()
    @State private var showingDeleteOptions = false
    @State private var deleteStartDate = Date()
    @State private var deleteEndDate = Date()
    @State private var showingDeleteConfirmation = false
    @State private var deleteConfirmationMessage = ""
    @State private var pendingDeleteAction: (() async -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 헤더 정보
                headerSection
                
                // 필터 섹션
                filterSection
                
                // 삭제 옵션 섹션
                deleteSection
                
                // 데이터 테이블
                if isLoading {
                    ProgressView("데이터 로딩 중...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if candleData.isEmpty {
                    emptyStateView
                } else {
                    dataTableView
                }
                
                // 페이지네이션
                if !candleData.isEmpty {
                    paginationSection
                }
            }
            .navigationTitle("\(selectedMarket) 데이터")
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
            .onAppear {
                setupDataService()
                loadData()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("총 데이터 개수")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalCount.formatted())개")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if let start = dateRange.start, let end = dateRange.end {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("데이터 범위")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(formatDate(start)) ~")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(formatDate(end))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("필터")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingDateFilter.toggle()
                }) {
                    HStack {
                        Image(systemName: "calendar")
                        Text("날짜 필터")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            }
            
            if showingDateFilter {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("시작 날짜")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $filterStartDate, displayedComponents: [.date])
                                .labelsHidden()
                        }
                        
                        VStack(alignment: .leading) {
                            Text("종료 날짜")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $filterEndDate, displayedComponents: [.date])
                                .labelsHidden()
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button("적용") {
                            applyDateFilter()
                            showingDateFilter = false
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Button("초기화") {
                            resetFilter()
                            showingDateFilter = false
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var deleteSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("데이터 삭제")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingDeleteOptions.toggle()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("삭제 옵션")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                }
            }
            
            if showingDeleteOptions {
                VStack(spacing: 12) {
                    // 날짜 범위 삭제
                    VStack(alignment: .leading, spacing: 8) {
                        Text("기간 지정 삭제")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("시작 날짜")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $deleteStartDate, displayedComponents: [.date])
                                    .labelsHidden()
                            }
                            
                            VStack(alignment: .leading) {
                                Text("종료 날짜")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $deleteEndDate, displayedComponents: [.date])
                                    .labelsHidden()
                            }
                        }
                        
                        Button("기간 내 데이터 삭제") {
                            confirmDateRangeDelete()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    // 전체 삭제 버튼
                    HStack(spacing: 12) {
                        Button("전체 데이터 삭제") {
                            confirmDeleteAllData()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red)
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
        }
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("수집된 데이터가 없습니다")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("\(selectedMarket) 마켓의 데이터를 먼저 수집해주세요.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var dataTableView: some View {
        VStack(spacing: 0) {
            // 테이블 헤더
            HStack {
                Text("시간")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("시가")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .trailing)
                
                Text("고가")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .trailing)
                
                Text("저가")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .trailing)
                
                Text("종가")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .trailing)
                
                Text("거래량")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .trailing)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGray5))
            
            Divider()
            
            // 데이터 리스트
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(candleData.enumerated()), id: \.element.id) { index, candle in
                        candleRowView(candle: candle, index: index)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func candleRowView(candle: CandleDataModel, index: Int) -> some View {
        HStack {
            Text(formatDateTime(candle.timestamp))
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(formatPrice(candle.openPrice))
                .font(.caption)
                .frame(width: 80, alignment: .trailing)
            
            Text(formatPrice(candle.highPrice))
                .font(.caption)
                .foregroundColor(.red)
                .frame(width: 80, alignment: .trailing)
            
            Text(formatPrice(candle.lowPrice))
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 80, alignment: .trailing)
            
            Text(formatPrice(candle.closePrice))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(candle.closePrice >= candle.openPrice ? .red : .blue)
                .frame(width: 80, alignment: .trailing)
            
            Text(formatVolume(candle.volume))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(index % 2 == 0 ? Color.clear : Color(.systemGray6).opacity(0.5))
    }
    
    private var paginationSection: some View {
        HStack {
            Button("이전") {
                if currentPage > 0 {
                    currentPage -= 1
                    loadData()
                }
            }
            .disabled(currentPage == 0)
            
            Spacer()
            
            Text("페이지 \(currentPage + 1) / \(totalPages)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("다음") {
                if currentPage < totalPages - 1 {
                    currentPage += 1
                    loadData()
                }
            }
            .disabled(currentPage >= totalPages - 1)
        }
        .padding()
    }
    
    private var totalPages: Int {
        max(1, (totalCount + itemsPerPage - 1) / itemsPerPage)
    }
    
    private func setupDataService() {
        dataService.setContainer(modelContext.container)
    }
    
    private func loadData() {
        Task {
            isLoading = true
            
            // 전체 개수 조회
            totalCount = await dataService.getDataCount(for: selectedMarket)
            
            // 데이터 범위 조회
            if let first = await dataService.getFirstDataTimestamp(for: selectedMarket),
               let last = await dataService.getLastDataTimestamp(for: selectedMarket) {
                dateRange = (first, last)
                
                // 필터 기본값 설정
                if filterStartDate == Date() && filterEndDate == Date() {
                    filterStartDate = first
                    filterEndDate = last
                }
            }
            
            // 페이지별 데이터 조회
            let startDate = filterStartDate
            let endDate = filterEndDate
            let allData = await dataService.getCandleData(for: selectedMarket, from: startDate, to: endDate)
            
            // 페이지네이션 적용
            let startIndex = currentPage * itemsPerPage
            let endIndex = min(startIndex + itemsPerPage, allData.count)
            
            if startIndex < allData.count {
                candleData = Array(allData[startIndex..<endIndex])
            } else {
                candleData = []
            }
            
            isLoading = false
        }
    }
    
    private func applyDateFilter() {
        currentPage = 0
        loadData()
    }
    
    private func resetFilter() {
        if let start = dateRange.start, let end = dateRange.end {
            filterStartDate = start
            filterEndDate = end
        }
        currentPage = 0
        loadData()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "0"
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.1fK", volume / 1_000)
        } else {
            return String(format: "%.1f", volume)
        }
    }
    
    // MARK: - Delete Functions
    
    private func confirmDateRangeDelete() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ko_KR")
        
        deleteConfirmationMessage = "\(formatter.string(from: deleteStartDate))부터 \(formatter.string(from: deleteEndDate))까지의 \(selectedMarket) 데이터를 삭제하시겠습니까?"
        
        pendingDeleteAction = {
            let success = await self.dataService.deleteData(for: self.selectedMarket, from: self.deleteStartDate, to: self.deleteEndDate)
            if success {
                await self.loadData()
                self.showingDeleteOptions = false
            }
        }
        
        showingDeleteConfirmation = true
    }
    
    private func confirmDeleteAllData() {
        deleteConfirmationMessage = "\(selectedMarket)의 모든 데이터를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."
        
        pendingDeleteAction = {
            let success = await self.dataService.deleteAllData(for: self.selectedMarket)
            if success {
                await self.loadData()
                self.showingDeleteOptions = false
            }
        }
        
        showingDeleteConfirmation = true
    }
}

#Preview {
    CollectedDataView(selectedMarket: "KRW-BTC")
        .modelContainer(for: [CandleDataModel.self])
}