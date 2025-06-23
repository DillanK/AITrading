//
//  BacktestDataService.swift
//  AITrading
//
//  Created by Jin Salon on 6/21/25.
//

import Foundation
import Alamofire
import SwiftData
import Combine
import BackgroundTasks

/// API 에러 타입 정의
enum APIError: Error {
    case serverError(code: Int, message: String)
    case invalidResponse
    case networkError(Error)
    
    var localizedDescription: String {
        switch self {
        case .serverError(let code, let message):
            return "API Error \(code): \(message)"
        case .invalidResponse:
            return "Invalid API response format"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

/// 백테스팅용 과거 데이터 수집 서비스
@MainActor
class BacktestDataService: ObservableObject {
    static let shared = BacktestDataService()
    
    @Published var isCollecting: Bool = false
    @Published var progress: Double = 0.0
    @Published var progressMessage: String = ""
    @Published var errorMessage: String? = nil
    
    private let baseURL = "https://api.upbit.com/v1"
    private var modelContainer: ModelContainer?
    private var isCancelled: Bool = false
    
    private init() {}
    
    func setContainer(_ container: ModelContainer) {
        self.modelContainer = container
    }
    
    /// 지정된 기간의 1분봉 데이터 수집 (백그라운드 지원)
    /// - Parameter market: 마켓 코드 (예: "KRW-BTC")
    /// - Parameter startDate: 수집 시작 날짜 (옵션)
    /// - Parameter resume: 이어받기 여부 (기본값: false)
    func collectTwoYearData(for market: String, startDate: Date? = nil, resume: Bool = false) async {
        guard !isCollecting else { return }
        
        isCollecting = true
        isCancelled = false
        progress = 0.0
        errorMessage = nil
        progressMessage = "\(market) 데이터 수집을 \(resume ? "이어서" : "") 시작합니다..."
        
        print("🚀 [START] \(resume ? "Resuming" : "Collecting") minute candle data for \(market)")
        
        let currentDate = Date()
        var collectionStartDate: Date
        
        if let customStartDate = startDate {
            // 사용자가 지정한 시작 날짜 사용
            collectionStartDate = customStartDate
            print("📅 [CUSTOM] Using custom start date: \(customStartDate)")
        } else if resume {
            // 이어받기인 경우 마지막 데이터 시점부터 시작
            collectionStartDate = await getLastDataTimestamp(for: market) ?? Calendar.current.date(byAdding: .year, value: -2, to: currentDate) ?? currentDate
            print("📅 [RESUME] Starting from \(collectionStartDate)")
        } else {
            // 기본값: 2년 전부터
            collectionStartDate = Calendar.current.date(byAdding: .year, value: -2, to: currentDate) ?? currentDate
            print("📅 [DEFAULT] Starting from 2 years ago: \(collectionStartDate)")
        }
        
        // 백그라운드에서 안전하게 데이터 수집 (strong reference로 container 보장)
        await Task.detached { [self, container = modelContainer] in
            await self.collectDataInBatchesBackground(
                market: market, 
                startDate: collectionStartDate, 
                endDate: currentDate,
                container: container
            )
        }.value
        
        if isCancelled {
            progressMessage = "\(market) 데이터 수집이 취소되었습니다."
            print("❌ [CANCELLED] Data collection cancelled for \(market)")
        } else {
            progressMessage = "\(market) 데이터 수집이 완료되었습니다!"
            print("✅ [COMPLETE] Data collection finished for \(market)")
        }
        
        isCollecting = false
    }
    
    /// 데이터 수집 취소
    func cancelCollection() {
        isCancelled = true
        progressMessage = "데이터 수집을 취소하는 중..."
        print("⏹️ [CANCEL] Cancelling data collection...")
    }
    
    /// 수집 취소 여부 확인
    var isCollectionCancelled: Bool {
        return isCancelled
    }
    
    /// 백그라운드용 데이터 수집 메서드 (container를 직접 받아서 사용)
    private func collectDataInBatchesBackground(market: String, startDate: Date, endDate: Date, container: ModelContainer?) async {
        guard let container = container else {
            print("❌ [ERROR] ModelContainer not available in background")
            return
        }
        
        let batchSize = 200 // API 최대 200개
        let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let totalBatches = max(1, (totalDays * 24 * 60) / batchSize) // 대략적인 배치 수
        
        var currentDate = startDate // 시작 날짜부터 순서대로 수집
        var batchCount = 0
        
        print("📅 [BACKGROUND] Start: \(startDate), End: \(endDate), Target batches: \(totalBatches)")
        var nextDate: Date = currentDate
        // 순차적으로 데이터 수집
        while nextDate <= endDate {
            do {
                await MainActor.run {
                    self.progressMessage = "배치 \(batchCount + 1) 수집 중... (\(market))"
                }
                
                // 다음 날짜부터 역순으로 데이터 가져오기 (API 특성상)
                let candleResponses = try await fetchCandleBatchBackground(market: market, to: nextDate, count: batchSize)
                
                if candleResponses.isEmpty {
                    print("⚠️ No more data available for \(market) at \(nextDate)")
                    break
                }
                
                // Asia/Seoul 타임존으로 날짜 비교를 위한 캘린더 설정
                var seoulCalendar = Calendar.current
                seoulCalendar.timeZone = TimeZone(identifier: "Asia/Seoul")!

                if !candleResponses.isEmpty {
                    // MainActor에서 SwiftData 작업 수행 (actor isolation 준수)
                    await MainActor.run {
                        let context = ModelContext(container)
                        
                        for response in candleResponses {
                            // CandleResponse를 CandleDataModel로 변환
                            let date = response.candleDateTimeKst.dateToISO8601() ?? Date()
                            nextDate = max(nextDate, date)
                            debugPrint("Max Date : next \(nextDate)  date \(date) \(max(nextDate, date))")
                            let candle = CandleDataModel(
                                market: response.market,
                                timestamp: date,
                                openPrice: response.openingPrice,
                                highPrice: response.highPrice,
                                lowPrice: response.lowPrice,
                                closePrice: response.tradePrice,
                                volume: response.candleAccTradeVolume,
                                accTradePrice: response.candleAccTradePrice
                            )
                            
                            // CloudKit unique constraint에 의존하여 직접 삽입
                            // 중복 데이터는 CloudKit의 @Attribute(.unique)가 자동으로 처리
                            context.insert(candle)
                        }
                        
                        do {
                            try context.save()
                            print("💾 [SAVED] \(candleResponses.count) candles for period \(currentDate) ~ \(nextDate)")
                        } catch {
                            print("❌ [ERROR] Failed to save candles: \(error)")
                        }
                    }
                } else {
                    print("🔄 [SKIP] No data in target period \(currentDate) ~ \(nextDate)")
                }
                
                // 다음 배치로 이동
                currentDate = nextDate
                batchCount += 1
                
                await MainActor.run {
                    self.progress = min(1.0, Double(batchCount) / Double(totalBatches))
                }
                
                // 취소 확인
                let cancelled = await MainActor.run { self.isCancelled }
                if cancelled {
                    print("❌ [CANCELLED] Collection cancelled at batch \(batchCount)")
                    break
                }
                
                // API 제한 준수를 위한 지연
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1초 대기
                
            } catch {
                print("❌ [ERROR] Background batch collection failed: \(error)")
                await MainActor.run {
                    self.errorMessage = "데이터 수집 오류: \(error.localizedDescription)"
                }
                // 에러 발생시 잠시 대기 후 계속
                do {
                    try await Task.sleep(seconds: 1)
                } catch {
                    // 슬립 에러 무시
                }
            }
        }
        
        print("🏁 [COMPLETE] Background collection finished for \(market)")
    }
    
    /// 단일 배치 데이터 수집
    private func fetchCandleBatch(market: String, to date: Date, count: Int) async throws -> [CandleDataModel] {
        let url = "\(baseURL)/candles/minutes/1"
        
        // KST 시간으로 포맷팅 (Bithumb API에 맞게 수정)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let toDateString = dateFormatter.string(from: date)
        
        let parameters: Parameters = [
            "market": market,
            "to": toDateString,
            "count": count // Int로 보냄 (스트링 변환 안함)
        ]
        
        print("🌐 [REQUEST] URL : \(url)")
        print("🌐 [REQUEST] Parameters: \(parameters)")
        
        // 세션 설정 (타임아웃 10초)
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0
        configuration.httpAdditionalHeaders = ["accept": "application/json"]
        
        let session = Session(configuration: configuration)
        
        let request = session.request(
            url,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.default
        )
        .validate(statusCode: 200..<300)
        
        let data = try await request
            .serializingData()
            .value
        
        do {
            // 먼저 응답 구조 확인
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📋 [DEBUG] API Response: \(jsonString.prefix(500))...")
            }
            
            // 에러 응답 처리
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let error = jsonObject["error"] as? [String: Any] {
                let errorMessage = error["message"] as? String ?? "Unknown API error"
                let errorCode = error["name"] as? Int ?? 0
                print("❌ [API ERROR] Code: \(errorCode), Message: \(errorMessage)")
                throw APIError.serverError(code: errorCode, message: errorMessage)
            }
            
            // 정상 응답 처리 - Bithumb API는 배열을 직접 반환
            let candleResponses = try JSONDecoder().decode([CandleResponse].self, from: data)
            
            var candleModels: [CandleDataModel] = []
            for response in candleResponses {
                let model = await response.toCandleDataModel()
                candleModels.append(model)
            }
            
            print("📊 [SUCCESS] Fetched \(candleModels.count) candles for \(market)")
            return candleModels
        } catch let decodingError as DecodingError {
            print("❌ [ERROR] JSON Decoding failed: \(decodingError)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📋 [DEBUG] Raw Response: \(jsonString)")
            }
            throw decodingError
        } catch {
            print("❌ [ERROR] Request failed: \(error)")
            throw error
        }
    }
    
    /// 백그라운드용 단일 배치 데이터 수집 - CandleResponse 반환 (Sendable 대응)
    private func fetchCandleBatchBackground(market: String, to date: Date, count: Int) async throws -> [CandleResponse] {
        let url = "\(baseURL)/candles/minutes/1"
        
        // KST 시간으로 포맷팅 (Bithumb API에 맞게 수정)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let toDateString = dateFormatter.string(from: date)
        
        let parameters: Parameters = [
            "market": market,
            "to": toDateString,
            "count": count // Int로 보냄
        ]
        
        print("🌐 [BACKGROUND] URL : \(url)")
        print("🌐 [BACKGROUND] Parameters: \(parameters)")
        
        // 세션 설정 (타임아웃 10초)
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0
        configuration.httpAdditionalHeaders = ["accept": "application/json"]
        
        let session = Session(configuration: configuration)
        
        let request = session.request(
            url,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.default
        )
        .validate(statusCode: 200..<300)
        
        let data = try await request
            .serializingData()
            .value
        
        do {
            // 먼저 응답 구조 확인
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📋 [BACKGROUND] API Response: \(jsonString.prefix(500))...")
            }
            
            // 에러 응답 처리
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let error = jsonObject["error"] as? [String: Any] {
                let errorMessage = error["message"] as? String ?? "Unknown API error"
                let errorCode = error["name"] as? Int ?? 0
                print("❌ [BACKGROUND API ERROR] Code: \(errorCode), Message: \(errorMessage)")
                throw APIError.serverError(code: errorCode, message: errorMessage)
            }
            
            // 정상 응답 처리 - Bithumb API는 배열을 직접 반환
            let candleResponses = try JSONDecoder().decode([CandleResponse].self, from: data)
            
            print("📊 [BACKGROUND SUCCESS] Fetched \(candleResponses.count) candle responses for \(market)")
            return candleResponses
        } catch let decodingError as DecodingError {
            print("❌ [BACKGROUND ERROR] JSON Decoding failed: \(decodingError)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📋 [BACKGROUND DEBUG] Raw Response: \(jsonString)")
            }
            throw decodingError
        } catch {
            print("❌ [BACKGROUND ERROR] Request failed: \(error)")
            throw error
        }
    }
    
    
    /// 캔들 데이터를 SwiftData에 저장
    private func saveCandleData(_ candles: [CandleDataModel]) async {
        guard let container = modelContainer else {
            print("❌ [ERROR] ModelContainer not available")
            errorMessage = "데이터베이스 컨테이너가 초기화되지 않았습니다."
            return
        }
        
        do {
            let context = ModelContext(container)
            
            for candle in candles {
                // CloudKit unique constraint에 의존하여 직접 삽입
                // 중복 데이터는 CloudKit의 @Attribute(.unique)가 자동으로 처리
                context.insert(candle)
            }
            
            try context.save()
            print("💾 [SAVED] \(candles.count) candles saved to database")
            
        } catch {
            print("❌ [ERROR] Failed to save candles: \(error)")
            errorMessage = "캔들 데이터 저장 실패: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func getCandleData(for market: String, from startDate: Date, to endDate: Date) async -> [CandleDataModel] {
        guard let container = modelContainer else { return [] }
        
        do {
            let context = ModelContext(container)
            
            // SwiftData Predicate를 사용한 효율적인 쿼리
            let predicate = #Predicate<CandleDataModel> { candle in
                candle.market == market && 
                candle.timestamp >= startDate && 
                candle.timestamp <= endDate
            }
            
            let descriptor = FetchDescriptor<CandleDataModel>(
                predicate: predicate,
                sortBy: [SortDescriptor(\CandleDataModel.timestamp, order: .forward)]
            )
            
            let results = try context.fetch(descriptor)
            
            print("📊 [FETCH] Retrieved \(results.count) candles using optimized query")
            return results
            
        } catch {
            print("❌ [ERROR] Failed to fetch candle data: \(error)")
            errorMessage = "캔들 데이터 조회 실패: \(error.localizedDescription)"
            return []
        }
    }
    
    @MainActor
    func getDataCount(for market: String) async -> Int {
        guard let container = modelContainer else { return 0 }
        
        do {
            let context = ModelContext(container)
            
            // SwiftData Predicate를 사용한 효율적인 COUNT 쿼리
            let predicate = #Predicate<CandleDataModel> { candle in
                candle.market == market
            }
            
            let descriptor = FetchDescriptor<CandleDataModel>(predicate: predicate)
            let results = try context.fetch(descriptor)
            
            return results.count
            
        } catch {
            print("❌ [ERROR] Failed to count data: \(error)")
            errorMessage = "데이터 개수 조회 실패: \(error.localizedDescription)"
            return 0
        }
    }
    
    func getCollectedMarkets() async -> [String] {
        guard let container = modelContainer else { return [] }
        
        do {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<CandleDataModel>()
            let candles = try context.fetch(descriptor)
            
            let markets = Set(candles.map { $0.market })
            return Array(markets).sorted()
            
        } catch {
            print("❌ [ERROR] Failed to fetch markets: \(error)")
            return []
        }
    }
    
    /// 특정 마켓의 마지막 데이터 시점 조회 (이어받기용)
    @MainActor
    func getLastDataTimestamp(for market: String) async -> Date? {
        guard let container = modelContainer else { return nil }
        
        do {
            let context = ModelContext(container)
            
            // SwiftData Predicate로 해당 마켓만 조회하고 timestamp 역순 정렬로 최신 1개만 가져오기
            let predicate = #Predicate<CandleDataModel> { candle in
                candle.market == market
            }
            
            var descriptor = FetchDescriptor<CandleDataModel>(predicate: predicate)
            descriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]
            descriptor.fetchLimit = 1
            
            let results = try context.fetch(descriptor)
            
            if let lastCandle = results.first {
                print("📅 [LAST] Last data for \(market): \(lastCandle.timestamp)")
                return lastCandle.timestamp
            }
            
            return nil
        } catch {
            print("❌ [ERROR] Failed to get last timestamp for \(market): \(error)")
            return nil
        }
    }
    
    /// 특정 마켓의 최초 데이터 시점 조회
    @MainActor
    func getFirstDataTimestamp(for market: String) async -> Date? {
        guard let container = modelContainer else { return nil }
        
        do {
            let context = ModelContext(container)
            
            // SwiftData Predicate로 해당 마켓만 조회하고 timestamp 정순 정렬로 가장 오래된 1개만 가져오기
            let predicate = #Predicate<CandleDataModel> { candle in
                candle.market == market
            }
            
            var descriptor = FetchDescriptor<CandleDataModel>(predicate: predicate)
            descriptor.sortBy = [SortDescriptor(\.timestamp, order: .forward)]
            descriptor.fetchLimit = 1
            
            let results = try context.fetch(descriptor)
            
            if let firstCandle = results.first {
                print("📅 [FIRST] First data for \(market): \(firstCandle.timestamp)")
                return firstCandle.timestamp
            }
            
            return nil
        } catch {
            print("❌ [ERROR] Failed to get first timestamp for \(market): \(error)")
            return nil
        }
    }
    
    /// 특정 마켓에 데이터가 있는지 확인 (이어받기 판단용)
    func hasDataForMarket(_ market: String) async -> Bool {
        let count = await getDataCount(for: market)
        return count > 0
    }
    
    /// 특정 마켓의 모든 데이터 삭제
    @MainActor
    func deleteAllData(for market: String) async -> Bool {
        guard let container = modelContainer else { return false }
        
        do {
            let context = ModelContext(container)
            
            // SwiftData Predicate를 사용한 효율적인 삭제
            let predicate = #Predicate<CandleDataModel> { candle in
                candle.market == market
            }
            
            let descriptor = FetchDescriptor<CandleDataModel>(predicate: predicate)
            let marketCandles = try context.fetch(descriptor)
            
            for candle in marketCandles {
                context.delete(candle)
            }
            
            try context.save()
            print("🗑️ [DELETE] Deleted all data for \(market) (\(marketCandles.count) items)")
            return true
            
        } catch {
            print("❌ [ERROR] Failed to delete data for \(market): \(error)")
            errorMessage = "데이터 삭제 실패: \(error.localizedDescription)"
            return false
        }
    }
    
    /// 특정 마켓의 날짜 범위 데이터 삭제
    @MainActor
    func deleteData(for market: String, from startDate: Date, to endDate: Date) async -> Bool {
        guard let container = modelContainer else { return false }
        
        do {
            let context = ModelContext(container)
            
            // SwiftData Predicate를 사용한 효율적인 범위 삭제
            let predicate = #Predicate<CandleDataModel> { candle in
                candle.market == market &&
                candle.timestamp >= startDate &&
                candle.timestamp <= endDate
            }
            
            let descriptor = FetchDescriptor<CandleDataModel>(predicate: predicate)
            let targetCandles = try context.fetch(descriptor)
            
            for candle in targetCandles {
                context.delete(candle)
            }
            
            try context.save()
            print("🗑️ [DELETE] Deleted \(targetCandles.count) items for \(market) from \(startDate) to \(endDate)")
            return true
            
        } catch {
            print("❌ [ERROR] Failed to delete data for \(market): \(error)")
            errorMessage = "데이터 삭제 실패: \(error.localizedDescription)"
            return false
        }
    }
    
    /// 전체 데이터 삭제
    func deleteAllData() async -> Bool {
        guard let container = modelContainer else { return false }
        
        do {
            let context = ModelContext(container)
            let allCandles = try context.fetch(FetchDescriptor<CandleDataModel>())
            
            for candle in allCandles {
                context.delete(candle)
            }
            
            try context.save()
            print("🗑️ [DELETE] Deleted all candle data (\(allCandles.count) items)")
            return true
            
        } catch {
            print("❌ [ERROR] Failed to delete all data: \(error)")
            errorMessage = "전체 데이터 삭제 실패: \(error.localizedDescription)"
            return false
        }
    }
    
    /// 특정 개수만큼 오래된 데이터 삭제
    @MainActor
    func deleteOldestData(for market: String, count: Int) async -> Bool {
        guard let container = modelContainer else { return false }
        
        do {
            let context = ModelContext(container)
            
            // SwiftData Predicate와 정렬, 제한을 사용한 효율적인 쿼리
            let predicate = #Predicate<CandleDataModel> { candle in
                candle.market == market
            }
            
            var descriptor = FetchDescriptor<CandleDataModel>(predicate: predicate)
            descriptor.sortBy = [SortDescriptor(\.timestamp, order: .forward)]
            descriptor.fetchLimit = count
            
            let candlesToDelete = try context.fetch(descriptor)
            
            for candle in candlesToDelete {
                context.delete(candle)
            }
            
            try context.save()
            print("🗑️ [DELETE] Deleted \(candlesToDelete.count) oldest items for \(market)")
            return true
            
        } catch {
            print("❌ [ERROR] Failed to delete oldest data for \(market): \(error)")
            errorMessage = "오래된 데이터 삭제 실패: \(error.localizedDescription)"
            return false
        }
    }
}

// MARK: - Task Extension for Sleep
extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
