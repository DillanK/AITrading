//
//  CandlestickResponse.swift
//  AITrading
//
//  Created by Jin Salon on 6/20/25.
//

import Foundation

/// Bithumb 캔들스틱 API 응답 구조체
/// `/public/candlestick/{market}/{timeframe}` 엔드포인트 응답
nonisolated struct CandlestickResponse: Decodable {
    /// API 응답 상태 코드
    /// "0000": 성공, 기타: 에러
    let status: String
    
    /// 캔들스틱 데이터 배열
    /// 각 항목은 [timestamp, open, close, high, low, volume] 형태
    let data: [[String]]
    
    /// CodingKeys 정의
    enum CodingKeys: String, @preconcurrency CodingKey {
        case status
        case data
    }
}