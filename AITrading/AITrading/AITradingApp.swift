//
//  AITradingApp.swift
//  AITrading
//
//  Created by Jin Salon on 6/18/25.
//


import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct AITradingApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Coin.self,
            Candle.self,
            TradingStrategy.self,
            CandleDataModel.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema, 
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.beakbig.ai.trading")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            CoinListView()
                .modelContainer(sharedModelContainer)
                .onAppear {
                    setupBackgroundTasks()
                }
        }
    }
    
    /// 백그라운드 작업 설정
    private func setupBackgroundTasks() {
        // 백그라운드 처리 작업 등록
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.jinsalon.AITrading.dataCollection", using: nil) { task in
            handleDataCollectionBackgroundTask(task: task as! BGProcessingTask)
        }
        
        print("🔧 [SETUP] Background tasks registered")
    }
    
    /// 백그라운드 데이터 수집 작업 처리
    private func handleDataCollectionBackgroundTask(task: BGProcessingTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            // 백그라운드에서 데이터 수집 서비스가 작업을 계속할 수 있도록 지원
            print("🔄 [BACKGROUND] Data collection task started")
            
            // 작업 완료
            task.setTaskCompleted(success: true)
        }
    }
}

