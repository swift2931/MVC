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

final class Store: ObservableObject {
  @Published var city = ""
  @Published var weekly = WeeklyForecast()
  @Published var curDetail = CurForecast()
  init() {
    _ = $city
      .dropFirst(1)
      .debounce(for: .seconds(0.5), scheduler: DispatchQueue(label: "WeatherViewModel"))
      .sink(receiveValue: weekly.load(_:))
  }
}

struct WeeklyWeatherView: View {
  @EnvironmentObject var store: Store
  var weekList: [DailyWeatherRow] {
    store.weekly.list
  }
  var body: some View {
    NavigationView {
      List {
        searchField
        if weekList.isEmpty {
          emptySection
        } else {
          cityHourlyWeatherSection
          forecastSection
        }
      }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("Weather ⛅️")
    }
  }
}

private extension WeeklyWeatherView {
  var searchField: some View {
    HStack(alignment: .center) {
      TextField("e.g. Cupertino", text: $store.city)
    }
  }

  var forecastSection: some View {
    Section {
      ForEach(weekList, content: {daily in daily})
    }
  }

  var cityHourlyWeatherSection: some View {
    Section {
      NavigationLink(destination: CurrentWeatherView()) {
        VStack(alignment: .leading) {
          Text(store.city)
          Text("Weather today")
            .font(.caption)
            .foregroundColor(.gray)
        }
      }
    }
  }

  var emptySection: some View {
    Section {
      Text("No results")
        .foregroundColor(.gray)
    }
  }
}
