//
//  BithumbAPI.swift
//  AITrading
//
//  Created by Jin Salon on 6/18/25.
//

import Foundation
import Alamofire
import Combine

class BithumbAPI {
    static let shared = BithumbAPI()
    private let baseURL = "https://api.bithumb.com/public"
    
    func fetchTicker() async throws -> [Coin] {
//        let url = "\(baseURL)/ticker/ALL"
//        let request = AF.request(url)
//        let dataTask = request.serializingDecodable(TickerResponse.self)
//        
//        switch await dataTask.result {
//        case .success(let value):
//            guard let response = await dataTask.response.response, (200...299).contains(response.statusCode) else {
//                throw AFError.responseValidationFailed(reason: .missingContentType(acceptableContentTypes: [""]))
//            }
//            
//            return value
//        case .failure(let error):
//            throw error
//        }
        
//        guard response.status == "0000" else {
//            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "API 상태 오류"])
//        }
//        
//        var coins: [Coin] = []
//        for (market, data) in response.data {
//            if let price = data.closingPriceDouble,
//               let changePercent = data.fluctateRate24HDouble {
//                let symbol = market.components(separatedBy: "-")[1]
//                let coin = Coin(market: market,
//                              symbol: symbol,
//                              name: symbol,
//                              price: price,
//                              changePercent: changePercent)
//                coins.append(coin)
//            }
//        }
//        return coins
        
        return [.Root(market: "market", symbol: "symbol", name: "name", price: 0, changePercent: 0)]
    }
    
    // WebSocket 연결은 별도 구현 필요
}
