//
//  ContentView.swift
//  News
//
//  Created by William Finnis on 03/08/2021.
//

import SwiftUI

extension URLSession {
    func decode<T: Decodable>(_ type: T.Type = T.self, from url: URL) async throws -> T {
        let (data, _) = try await data(from: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: data)
    }
}

struct NewsItem: Decodable, Identifiable {
    let id: Int
    let title: String
    let strap: String
    let url: URL
    let main_image: URL
    let published_date: Date
    
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        
        return formatter.localizedString(for: published_date, relativeTo: Date())
    }
}

struct ContentView: View {
    @State var stories = [NewsItem]()
    
    var body: some View {
        NavigationView {
            List(stories) { newsItem in
                Link(destination: newsItem.url) {
                    HStack(alignment: .top) {
                        AsyncImage(url: newsItem.main_image) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 100, height: 100)
                        .cornerRadius(5)
                        
                        VStack(alignment: .leading) {
                            Text(newsItem.title)
                                .font(.headline)
                                .lineLimit(2)
                            Text(newsItem.strap)
                                .font(.subheadline)
                                .lineLimit(2)
                            Text(newsItem.relativeDate)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.black)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("HWS News")
        }
        .task(loadStories)
    }
    
    func loadStories() async {
        do {
            try await withThrowingTaskGroup(of: [NewsItem].self) { group -> Void in
                for i in 1...5 {
                    group.addTask {
                        let url = URL(string: "https://hws.dev/news-\(i).json")!
                        return try await URLSession.shared.decode(from: url)
                    }
                    
                    for try await result in group {
                        stories.append(contentsOf: result)
                    }
                    
                    stories.sort { $0.published_date > $1.published_date }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
