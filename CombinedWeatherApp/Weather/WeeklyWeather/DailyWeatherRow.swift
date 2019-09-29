/// Copyright (c) 2019 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI

extension DailyWeatherRow: View {
  var body: some View {
    HStack {
      VStack {
        Text("\(day)")
        Text("\(month)")
      }
      
      VStack(alignment: .leading) {
        Text("\(title)")
          .font(.body)
        Text("\(fullDescription)")
          .font(.footnote)
      }
        .padding(.leading, 8)

      Spacer()

      Text("\(temperature)°")
        .font(.title)
    }
  }
}

extension DailyWeatherRow: Identifiable {
  var id: String {
    return day + temperature + title
  }
  
  var day: String {
    return dayFormatter.string(from: date)
  }
  
  var month: String {
    return monthFormatter.string(from: date)
  }
  
  var temperature: String {
    return String(format: "%.1f", main.temp)
  }
  
  var title: String {
    guard let title = weather.first?.main.rawValue else { return "" }
    return title
  }
  
  var fullDescription: String {
    guard let description = weather.first?.weatherDescription else { return "" }
    return description
  }
}

// Used to hash on just the day in order to produce a single view model for each
// day when there are multiple items per each day.
extension DailyWeatherRow: Hashable {
  static func == (lhs: DailyWeatherRow, rhs: DailyWeatherRow) -> Bool {
    return lhs.day == rhs.day
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.day)
  }
}
