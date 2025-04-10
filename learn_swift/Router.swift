//
//  Router.swift
//  learn_swift
//
//  Created by mackbool on 09/04/25.
//

import SwiftUI
import Combine

// Public protocol for routes
public protocol NavigationRoute: Equatable, Hashable {}

// Identifiable wrapper for routes
public struct RouteWrapper<Route: NavigationRoute>: Identifiable,Equatable {
    public let id = UUID()
    public let route: Route
    
    public init(route: Route) {
        self.route = route
    }
    
    // Equatable conformance
    public static func == (lhs: RouteWrapper<Route>, rhs: RouteWrapper<Route>) -> Bool {
        return lhs.id == rhs.id && lhs.route == rhs.route
    }
}

// Public router class
public class AppRouter<Route: NavigationRoute>: ObservableObject {
    @Published public private(set) var routeStack: [RouteWrapper<Route>]
    private let viewBuilder: (Route, AppRouter<Route>) -> AnyView
    
    public init(initialRoute: Route, viewBuilder: @escaping (Route, AppRouter<Route>) -> AnyView) {
        self.routeStack = [RouteWrapper(route: initialRoute)]
        self.viewBuilder = viewBuilder
    }
    
    public func push(_ route: Route) {
        routeStack.append(RouteWrapper(route: route))
    }
    
    public func pop() {
        if routeStack.count > 1 {
            routeStack.removeLast()
        }
    }
    
    public func popToRoot() {
        routeStack = [RouteWrapper(route: routeStack.first!.route)]
    }
    
    @ViewBuilder
    internal func viewForRoute(_ route: Route) -> some View {
        viewBuilder(route, self)
    }
}

// Internal generic container
struct NavigationContainer<Route: NavigationRoute>: View {
    @EnvironmentObject private var router: AppRouter<Route>
    
    var body: some View {
        ZStack {
            ForEach(router.routeStack) { wrapper in
                ZStack {
                    router.viewForRoute(wrapper.route)
                
                    if router.routeStack.firstIndex(of: wrapper) != 0 {
                        VStack(spacing: 0) {
                            HStack {
                                Button(action: {
                                    router.pop()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.blue)
                                        Text("Back")
                                            .font(.system(size: 17))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.leading, 10)
                                Spacer()
                            }
                            .frame(height: 44)
                            .zIndex(Double.infinity)
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(Double(router.routeStack.firstIndex(of: wrapper) ?? 0))
                .offset(x: offsetFor(wrapper: wrapper))
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .trailing)
                ))
            }
        }
        .animation(.easeInOut, value: router.routeStack)
    }
    
    private func offsetFor(wrapper: RouteWrapper<Route>) -> CGFloat {
        let index = router.routeStack.firstIndex(of: wrapper) ?? 0
        let topIndex = router.routeStack.count - 1
        
        if index == topIndex {
            return 0
        } else {
            return -UIScreen.main.bounds.width
        }
    }
}

// Public type-erased wrapper
public struct NavigationStack: View {
    private let content: AnyView
    
    public init<Route: NavigationRoute>(_ router: AppRouter<Route>) {
        self.content = AnyView(NavigationContainer<Route>().environmentObject(router))
    }
    
    public var body: some View {
        content
    }
}
