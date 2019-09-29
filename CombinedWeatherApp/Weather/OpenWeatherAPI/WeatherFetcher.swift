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
  static let key = ""
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


protocol WeatherFetchable: class {
  static var endpoint: String {get}
  var session: URLSession {get}
  associatedtype JSONDecoded: Decodable
  var data: JSONDecoded? {get set}
  var cancellable: AnyCancellable? {get set}
  func request(_ city: String) -> AnyPublisher<JSONDecoded, WeatherError>
  func load(_ city: String)
}

extension WeatherFetchable {
  var session: URLSession {
    URLSession.shared
  }
  func request(_ city: String) -> AnyPublisher<JSONDecoded, WeatherError> {
    forecast(with: OpenWeatherAPI.makeComponents(Self.endpoint, city))
  }
  func load(_ city: String) {
    cancellable = request(city)
    .receive(on: DispatchQueue.main)
    .sink(
      receiveCompletion: { [weak self] value in
        switch value {
        case .failure:
          self?.data = nil
        case .finished:
          break
        }
      },
      receiveValue: { [weak self] forecast in
        self?.data = forecast
    })
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
  var data: WeeklyForecastResponse? = nil {
    didSet {
      list = data?.list ?? []
    }
  }
  @Published var list = [DailyWeatherRow]()
  var cancellable: AnyCancellable?

}

final class CurForecast: WeatherFetchable, ObservableObject {
  static var endpoint: String {
    "/weather"
  }
  @Published var data: CurrentWeatherRow? = nil
  var cancellable: AnyCancellable?
}
