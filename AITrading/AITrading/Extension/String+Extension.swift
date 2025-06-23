//
//  String+Extension.swift
//  AITrading
//
//  Created by Jin Salon on 6/23/25.
//

import Foundation

extension String {
    func dateToISO8601(timeZone: String = "Asia/Seoul") -> Date? {
        let convertDateString = self.last == "Z" ? self : self + "Z"
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        dateFormatter.timeZone = .init(identifier: timeZone)
        return dateFormatter.date(from: convertDateString)
    }
}
