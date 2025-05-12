//
//  HomeView.swift
//  SwiftUI-Vocab3000
//
//  Created by Pavee Jeungtanasirikul on 12/5/2568 BE.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Home!")
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
