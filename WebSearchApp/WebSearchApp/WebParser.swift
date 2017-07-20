//
//  WebParser.swift
//  WebSearchApp
//
//  Created by Julia Potapenko on 14.07.2017.
//  Copyright © 2017 Julia Potapenko. All rights reserved.
//

import Foundation
import Kanna

class WebParser {
    
    struct Response {
        let title: String
        let found: Int
        let childs: [String]
        let error: String?
    }
    
    let regex = "\\b(?i)(http|https)://([a-z0-9+&@#/%?=~_|!:,.;|]*)\\b"
    
    func parse(searchUrl: String, searchText: String) -> (WebParser.Response) {
        
        guard let url = URL(string: searchUrl) else {
            return (Response(title: "", found: 0, childs: [], error: "Cannot parse URL string."))
        }
        guard let doc = HTML(url: url, encoding: .utf8) else {
            return (Response(title: "", found: 0, childs: [], error: "Cannot parse HTML page."))
        }
        
        let title = doc.title ?? "No Title"
        let childs = parseChilds(doc: doc)
        let found = search(text: searchText, in: doc)
        return Response(title: title, found: found, childs: childs, error: nil)
    }
    
    private func parseChilds(doc: HTMLDocument) -> [String] {
        
        var childUrls: [String] = []
        
        for docLink in doc.xpath("//a | //link") {
            if let link = docLink["href"] {
                if let range = link.range(of: regex, options: .regularExpression) {
                    let result = link.substring(with: range)
                    childUrls.append(result)
                }
            }
        }
        return childUrls
    }
    
    private func search(text: String, in doc: HTMLDocument) -> Int {
        if let docText = doc.text {
            return docText.lowercased().components(separatedBy: text.lowercased()).count - 1
        }
        return 0
    }
}
