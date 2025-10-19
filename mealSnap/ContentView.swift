//
//  ContentView.swift
//  mealSnap
//
//  Created by Happiness Adeboye on 12/10/2025.
//

import SwiftUI

enum AppTab: Hashable {
    case today
    case add
    case diary
    case settings
}

struct ContentView: View {
    @StateObject private var store = MealStore()
    @State private var selectedTab: AppTab = .today
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Today", systemImage: "sun.max")
            }
            .tag(AppTab.today)
            
            NavigationStack {
                AddMealView()
            }
            .tabItem {
                Label("Add", systemImage: "plus.circle")
            }
            .tag(AppTab.add)
            
            NavigationStack {
                DiaryView()
            }
            .tabItem {
                Label("Diary", systemImage: "book.pages")
            }
            .tag(AppTab.diary)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(AppTab.settings)
        }
        .environmentObject(store)
        .fullScreenCover(isPresented: $store.showingOnboarding) {
            OnboardingView(
                viewModel: OnboardingViewModel(plan: store.plan),
                allowDismissal: store.plan != nil
            ) { plan in
                store.updatePlan(plan)
            }
            .preferredColorScheme(.dark)
        }
        .tint(.accentPrimary)
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
