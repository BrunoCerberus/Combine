import SwiftUI
import Combine
import Foundation

struct MobileResponse: Codable, Equatable {
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

func fetchMovies() -> AnyPublisher<MobileResponse, Error> {
    let url = URL(string: "https://api.themoviedb.org/3/movie/upcoming?api_key=123")!
    
    return URLSession
        .shared
        .dataTaskPublisher(for: url)
        .map(\.data)
        .decode(type: MobileResponse.self, decoder: JSONDecoder())
        .eraseToAnyPublisher()
}

final class MovieViewModel: ObservableObject {
    @Published var movies: [MobileResponse.Movie] = []
    
    var cancellables = Set<AnyCancellable>()
    
    func fetchData() {
        fetchMovies()
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
