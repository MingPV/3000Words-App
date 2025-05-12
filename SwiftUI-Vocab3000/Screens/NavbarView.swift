//
//  NavbarTab.swift
//  SwiftUI-Vocab3000
//
//  Created by Pavee Jeungtanasirikul on 12/5/2568 BE.
//

import SwiftUI

struct NavbarView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }

            VocabListView()
                .tabItem { Label("3000 Words", systemImage: "character.book.closed") }

            AccountView()
                .tabItem { Label("Account", systemImage: "person")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavbarView()
    }
}
