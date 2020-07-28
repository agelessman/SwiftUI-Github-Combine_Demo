//
//  GithubViewModel.swift
//  PublisherDemo
//
//  Created by MC on 2020/7/27.
//

import UIKit
import Combine

class GithubViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var githubUserData: [GithubAPIUser] = []
    @Published var loading: Bool = false
    @Published var repositoryCount: String = ""
    @Published var img: UIImage?
    
    var apiNetworkActivitySubscriber: AnyCancellable?
    var usernameSubscriber: AnyCancellable?
    var repositoryCountSubscriber: AnyCancellable?
    var avatarSubscriber: AnyCancellable?
    
    var myBackgropundQueue: DispatchQueue = DispatchQueue(label: "myBackgropundQueue")
    
    init() {
        /// 设置加载
        apiNetworkActivitySubscriber = GithubAPI.networkActivityPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { (someValue) in
                self.loading = someValue
            })
        
        /// 设置username pipline
        usernameSubscriber = $username
            .throttle(for: 0.5, scheduler: myBackgropundQueue, latest: true)
            .removeDuplicates()
            .print("usernampipeline: ")
            .map { username -> AnyPublisher<[GithubAPIUser], Never> in
                return GithubAPI.retrieveGithubUser(username: username)
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .assign(to: \.githubUserData, on: self)
        
        /// 设置repository count pipline
        repositoryCountSubscriber = $githubUserData
            .print("github user data: ")
            .map { userData -> String in
                if let firstUser = userData.first {
                    return String(firstUser.public_repos)
                }
                return ""
            }
            .receive(on: RunLoop.main)
            .assign(to: \.repositoryCount, on: self)
        
        /// 设置图片
        avatarSubscriber = $githubUserData
            .map { userData -> AnyPublisher<UIImage, Never> in
                guard let firstUser = userData.first else {
                    return Just(UIImage()).eraseToAnyPublisher()
                }
                
                return URLSession.shared.dataTaskPublisher(for: URL(string: firstUser.avatar_url)!)
                    .handleEvents(receiveSubscription: { _ in
                        DispatchQueue.main.async {
                            self.loading = true
                        }
                    }, receiveCompletion: { _ in
                        DispatchQueue.main.async {
                            self.loading = false
                        }
                    }, receiveCancel: {
                        DispatchQueue.main.async {
                            self.loading = false
                        }
                    })
                    .map {
                        $0.data
                    }
                    .map {
                        UIImage(data: $0)!
                    }
                    .subscribe(on: self.myBackgropundQueue)
                    .catch { err in
                        return Just(UIImage())
                    }
                    .eraseToAnyPublisher()
                    
            }
            .switchToLatest()
            .subscribe(on: myBackgropundQueue)
            .receive(on: RunLoop.main)
            .map { image -> UIImage? in
                image
            }
            .assign(to: \.img, on: self)
    }
}
