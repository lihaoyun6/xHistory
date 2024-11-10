//
//  SInfoButton.swift
//  AirBattery
//
//  Created by apple on 2024/10/28.
//

import SwiftUI

struct SForm<Content: View>: View {
    var spacing: CGFloat = 30
    var noSpacer: Bool = false
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(spacing: spacing) {
            content()
            if !noSpacer {
                Spacer().frame(minHeight: 0)
            }
        }
        .padding(.bottom, noSpacer ? 0 : -spacing)
        .padding()
        .frame(maxWidth: .infinity)
        
    }
}

struct SGroupBox<Content: View>: View {
    var label: LocalizedStringKey? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        GroupBox(label: label != nil ? Text(label!).font(.headline) : nil) {
            VStack(spacing: 10) { content() }.padding(5)
        }
    }
}

struct SItem<Content: View>: View {
    var label: LocalizedStringKey? = nil
    var spacing: CGFloat = 8
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        HStack(spacing: spacing) {
            if let label = label { Text(label) }
            Spacer()
            content()
        }.frame(height: 16)
    }
}

struct SDivider: View {
    var body: some View {
        Divider().opacity(0.5)
    }
}

struct SSlider: View {
    var label: LocalizedStringKey? = nil
    @Binding var value: Int
    var range: ClosedRange<Double> = 0...100
    var width: CGFloat = .infinity
    
    var body: some View {
        HStack {
            if let label = label {
                Text(label)
            }
            Spacer()
            Slider(value:
                    Binding(get: { Double(value) },
                            set: { newValue in
                let base: Int = Int(newValue.rounded())
                let modulo: Int = base % 1
                value = base - modulo
            }), in: range).frame(maxWidth: width)
        }.frame(height: 16)
    }
}

struct SInfoButton: View {
    var tips: LocalizedStringKey
    @State var isPresented: Bool = false
    
    var body: some View {
        Button(action: {
            isPresented = true
        }, label: {
            Image(systemName: "info.circle")
                .font(.system(size: 15, weight: .light))
                .opacity(0.5)
        })
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            VStack(alignment: .trailing) {
                GroupBox { Text(tips).padding() }
                Button(action: {
                    isPresented = false
                }, label: {
                    Text("OK").frame(width: 30)
                }).keyboardShortcut(.defaultAction)
            }.padding()
        }
    }
}

struct SButton: View {
    var title: LocalizedStringKey
    var buttonTitle: LocalizedStringKey
    var tips: LocalizedStringKey?
    var action: () -> Void
    
    init(_ title: LocalizedStringKey, buttonTitle: LocalizedStringKey, tips: LocalizedStringKey? = nil, action: @escaping () -> Void) {
        self.title = title
        self.buttonTitle = buttonTitle
        self.tips = tips
        self.action = action
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            Spacer()
            if let tips = tips { SInfoButton(tips: tips) }
            Button(buttonTitle,
                   action: { action() })
        }.frame(height: 16)
    }
}

struct SField: View {
    var title: LocalizedStringKey
    var tips: LocalizedStringKey?
    @Binding var text: String
    
    init(_ title: LocalizedStringKey, tips: LocalizedStringKey? = nil, text: Binding<String>) {
        self.title = title
        self.tips = tips
        self._text = text
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            Spacer()
            if let tips = tips { SInfoButton(tips: tips) }
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 220)
        }
    }
}

struct SPicker<T: Hashable, Content: View, Style: PickerStyle>: View {
    var title: LocalizedStringKey
    @Binding var selection: T
    var style: Style
    var tips: LocalizedStringKey?
    @ViewBuilder let content: () -> Content
    
    init(_ title: LocalizedStringKey, selection: Binding<T>, style: Style = .menu, tips: LocalizedStringKey? = nil, @ViewBuilder content: @escaping () -> Content) {
            self.title = title
            self._selection = selection
            self.style = style
            self.tips = tips
            self.content = content
        }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if let tips = tips { SInfoButton(tips: tips) }
            Picker("", selection: $selection) { content() }
                .fixedSize()
                .pickerStyle(style)
                .buttonStyle(.borderless)
        }.frame(height: 16)
    }
}

struct SToggle: View {
    var title: LocalizedStringKey
    @Binding var isOn: Bool
    var tips: LocalizedStringKey?
    
    init(_ title: LocalizedStringKey, isOn: Binding<Bool>, tips: LocalizedStringKey? = nil) {
        self.title = title
        self._isOn = isOn
        self.tips = tips
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if let tips = tips { SInfoButton(tips: tips) }
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .scaleEffect(0.7)
                .frame(width: 32)
        }.frame(height: 16)
    }
}

struct SSteper: View {
    var title: LocalizedStringKey
    @Binding var value: Int
    var min: Int
    var max: Int
    var width: CGFloat
    var tips: LocalizedStringKey?
    
    init(_ title: LocalizedStringKey, value: Binding<Int>, min: Int = 0, max: Int = 100, width: CGFloat = 45, tips: LocalizedStringKey? = nil) {
        self.title = title
        self._value = value
        self.tips = tips
        self.width = width
        self.min = min
        self.max = max
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(title)
            Spacer()
            if let tips = tips { SInfoButton(tips: tips) }
            TextField("", value: $value, formatter: NumberFormatter())
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: width)
                .onChange(of: value) { newValue in
                    if newValue > max { value = max }
                    if newValue < min { value = min }
                }
            Stepper("", value: $value)
                .padding(.leading, -6)
        }.frame(height: 16)
    }
}
