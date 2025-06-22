//
//  BithumbAPI.swift
//  AITrading
//
//  Created by Jin Salon on 6/18/25.
//

import Foundation
import Alamofire
import Combine

/// Bithumb API 클라이언트
/// 실시간 코인 데이터 및 과거 캔들 데이터를 제공
class BithumbAPI: ObservableObject {
    static let shared = BithumbAPI()
    
    /// Bithumb API 기본 URL
    private let baseURL = "https://api.bithumb.com/v1"
    
    /// API 호출 에러 타입
    enum APIError: Error, @preconcurrency LocalizedError {
        case invalidURL
        case noData
        case invalidResponse
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "잘못된 URL입니다."
            case .noData:
                return "데이터가 없습니다."
            case .invalidResponse:
                return "잘못된 응답입니다."
            case .apiError(let message):
                return "API 오류: \(message)"
            }
        }
    }
    
    private init() {}
    
    /// 모든 코인의 현재 가격 정보를 가져옵니다
    /// - Returns: Coin 배열
    /// - Throws: APIError
    func fetchTicker() async throws -> [Coin] {
        print("🚀 [START] Fetching all coin ticker data from Bithumb...")
        
        let url = "\(baseURL)/market/all"
        
        print("🌐 [REQUEST] Bithumb Ticker API")
        print("📍 URL: \(url)")
        print("🔧 Method: GET")
        
        do {
            let request = AF.request(url, headers: [
                "Accept": "application/json"
            ]).validate()
            
            let data = try await request
                .serializingData()
                .value
            
            // JSON 데이터 출력
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 [JSON DATA] Bithumb Ticker Response:")
                debugPrint(jsonString.prefix(500)) // 처음 500자만 출력
            }
            
            // Bithumb API v1 마켓 코드 응답 파싱
            let response = try JSONDecoder().decode(BithumbTickerResponse.self, from: data)
            
            var coins: [Coin] = []
            
            // 각 마켓 정보를 Coin 모델로 변환 (가격 정보는 임시값 사용)
            for marketInfo in response {
                // 마켓 코드에서 심볼 추출 (예: KRW-BTC -> BTC)
                let marketComponents = marketInfo.market.components(separatedBy: "-")
                guard marketComponents.count == 2,
                      marketComponents[0] == "KRW" else { continue }
                
                let symbol = marketComponents[1]
                
                let coin = Coin(
                    market: marketInfo.market,
                    symbol: symbol,
                    name: marketInfo.koreanName,
                    price: Double.random(in: 1000...100000000), // 임시 가격 (실제로는 ticker API 호출 필요)
                    changePercent: Double.random(in: -10...10), // 임시 변동률
                    mfi: Double.random(in: 20...80), // 임시 값
                    rsi: Double.random(in: 20...80), // 임시 값
                    isFavorite: false
                )
                
                coins.append(coin)
            }
            
            // 주요 코인을 우선 정렬
            let majorCoins = ["BTC", "ETH", "XRP", "ADA", "DOT", "LINK", "LTC", "BCH", "EOS", "TRX"]
            let sortedCoins = coins.sorted { coin1, coin2 in
                let isMajor1 = majorCoins.contains(coin1.symbol)
                let isMajor2 = majorCoins.contains(coin2.symbol)
                
                if isMajor1 && !isMajor2 { return true }
                if !isMajor1 && isMajor2 { return false }
                return coin1.symbol < coin2.symbol
            }
            
            print("🎉 [COMPLETE] Successfully fetched \(sortedCoins.count) coins from Bithumb")
            print("🪙 Final coins: \(sortedCoins.prefix(10).map { $0.symbol })")
            
            return sortedCoins
            
        } catch {
            print("❌ [ERROR] Bithumb API Failed")
            print("💥 Error: \(error)")
            throw APIError.invalidResponse
        }
    }
    
    /// Bithumb API를 위한 단순한 마켓 목록 반환 (사용하지 않음)
    private func fetchMarkets() async throws -> [String] {
        // Bithumb API는 ALL_KRW로 모든 데이터를 한 번에 가져오므로 이 함수는 사용하지 않음
        return []
    }
    
    /// 특정 마켓의 현재가 정보를 가져옵니다
    /// - Parameter market: 마켓 코드 (예: "KRW-BTC")
    /// - Returns: 현재가 정보
    /// - Throws: APIError
    private func fetchTickerForMarket(market: String) async throws -> TickerInfo {
        let url = "\(baseURL)/ticker"
        let parameters: [String: String] = ["markets": market]
        
        print("🌐 [REQUEST] Ticker API for \(market)")
        print("📍 URL: \(url)")
        print("🔧 Method: GET")
        print("📋 Parameters: \(parameters)")
        print("📦 Headers: Content-Type: application/json")
        print("⏰ Timestamp: \(Date())")
        
        do {
            let request = AF.request(url, parameters: parameters)
                .validate()
            
            // Request 디버그 출력
            debugPrint("📤 REQUEST:", request)
            print("🎯 Expected Response: Array of TickerInfo objects")
            print("📝 Expected Fields: market, trade_price, change_rate, etc.")
            
            let data = try await request
                .serializingData()
                .value
            
            // JSON 데이터 출력
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 [JSON DATA] Ticker Response for \(market):")
                debugPrint(jsonString)
            }
            
            let response = try JSONDecoder().decode([TickerInfo].self, from: data)
            
            print("✅ [RESPONSE] Ticker API Success for \(market)")
            print("📊 Response count: \(response.count)")
            print("⏱️ Response time: \(Date())")
            
            guard let tickerInfo = response.first else {
                print("❌ [ERROR] No ticker data found for \(market)")
                throw APIError.noData
            }
            
            print("💰 Current Price: \(tickerInfo.tradePrice) KRW")
            print("📈 Change: \(tickerInfo.change) (\(String(format: "%.2f", tickerInfo.changeRate * 100))%)")
            print("📊 24H Volume: \(tickerInfo.accTradeVolume24h)")
            print("🔄 Price Range: \(tickerInfo.lowPrice) ~ \(tickerInfo.highPrice)")
            print("⏰ Timestamp: \(tickerInfo.timestamp)")
            
            return tickerInfo
            
        } catch {
            print("❌ [ERROR] Ticker API Failed for \(market)")
            print("💥 Error: \(error)")
            print("🔧 API Endpoint: \(url)")
            print("📋 Parameters: \(parameters)")
            print("📦 Expected Response: Array of TickerInfo")
            print("⏰ Error time: \(Date())")
            if let afError = error as? AFError {
                print("🔍 AFError details: \(afError.localizedDescription)")
                print("🌐 Possible causes: Invalid market code, Network error, Server maintenance")
                switch afError {
                case .responseValidationFailed(let reason):
                    print("📄 Validation failed: \(reason)")
                    print("💡 Suggestion: Check if market '\(market)' exists on Bithumb")
                case .responseSerializationFailed(let reason):
                    print("📄 Serialization failed: \(reason)")
                    print("💡 Suggestion: Check if response structure matches TickerInfo model")
                default:
                    print("📄 Other AFError: \(afError)")
                }
            }
            throw APIError.invalidResponse
        }
    }
    
    /// 특정 코인의 캔들스틱 데이터를 가져옵니다
    /// - Parameters:
    ///   - market: 마켓 코드 (예: "KRW-BTC")
    ///   - timeframe: 시간 단위 (1, 3, 5, 10, 15, 30, 60, 240분)
    /// - Returns: Candle 배열
    /// - Throws: APIError
    func fetchCandlestick(market: String, timeframe: String) async throws -> [Candle] {
        // timeframe을 분 단위로 변환
        let minutes = convertTimeframeToMinutes(timeframe)
        let url = "\(baseURL)/candles/minutes/\(minutes)"
        let parameters: [String: String] = [
            "market": market,
            "count": "200" // 최대 200개
        ]
        
        print("🌐 [REQUEST] Candlestick API for \(market)")
        print("📍 URL: \(url)")
        print("🔧 Method: GET")
        print("📋 Parameters: \(parameters)")
        print("⏰ Timeframe: \(timeframe) -> \(minutes) minutes")
        print("📦 Headers: Content-Type: application/json")
        print("⏰ Timestamp: \(Date())")
        
        do {
            let request = AF.request(url, parameters: parameters)
                .validate()
            
            // Request 디버그 출력
            debugPrint("📤 REQUEST:", request)
            print("🎯 Expected Response: Array of CandleData objects")
            print("📝 Expected Fields: market, candle_date_time_kst, opening_price, trade_price, etc.")
            print("📊 Max Candles: 200")
            
            let data = try await request
                .serializingData()
                .value
            
            // JSON 데이터 출력
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 [JSON DATA] Candlestick Response for \(market):")
                debugPrint(jsonString)
            }
            
            let response = try JSONDecoder().decode([CandleData].self, from: data)
            
            print("✅ [RESPONSE] Candlestick API Success for \(market)")
            print("📊 Candle count: \(response.count)")
            print("⏱️ Response time: \(Date())")
            
            var candles: [Candle] = []
            
            for candleData in response {
                let candle = Candle(
                    timestamp: candleData.candleDateTimeKst,
                    open: candleData.openingPrice,
                    high: candleData.highPrice,
                    low: candleData.lowPrice,
                    close: candleData.tradePrice,
                    volume: candleData.candleAccTradeVolume
                )
                
                candles.append(candle)
            }
            
            // 시간순 정렬 (오래된 것부터)
            let sortedCandles = candles.sorted { $0.timestamp < $1.timestamp }
            
            if let first = sortedCandles.first, let last = sortedCandles.last {
                print("📅 Date range: \(first.timestamp) ~ \(last.timestamp)")
                print("💰 Current Price: \(last.close) KRW")
                print("📈 Price change: \(last.close - first.close) (\(String(format: "%.2f", ((last.close - first.close) / first.close) * 100))%)")
                print("📊 Volume range: \(sortedCandles.map { $0.volume }.min() ?? 0) ~ \(sortedCandles.map { $0.volume }.max() ?? 0)")
                print("⏰ Candle interval: \(minutes) minutes")
            }
            
            return sortedCandles
            
        } catch {
            print("❌ [ERROR] Candlestick API Failed for \(market)")
            print("💥 Error: \(error)")
            if let afError = error as? AFError {
                print("🔍 AFError details: \(afError.localizedDescription)")
                switch afError {
                case .responseValidationFailed(let reason):
                    print("📄 Validation failed: \(reason)")
                case .responseSerializationFailed(let reason):
                    print("📄 Serialization failed: \(reason)")
                default:
                    print("📄 Other AFError: \(afError)")
                }
            }
            throw APIError.invalidResponse
        }
    }
    
    /// 시간 단위를 분 단위로 변환합니다
    /// - Parameter timeframe: 시간 단위 문자열
    /// - Returns: 분 단위 정수
    private func convertTimeframeToMinutes(_ timeframe: String) -> Int {
        switch timeframe.lowercased() {
        case "1m": return 1
        case "3m": return 3
        case "5m": return 5
        case "10m": return 10
        case "15m": return 15
        case "30m": return 30
        case "1h": return 60
        case "4h": return 240
        default: return 60 // 기본값: 1시간
        }
    }
    
    /// 심볼에 대한 코인 이름을 반환합니다
    /// - Parameter symbol: 코인 심볼
    /// - Returns: 코인 이름
    private func getCoinName(for symbol: String) -> String {
        let coinNames: [String: String] = [
            "BTC": "Bitcoin",
            "ETH": "Ethereum", 
            "XRP": "Ripple",
            "ADA": "Cardano",
            "DOT": "Polkadot",
            "LINK": "Chainlink",
            "LTC": "Litecoin",
            "BCH": "Bitcoin Cash",
            "EOS": "EOS",
            "TRX": "TRON",
            "BNB": "Binance Coin",
            "SOL": "Solana",
            "MATIC": "Polygon",
            "AVAX": "Avalanche",
            "ATOM": "Cosmos",
            "NEAR": "NEAR Protocol",
            "ALGO": "Algorand",
            "VET": "VeChain",
            "ICP": "Internet Computer",
            "FIL": "Filecoin",
            "SAND": "The Sandbox",
            "MANA": "Decentraland",
            "APT": "Aptos",
            "STX": "Stacks",
            "GRT": "The Graph",
            "CRO": "Cronos",
            "LDO": "Lido DAO",
            "OKB": "OKB",
            "UNI": "Uniswap",
            "DOGE": "Dogecoin"
        ]
        
        return coinNames[symbol] ?? symbol
    }
}
