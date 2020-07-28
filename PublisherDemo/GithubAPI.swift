//
//  GithubAPI.swift
//  PublisherDemo
//
//  Created by MC on 2020/7/27.
//

import Combine
import Foundation

enum APIFailureCondition: Error {
    case invalidServerResponse
}

struct GithubAPIUser: Decodable {
    let login: String
    let public_repos: Int
    let avatar_url: String
}

struct GithubAPI {
    static let networkActivityPublisher = PassthroughSubject<Bool, Never>()

    static func retrieveGithubUser(username: String) -> AnyPublisher<[GithubAPIUser], Never> {
        if username.count < 3 {
            return Just([]).eraseToAnyPublisher()
        }
        
        let assembledURL = String("https://api.github.com/users/\(username)")

        guard let url = URL(string: assembledURL) else {
            return Just([]).eraseToAnyPublisher()
        }

        let publisher = URLSession.shared.dataTaskPublisher(for: url)
            .handleEvents { _ in
                networkActivityPublisher.send(true)
            } receiveCompletion: { _ in
                networkActivityPublisher.send(false)
            } receiveCancel: {
                networkActivityPublisher.send(false)
            }
            .tryMap { (data, response) -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw APIFailureCondition.invalidServerResponse
                }
                return data
            }
            .decode(type: GithubAPIUser.self, decoder: JSONDecoder())
            .map {
                [$0]
            }
            .replaceError(with: [])
            .eraseToAnyPublisher()

        return publisher
    }
}
