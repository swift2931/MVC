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

import Foundation
import Combine

struct OpenWeatherAPI {
  static let scheme = "https"
  static let host = "api.openweathermap.org"
  static let path = "/data/2.5"
  static let key = "your api key"
}

extension OpenWeatherAPI {
  static func makeComponents(_ endpoint: String, _ city: String) -> URLComponents {
    var components = URLComponents()
    components.scheme = OpenWeatherAPI.scheme
    components.host = OpenWeatherAPI.host
    components.path = OpenWeatherAPI.path + endpoint
    
    components.queryItems = [
      URLQueryItem(name: "q", value: city),
      URLQueryItem(name: "mode", value: "json"),
      URLQueryItem(name: "units", value: "metric"),
      URLQueryItem(name: "APPID", value: OpenWeatherAPI.key)
    ]
    return components
  }
}

protocol WeatherFetchable {
  static var endpoint: String {get}
  var session: URLSession {get}
  associatedtype ResourceType
  var data: ResourceType {get set}
  var cancellable: AnyCancellable? {get set}
  func load(_ city: String)
}

extension WeatherFetchable {
  var session: URLSession {
    URLSession.shared
  }
  func forecast<T>(
    with components: URLComponents
  ) -> AnyPublisher<T, WeatherError> where T: Decodable {
    guard let url = components.url else {
      let error = WeatherError.network(description: "Couldn't create URL")
      return Fail(error: error).eraseToAnyPublisher()
    }
    return session.dataTaskPublisher(for: URLRequest(url: url))
      .mapError { error in
        .network(description: error.localizedDescription)
      }
      .flatMap(maxPublishers: .max(1)) { pair in
        decode(pair.data)
      }
      .eraseToAnyPublisher()
  }
}

final class WeeklyForecast: WeatherFetchable, ObservableObject {
  static var endpoint: String {
    "/forecast"
  }
  @Published var data = [DailyWeatherRowViewModel]()
  var cancellable: AnyCancellable?
  func load(_ city: String) {
    let p: AnyPublisher<WeeklyForecastResponse, WeatherError> = forecast(with: OpenWeatherAPI.makeComponents(WeeklyForecast.endpoint, city))
    cancellable = p.map { response in
      response.list.map(DailyWeatherRowViewModel.init)
    }
    .map(Array.removeDuplicates)
    .receive(on: DispatchQueue.main)
    .sink(
      receiveCompletion: { [weak self] value in
        switch value {
        case .failure:
          self?.data = []
        case .finished:
          break
        }
      },
      receiveValue: { [weak self] forecast in
        self?.data = forecast
    })
  }
}

final class CurForecast: WeatherFetchable, ObservableObject {
  static var endpoint: String {
    "/weather"
  }
  @Published var data: CurrentWeatherRowViewModel? = nil
  var cancellable: AnyCancellable?
  func load(_ city: String) {
    let p: AnyPublisher<CurrentWeatherForecastResponse, WeatherError> = forecast(with: OpenWeatherAPI.makeComponents(CurForecast.endpoint, city))
    cancellable = p.map(CurrentWeatherRowViewModel.init)
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { value in
        switch value {
        case .failure:
          self.data = nil
        case .finished:
          break
        }
      }, receiveValue: { weather in
          self.data = weather
      })
  }
}
