//
//  CoinListView.swift
//  AITrading
//
//  Created by Jin Salon on 6/18/25.
//

import SwiftUI
import SwiftData

struct CoinListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: CoinListViewModel
    
    @State private var isShowingAddCoin = false
    @State private var isShowingBacktestData = false
    
    init() {
        _viewModel = StateObject(wrappedValue: CoinListViewModel())
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.6, green: 0.4, blue: 0.8),  // Purple
                        Color(red: 0.9, green: 0.4, blue: 0.7)   // Pink
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                    
                    // Main Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Wallet Balance Section
                            walletBalanceSection
                            
                            // My Wallet Section
                            myWalletSection
                            
                            // Coins List
                            coinsListSection
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $isShowingBacktestData) {
            BacktestDataView()
        }
        .onAppear {
            viewModel.setContainer(modelContext.container)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Button(action: {
                isShowingBacktestData = true
            }) {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.white)
                    .font(.title2)
            }
            
            Spacer()
            
            Text("WALLET")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .tracking(2)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "qrcode")
                    .foregroundColor(.white)
                    .font(.title2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Wallet Balance Section
    private var walletBalanceSection: some View {
        VStack(spacing: 8) {
            // Page Indicator Dots
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index == 0 ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 20)
            
            // Total Balance
            Text("$ 9238.31")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(.white)
            
            // Change Amount
            HStack(spacing: 4) {
                Image(systemName: "arrow.up")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("$ 170.25 (22.12%)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
            }
            .padding(.bottom, 30)
            
            // Floating Action Button
            HStack {
                Spacer()
                Button(action: {}) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.gray)
                                .font(.title2)
                        )
                }
            }
            .padding(.trailing, 20)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - My Wallet Section
    private var myWalletSection: some View {
        VStack(spacing: 0) {
            // Dark background starts here
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Wallet")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            Text("$4,926.44")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text("(+221%)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                            
                            Image(systemName: "arrow.up")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { isShowingAddCoin = true }) {
                        HStack(spacing: 4) {
                            Text("ADD COIN")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.cyan)
                            
                            Image(systemName: "plus")
                                .foregroundColor(.cyan)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 20)
            }
            .background(
                Color(red: 0.15, green: 0.15, blue: 0.2)
            )
        }
    }
    
    // MARK: - Coins List Section
    private var coinsListSection: some View {
        VStack(spacing: 0) {
            // Header with refresh indicator
            HStack {
                Text("코인 목록")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Refresh indicator
                if viewModel.isRefreshing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.cyan)
                        Text("업데이트 중...")
                            .font(.system(size: 12))
                            .foregroundColor(.cyan)
                    }
                } else {
                    Button(action: {
                        viewModel.refresh()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.cyan)
                            .font(.title3)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Content based on state
            if viewModel.isLoading && !viewModel.hasData {
                // Initial loading state
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text("코인 데이터를 불러오는 중...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("잠시만 기다려주세요")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 80)
            } else if let errorMessage = viewModel.errorMessage {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title)
                    
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Button(action: {
                        viewModel.retryLoad()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("다시 시도")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if viewModel.coins.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "bitcoinsign.circle")
                        .foregroundColor(.gray)
                        .font(.system(size: 48))
                    
                    Text("코인 데이터가 없습니다")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        viewModel.retryLoad()
                    }) {
                        Text("데이터 불러오기")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.purple)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                // Coins list
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.coins, id: \.id) { coin in
                        NavigationLink(destination: MainChartView(coin: coin)) {
                            CoinRowView(coin: coin, viewModel: viewModel)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Add Wallet Button
            Button(action: {}) {
                HStack {
                    Image(systemName: "plus")
                        .foregroundColor(.purple)
                        .font(.title2)
                    
                    Text("ADD WALLET")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.purple)
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(red: 0.15, green: 0.15, blue: 0.2))
            }
        }
        .background(Color(red: 0.15, green: 0.15, blue: 0.2))
        .sheet(isPresented: $isShowingAddCoin) {
            Text("Add Coin Screen")
        }
    }
}

// MARK: - Coin Row View
struct CoinRowView: View {
    let coin: Coin
    let viewModel: CoinListViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Coin Icon
            ZStack {
                Circle()
                    .fill(coinIconColor)
                    .frame(width: 40, height: 40)
                
                Text(coin.symbol.prefix(1))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Coin Info
            VStack(alignment: .leading, spacing: 2) {
                Text(coin.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("$ \(String(format: "%.2f", coin.price / 1000))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Price and Chart
            VStack(alignment: .trailing, spacing: 2) {
                Text("$ \(String(format: "%.1f", coin.price / 1000))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(String(format: "%.3f", coin.price / 100000)) coin")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // Mini Chart
            miniChartView
            
            // Favorite Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleFavorite(for: coin)
                }
            }) {
                Image(systemName: coin.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(coin.isFavorite ? .red : .gray)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Change Percentage
            HStack(spacing: 4) {
                Image(systemName: coin.changePercent >= 0 ? "arrow.up" : "arrow.down")
                    .foregroundColor(coin.changePercent >= 0 ? .green : .red)
                    .font(.caption)
                
                Text("\(String(format: "%.2f", abs(coin.changePercent)))%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(coin.changePercent >= 0 ? .green : .red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(red: 0.15, green: 0.15, blue: 0.2))
    }
    
    private var coinIconColor: Color {
        switch coin.symbol {
        case "BTC": return Color.orange
        case "ETH": return Color.blue
        case "XRP": return Color.cyan
        default: return Color.purple
        }
    }
    
    private var miniChartView: some View {
        // Simple line chart representation
        HStack(spacing: 1) {
            ForEach(0..<20, id: \.self) { index in
                Rectangle()
                    .fill(coin.changePercent >= 0 ? Color.green : Color.red)
                    .frame(width: 2, height: CGFloat.random(in: 8...24))
                    .opacity(0.7)
            }
        }
        .frame(width: 50, height: 24)
    }
}

#Preview {
    CoinListView()
}