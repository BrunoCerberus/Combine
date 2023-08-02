import SwiftUI
import Combine
import Foundation

let apiKey = ""

struct MovieResponse: Codable, Equatable {
    let movies: [Movie]
        struct Movie: Codable, Equatable {
            let title: String
            let releaseYear: Int
            
            enum CodingKeys: CodingKey {
                case title
                case releaseYear
            }
        }
}

// As AnyPublisher
protocol Service {
    func fetchMovies() -> AnyPublisher<MovieResponse, Error>
}

class MoviesService: Service {
    func fetchMovies() -> AnyPublisher<MovieResponse, Error> {
        let url = URL(string: "https://api.themoviedb.org/3/movie/upcoming?api_key=123")!
        
        return URLSession
            .shared
            .dataTaskPublisher(for: url)
            .map(\.data)
        //        .tryMap { data in
        //            let decoded = try jsonDecoder.decode(MovieResponse.self, from: data)
        //            return decoded
        //        }
            .decode(type: MovieResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

// Mock for test
class MockMoviesService: Service {
    func fetchMovies() -> AnyPublisher<MovieResponse, Error> {
        Just(MovieResponse(movies: []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// As some Publisher
func searchMovies(for query: String) -> some Publisher<MovieResponse, Error> {
    let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    let url = URL(string: "https://api.themoviedb.org/3/search/movie?api_key=\(apiKey)&query=\(encodedQuery!)")!

    return URLSession
        .shared
        .dataTaskPublisher(for: url)
        .map { $0.data }
        .decode(type: MovieResponse.self, decoder: JSONDecoder())
}

final class MovieViewModel: ObservableObject {
    @Published var movies: [MovieResponse.Movie] = []
    
    var cancellables = Set<AnyCancellable>()
    let service: Service
    
    init(service: Service = MoviesService()) {
        self.service = service
    }
    
    func fetchData() {
        service.fetchMovies()
            .map(\.movies)
            .receive(on: DispatchQueue.main)
            .replaceError(with: [])
            .print()
            .assign(to: \.movies, on: self)
            .store(in: &cancellables)
    }
}

let vm = MovieViewModel()
vm.fetchData()
