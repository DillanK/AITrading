//
//  ContentView.swift
//  AITrading
//
//  Created by Jin Salon on 6/18/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

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
                    // 헤더 섹션
                    headerSection
                    
                    // 메인 콘텐츠
                    VStack(spacing: 32) {
                        Spacer()
                        
                        // 앱 로고 및 제목
                        appLogoSection
                        
                        // 메뉴 버튼들
                        menuButtonsSection
                        
                        Spacer()
                        
                        // 최근 활동 섹션
                        recentActivitySection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - 헤더 섹션
    
    private var headerSection: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "line.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("AI TRADING")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .tracking(2)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - 앱 로고 섹션
    
    private var appLogoSection: some View {
        VStack(spacing: 16) {
            // 앱 아이콘
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("AI Trading")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("스마트한 암호화폐 거래 플랫폼")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - 메뉴 버튼들
    
    private var menuButtonsSection: some View {
        VStack(spacing: 20) {
            // 주요 기능 버튼들
            HStack(spacing: 16) {
                NavigationLink(destination: CoinListView()) {
                    menuCard(
                        icon: "bitcoinsign.circle.fill",
                        title: "코인 목록",
                        subtitle: "실시간 가격 확인",
                        colors: [Color.orange, Color.yellow]
                    )
                }
                
                NavigationLink(destination: TradingStrategyView()) {
                    menuCard(
                        icon: "chart.bar.fill",
                        title: "전략 설정",
                        subtitle: "백테스팅 & 전략",
                        colors: [Color.blue, Color.purple]
                    )
                }
            }
            
            // 추가 기능들
            HStack(spacing: 16) {
                Button(action: {}) {
                    menuCard(
                        icon: "trophy.fill",
                        title: "포트폴리오",
                        subtitle: "수익률 분석",
                        colors: [Color.green, Color.teal]
                    )
                }
                
                Button(action: {}) {
                    menuCard(
                        icon: "gear",
                        title: "설정",
                        subtitle: "알림 & 환경설정",
                        colors: [Color.gray, Color.secondary]
                    )
                }
            }
        }
    }
    
    // MARK: - 최근 활동 섹션
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("최근 활동")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("모두 보기") {
                    // 전체 활동 보기
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            }
            
            if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("아직 활동이 없습니다")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("코인 목록에서 거래를 시작해보세요")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
            } else {
                VStack(spacing: 12) {
                    ForEach(items.prefix(3)) { item in
                        activityItem(item)
                    }
                }
            }
        }
    }
    
    // MARK: - 메뉴 카드 컴포넌트
    
    private func menuCard(icon: String, title: String, subtitle: String, colors: [Color]) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .medium))
                .foregroundColor(.white)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            LinearGradient(
                gradient: Gradient(colors: colors.map { $0.opacity(0.3) }),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - 활동 아이템
    
    private func activityItem(_ item: Item) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "clock")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("활동 기록")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(item.timestamp.formatted(.dateTime.month().day().hour().minute()))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: { deleteItem(item) }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - 메서드들

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItem(_ item: Item) {
        withAnimation {
            modelContext.delete(item)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}