//
//  ContentView.swift
//  WordLeZ
//
//  Created by 周源坤 on 10/6/24.
//

import SwiftUI

struct LetterModel: Hashable, Identifiable {
    let id = UUID()
    
    let letter: Character
    let bgColor: Color
    let contentColor: Color
}

@Observable
class GameLogic {
    var rows: Int
    var cols: Int
    var ans: String = ""
    
    var keyboardHint: [LetterModel] = []
    
    var inputs: [LetterModel] = []
    
    var alphebet: [Character: Int] = [:]
    
    var oneRowFull: Bool = false
    
    var letterInputDisable: Bool {
        oneRowFull || gameOver
    }
    var deleteDisable: Bool {
        currentCol == 0 || gameOver
    }
    var submitDisable: Bool {
        !oneRowFull || gameOver
    }
    
    var gameOver: Bool = false
    var gameWin: Bool = false
    var gameOverString: String = ""
    
    var currentPos: Int = 0
    
    var currentRow: Int {
        currentPos / cols
    }
    
    var currentCol: Int {
        currentPos % cols
    }
    
    var currentModel: LetterModel {
        return inputs[currentPos]
    }
    
    var allCount: Int {
        rows * cols
    }
    
    init() {
        rows = 6
        cols = 3
        self.initGame()
    }
    
    func initGame() {
        self.oneRowFull = false
        self.gameWin = false
        self.gameOver = false
        self.currentPos = 0
        self.alphebet = [:]
        self.keyboardHint = []
        self.inputs = []
        
        let demo = try! String(contentsOfFile: Bundle.main.path(forResource: "words", ofType: "txt")!, encoding: .utf8).components(separatedBy: ["\n"])
        let targetWords = demo.filter { $0.count >= 3 && $0.count <= 7 }
        ans = targetWords.randomElement()!.uppercased()
        for char in ans {
            alphebet[char] = (alphebet[char] ?? 0) + 1
        }
        
        self.rows = 6
        self.cols = ans.count
        for _ in 0..<allCount {
            self.inputs.append(LetterModel(letter: Character(UnicodeScalar(32)), bgColor: .white, contentColor: .white))
        }
        
        for i in 0..<26 {
            self.keyboardHint.append(LetterModel(letter: Character(UnicodeScalar(65+i)!), bgColor: .teal, contentColor: .black))
        }
    }
    
    
    func receiveLetter(letter: Character) {
        if currentPos >= rows * cols { return } //Game finish
        if currentCol == cols-1 && oneRowFull {
            //row is full, submit first
            return
        }
        inputs[currentPos] = LetterModel(letter: letter, bgColor: .white, contentColor: .black)
        if currentCol == cols-1 {
            //row is full, submit hint
            oneRowFull = true
        } else {
            currentPos += 1
        }
    }
    
    func processRow() {
        if !oneRowFull { return }
        let letters = inputs[currentRow*cols..<(currentRow+1)*cols].map { $0.letter }
        var editAlphabet = alphebet
        var rightCnt: Int = 0
        for (colIndex, monoLetter) in letters.enumerated() {
            if let letterCnt = editAlphabet[monoLetter], letterCnt != 0 {
                editAlphabet[monoLetter] = letterCnt - 1
                if ans[colIndex] == monoLetter {
                    inputs[currentRow*cols+colIndex] = LetterModel(letter: monoLetter, bgColor: .green, contentColor: .white)
                    rightCnt += 1
                    keyboardHint[Int(monoLetter.asciiValue!)-65] = LetterModel(letter: monoLetter, bgColor: .green, contentColor: .white)
                } else {
                    inputs[currentRow*cols+colIndex] = LetterModel(letter: monoLetter, bgColor: .yellow, contentColor: .white)
                    if(keyboardHint[Int(monoLetter.asciiValue!)-65].bgColor != .green) {
                        keyboardHint[Int(monoLetter.asciiValue!)-65] = LetterModel(letter: monoLetter, bgColor: .yellow, contentColor: .white)
                    }
                }
            } else {
                inputs[currentRow*cols+colIndex] = LetterModel(letter: monoLetter, bgColor: .gray, contentColor: .white)
                if(keyboardHint[Int(monoLetter.asciiValue!)-65].bgColor == .teal) {
                    keyboardHint[Int(monoLetter.asciiValue!)-65] = LetterModel(letter: monoLetter, bgColor: .gray, contentColor: .black)
                }
            }
        }
        if rightCnt == letters.count {
            gameOver(win: true)
        } else {
            currentPos += 1
            if currentRow == rows { gameOver(win: false) }
            oneRowFull = false
        }
    }
    
    func gameOver(win: Bool) {
        gameOver = true
        gameWin = win
        gameOverString = win ? "WIN" : "FAIL"
    }
    
    func deleteLetter() {
        if oneRowFull {
            oneRowFull = false
        } else {
            if currentCol != 0 { currentPos -= 1 }
            
        }
        inputs[currentPos] = LetterModel(letter: Character(UnicodeScalar(32)), bgColor: .white, contentColor: .white)
        
    }
}

struct ContentView: View {
    @Environment(GameLogic.self) private var gameLogic
    @State var cheat: Bool = false
    @FocusState private var isFocused: Bool

    var keyboardLetterSpacing: CGFloat {
        return 5
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                InputGridView()
                    .onTapGesture {
                        isFocused = true
                    }
        
                Spacer()
                if cheat {
                    Text(gameLogic.ans)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                    ForEach(gameLogic.keyboardHint, id:\.self) { letterModel in
                        Button(action: {
                            gameLogic.receiveLetter(letter: letterModel.letter)
                        }, label: {
                            LetterCard(letter: letterModel.letter, bgColor: letterModel.bgColor, contentColor: letterModel.contentColor)
                        })
                        .buttonStyle(.plain)
                        .disabled(gameLogic.letterInputDisable)
                    }
                }
                HStack {
                    Spacer()
                    Button(action: {
                        gameLogic.initGame()
                    }, label: {
                        ImageCard(systemName: "arrow.counterclockwise", color: .yellow)
                    })
                    .buttonStyle(.plain)
                    
                    Spacer()
                    Button(action: {
                        gameLogic.deleteLetter()
                    }, label: {
                        ImageCard(systemName: "delete.left", color: .red)
                    })
                    .buttonStyle(.plain)
                    .disabled(gameLogic.deleteDisable)
                    Spacer()
                    Button(action: {
                        gameLogic.processRow()
                    }, label: {
                        ImageCard(systemName: "return", color: .green)
                            .phaseAnimator(gameLogic.submitDisable ? [1,1] : [1,1.1]) { view, phase in
                                view.scaleEffect(CGSize(width: phase, height: phase))
                            }
                    })
                    .buttonStyle(.plain)
                    .disabled(gameLogic.submitDisable)
                    .alert(gameLogic.gameOverString, isPresented: Binding(get: { gameLogic.gameOver }, set: {_ in
                    }), actions: {
                        Button(action: {
                            gameLogic.initGame()
                        }, label: {
                            if gameLogic.gameWin {
                                Text("OK")
                            } else {
                                Text("Ans: \(gameLogic.ans)")
                            }
                        })
                    })
                    Spacer()
                    
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color.init(hexCode: 0xBDE0FE))
            .navigationTitle(Text("WordLeZ"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar(content: {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle(isOn: $cheat, label: {Text("Cheating")})
                }
                #elseif os(macOS)
                ToolbarItem(placement: .navigation) {
                    Toggle(isOn: $cheat, label: {Text("Cheating")})
                }
                #endif
            })
            .focusable()
            .focused($isFocused)
            .onKeyPress { press in
                guard let character = press.characters.uppercased().first else {
                    return .ignored
                }
                if character.isLetter {
                    gameLogic.receiveLetter(letter: character)
                    return .handled
                } else if character.asciiValue == 8 || character.asciiValue == 127 {
                    gameLogic.deleteLetter()
                    return .handled
                } else if character.asciiValue == 13  {
                    gameLogic.processRow()
                    return .handled
                } else {
                    return .ignored
                }
            }
            .onAppear {
                isFocused = true
            }
            .onTapGesture {
                isFocused = true
            }
        }
        
        
    }
}

struct InputGridView: View {
    @Environment(GameLogic.self) private var gameLogic
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: gameLogic.cols)) {
            ForEach(gameLogic.inputs) { letterModel in
                let selected = (gameLogic.currentPos < gameLogic.allCount && gameLogic.currentModel == letterModel)
                LetterCard(letter: letterModel.letter, bgColor: letterModel.bgColor, contentColor: letterModel.contentColor)
                    .phaseAnimator(!gameLogic.oneRowFull && selected ? [1,1.1] : [1,1]) { view, phase in
                        view.scaleEffect(CGSize(width: phase, height: phase))
                    }
            }
        }
    }
}

struct ImageCard: View {
    let systemName: String
    let color: Color
    
    var body: some View {
        Image(systemName: systemName)
            .foregroundColor(.white)
            .font(.title)
            .bold()
            .frame(width: 96, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(color)
            )
    }
}

struct LetterCard: View {
    let letter: Character
    let bgColor: Color
    let contentColor: Color
    
    var body: some View {
        Text(letter.uppercased())
            .foregroundStyle(contentColor)
            .font(.title)
            .bold()
            .frame(width: 48, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(bgColor)
            )
    }
}

struct CharacterCard: View {
    var charater: Character = "X"
    var selected: Bool = false
    
    var body: some View {
        VStack {
            Text(charater.uppercased())
                .font(.largeTitle)
        }
        .frame(width: 50, height: 50)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(lineWidth: 2)
                .foregroundColor(selected ? .orange : .black)
                .phaseAnimator(selected ? [1,1.1] : [1,1]) { view, phase in
                    view.scaleEffect(CGSize(width: phase, height: phase))
                }
            )
    }
}

#Preview {
    var gameLogic = GameLogic()
    ContentView()
        .environment(gameLogic)
}

#if os(iOS)
extension UIColor {
    convenience init(hexCode: UInt, enableAlpha: Bool = false) {
        if !enableAlpha {
            let red = CGFloat((hexCode & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((hexCode & 0x00FF00) >> 8) / 255.0
            let blue = CGFloat(hexCode & 0x0000FF) / 255.0
            self.init(red: red, green: green, blue: blue, alpha:1.0)
        } else {
            let red = CGFloat((hexCode & 0xFF000000) >> 24) / 255.0
            let green = CGFloat((hexCode & 0x00FF0000) >> 16) / 255.0
            let blue = CGFloat((hexCode & 0x0000FF00) >> 8) / 255.0
            let alpha = CGFloat(hexCode & 0x000000FF) / 255.0
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        }
    }
}
#endif

#if os(macOS)
extension NSColor {
    convenience init(hexCode: UInt, enableAlpha: Bool = false) {
        if !enableAlpha {
            let red = CGFloat((hexCode & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((hexCode & 0x00FF00) >> 8) / 255.0
            let blue = CGFloat(hexCode & 0x0000FF) / 255.0
            self.init(red: red, green: green, blue: blue, alpha:1.0)
        } else {
            let red = CGFloat((hexCode & 0xFF000000) >> 24) / 255.0
            let green = CGFloat((hexCode & 0x00FF0000) >> 16) / 255.0
            let blue = CGFloat((hexCode & 0x0000FF00) >> 8) / 255.0
            let alpha = CGFloat(hexCode & 0x000000FF) / 255.0
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        }
    }
}
#endif

extension Color {
    #if os(iOS)
    init(hexCode: UInt, enableAlpha: Bool = false) {
        self.init(uiColor: UIColor.init(hexCode: hexCode, enableAlpha: enableAlpha))
    }
    #endif
    
    #if os(macOS)
    init(hexCode: UInt, enableAlpha: Bool = false) {
        self.init(nsColor: NSColor.init(hexCode: hexCode, enableAlpha: enableAlpha))
    }
    #endif
}

extension StringProtocol {
    subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
}
