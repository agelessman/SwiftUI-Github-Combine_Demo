//
//  ContentView.swift
//  PublisherDemo
//
//  Created by MC on 2020/7/27.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GithubViewModel()
    
    var body: some View {
        VStack {
            HStack {
                Text("用户名:")
                TextField("输入用户名：", text: $viewModel.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                if viewModel.loading {
                    ActivityRep()
                        .padding(.vertical, 20)
                 }
            }
            
            VStack {
                Text("\(getUsername())")
                    .font(.title)
                
                Text("仓库数量： \(viewModel.repositoryCount)")
            }
            .padding(.vertical, 30)
            .padding(.horizontal, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
            
            if (viewModel.img != nil) {
                Image(uiImage: viewModel.img!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 300)
            }
        }
    }
    
    func getUsername() -> String {
        if let firstUser = self.viewModel.githubUserData.first {
            return firstUser.login
        }
        return ""
    }
}

struct ActivityRep: UIViewRepresentable {
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        return UIActivityIndicatorView()
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        uiView.startAnimating()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
