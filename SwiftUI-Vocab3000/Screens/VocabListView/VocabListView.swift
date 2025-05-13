//
//  VocabListView.swift
//  SwiftUI-Vocab3000
//
//  Created by Pavee Jeungtanasirikul on 12/5/2568 BE.
//

import CoreXLSX
import Foundation
import SwiftUI

struct Vocabulary: Identifiable, Codable {
    let id = UUID()
    let word: String
    let meaning: String
    var isRemembered: Bool = false
}

struct VocabListView: View {
    @State private var words = [Vocabulary]()
    @State private var displayedWords = [Vocabulary]()
    @State private var batchSize = 30
    @State private var showOnlyNotRemembered = false
    @State private var rememberedStates: [String: Bool] = [:] // 👈 สถานะที่โหลดจากเครื่อง

    var filteredWords: [Vocabulary] {
        if showOnlyNotRemembered {
            return displayedWords.filter { !$0.isRemembered }
        } else {
            return displayedWords
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                VStack(spacing: 10) {
                    Text("Vocab List")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)

                    Toggle("Not Remembered", isOn: $showOnlyNotRemembered)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 25)
                        .padding(.top, 10)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                        .frame(maxWidth: .infinity)
                }.overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray), alignment: .bottom
                )

                List {
                    ForEach(filteredWords.indices, id: \.self) { index in
                        let word = filteredWords[index]
                        HStack {
                            Button(action: {
                                if let realIndex = displayedWords.firstIndex(where: { $0.id == word.id }) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        displayedWords[realIndex].isRemembered.toggle()

                                        // 👇 อัปเดตและเซฟลง local storage
                                        rememberedStates[displayedWords[realIndex].word] = displayedWords[realIndex].isRemembered
                                        saveRememberedStates(rememberedStates)
                                    }
                                }
                            }) {
                                Image(systemName: word.isRemembered ? "checkmark" : "circle")
                                    .foregroundColor(word.isRemembered ? .green : .gray)
                                    .animation(nil)
                            }
                            .padding(5)

                            VStack(alignment: .leading) {
                                Text(word.word)
                                    .font(.headline)
                                    .foregroundColor(word.isRemembered ? Color.green.opacity(0.9) : .black)
                                Text(word.meaning)
                                    .font(.subheadline)
                                    .opacity(word.isRemembered ? 0.5 : 1)
                                    .foregroundColor(.gray)
                            }
                            .padding(10)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(word.isRemembered ? Color.green.opacity(0.1) : Color.clear)
                        .transition(.opacity)
                        .onAppear {
                            if index == filteredWords.count - 1 {
                                loadMoreWords()
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .padding([.leading, .trailing], 16)
            .onAppear {
                rememberedStates = loadRememberedStates() // โหลดก่อน
                loadWords() // แล้วค่อยโหลดคำศัพท์
            }
        }
    }

    func loadWords() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let fileURL = Bundle.main.url(forResource: "oxford3000", withExtension: "xlsx") {
                let words = readWordsFromExcel(fileURL: fileURL)

                DispatchQueue.main.async {
                    // 👇 รวมสถานะ remembered ที่บันทึกไว้เข้ากับคำศัพท์
                    self.words = words.map { vocab in
                        var updated = vocab
                        updated.isRemembered = rememberedStates[vocab.word] ?? false
                        return updated
                    }

                    self.displayedWords = Array(self.words.prefix(batchSize))
                }
            } else {
                print("oxford3000.xlsx is not in bundle")
            }
        }
    }

    func loadMoreWords() {
        guard displayedWords.count < words.count else { return }

        let nextBatchEnd = min(displayedWords.count + batchSize, words.count)
        let nextBatch = words[displayedWords.count ..< nextBatchEnd]
        displayedWords.append(contentsOf: nextBatch)
    }
}

func readWordsFromExcel(fileURL: URL) -> [Vocabulary] {
    var vocabList = [Vocabulary]()

    do {
        guard let file = XLSXFile(filepath: fileURL.path) else {
            print("Invalid XLSX file.")
            return vocabList
        }

        guard let sharedStrings = try file.parseSharedStrings() else {
            print("No shared strings found.")
            return vocabList
        }

        let worksheets = try file.parseWorksheetPaths()
        guard let firstWorksheet = worksheets.first else {
            print("No worksheets found.")
            return vocabList
        }

        let worksheet = try file.parseWorksheet(at: firstWorksheet)

        for row in worksheet.data?.rows ?? [] {
            var word = ""
            var meaning = ""

            for cell in row.cells {
                if cell.reference.column.value == "B", let stringValue = cell.stringValue(sharedStrings) {
                    word = stringValue
                }
                if cell.reference.column.value == "C", let stringValue = cell.stringValue(sharedStrings) {
                    meaning = stringValue
                }
            }

            if !word.isEmpty {
                vocabList.append(Vocabulary(word: word, meaning: meaning))
            }
        }

    } catch {
        print("Error reading XLSX file: \(error)")
    }

    return vocabList
}

func saveRememberedStates(_ states: [String: Bool]) {
    if let data = try? JSONEncoder().encode(states) {
        UserDefaults.standard.set(data, forKey: "rememberedStates")
    }
}

func loadRememberedStates() -> [String: Bool] {
    if let data = UserDefaults.standard.data(forKey: "rememberedStates"),
       let states = try? JSONDecoder().decode([String: Bool].self, from: data) {
        return states
    }
    return [:]
}

#Preview {
    VocabListView()
}
