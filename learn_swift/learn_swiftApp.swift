//
//  learn_swiftApp.swift
//  learn_swift
//
//  Created by mackbool on 03/04/25.
//

import SwiftUI
import NavigationBackport
import Combine

@main
struct learn_swiftApp: App {
    var body: some Scene {
        WindowGroup {
            MyView()
        }
    }
}

struct MyView: View {
    @StateObject private var myAppRouter = MyAppRouter()
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor.clear
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $myAppRouter.selectedTab) {
            NBNavigationStack(path: $myAppRouter.pathFirst) {
                FirstView().nbNavigationDestination(for: Presentable.self) {value in
                    value
                }
            }
            .tabItem {
                Label("FirstView", systemImage: "house.fill")
            }.tag(TabEnum.first)
            NBNavigationStack(path: $myAppRouter.pathSecond) {
                SecondView().nbNavigationDestination(for: Presentable.self) {value in
                    value
                }
            }.tabItem {
                Label("SecondView", systemImage: "house.fill")
            }.tag(TabEnum.second)
        }.environmentObject(myAppRouter)
    }
}

#Preview {
    MyView()
}


struct FirstView: IdentifiableView {
    var viewID: String = "first"
    
    @EnvironmentObject var navigator: MyAppRouter
    
    var body: some View {
        VStack{
            Button(action: {
                navigator.push(FirstDetailView())
            }){
                Text("FirstView")
            }
        }
        .navigationTitle("FirstView")
    }
}

struct FirstDetailView: IdentifiableView {
    var viewID: String = "first-detail"
    
    @EnvironmentObject var navigator: MyAppRouter
    @StateObject private var viewModel = FirstDetailViewModel()
    
    var body: some View {
        Button(action: {
            navigator.pop()
        }) {
            Text("FirstDetailView")
        }
        .navigationTitle("FirstDetailView")
    }
}

struct SecondView: IdentifiableView {
    var viewID: String = "second"
    
    @EnvironmentObject var navigator: MyAppRouter
    
    var body: some View {
        VStack{
            Button(action: {
                navigator.push(SecondDetailView())
            }){
                Text("SecondView")
            }
            
        }
        .navigationTitle("SecondView")
    }
}

struct SecondDetailView: IdentifiableView {
    var viewID: String = "second-detail"
    
    @EnvironmentObject var navigator: MyAppRouter
    
    var body: some View {
        Button(action: {
            navigator.switchTab(tab: .first)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigator.push(FirstDetailView())
            }
        }) {
            Text("SecondDetailView → FirstDetailView")
        }
    }
}


struct Presentable: View {
    let id: String
    let content: AnyView
    
    init<V: IdentifiableView>(_ content: V) {
        self.id = content.viewID
        self.content = AnyView(content)
    }
    
    var body: some View {
        content
    }
}

extension Presentable: Hashable {
    static func == (lhs: Presentable, rhs: Presentable) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

final class FirstDetailViewModel: ObservableObject {
    @Published var count: Int = 0
    
    init() {
        print("FirstDetailViewModel init")
        count += 1
    }
    
    deinit {
        print("FirstDetailViewModel deinit")
        count -= 1
    }
}

class MyAppRouter: ObservableObject {
    @Published var pathFirst: [Presentable] = []
    @Published var pathSecond: [Presentable] = []
    
    @Published var selectedTab: TabEnum = .first
    
    func push(_ view: any IdentifiableView) {
        switch selectedTab {
        case .first:
            let isActive = checkIsActive(view: view, views: pathFirst)
            if isActive {
                break
            }
            pathFirst.append(Presentable(view))
        case .second:
            pathSecond.append(Presentable(view))
        }
    }
    
    func pop() {
        switch selectedTab {
        case .first:
            pathFirst.removeLast()
        case .second:
            pathFirst.removeLast()
        }
    }
    
    func switchTab(tab: TabEnum) {
        selectedTab = tab
    }
    
    private func checkIsActive(view: any IdentifiableView, views: [Presentable]) -> Bool {
        return views.last?.id == view.viewID
    }
}

enum TabEnum {
    case first
    case second
}

protocol IdentifiableView: View {
    var viewID: String { get }
}
