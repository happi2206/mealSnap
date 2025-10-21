//
//  OnboardingView.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 11/10/2025.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: OnboardingViewModel
    var allowDismissal: Bool
    var onComplete: (AppPlan) -> Void
    
    @State private var path: [OnboardingStep] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            WelcomeStep(onNext: { push(.profile) })
            .navigationDestination(for: OnboardingStep.self) { step in
                switch step {
                case .welcome:
                    EmptyView()
                case .profile:
                    ProfileStep(
                        viewModel: viewModel,
                        onNext: { push(.activity) }
                    )
                case .activity:
                    ActivityStep(
                        viewModel: viewModel,
                        onNext: { push(.goal) }
                    )
                case .goal:
                    GoalStep(
                        viewModel: viewModel,
                        onNext: { push(.pace) }
                    )
                case .pace:
                    PaceStep(
                        viewModel: viewModel,
                        onNext: { push(.review) }
                    )
                case .review:
                    ReviewStep(
                        viewModel: viewModel,
                        onNext: { push(.permissions) }
                    )
                case .permissions:
                    PermissionsStep(
                        viewModel: viewModel,
                        onNext: { push(.done) }
                    )
                case .done:
                    DoneStep(viewModel: viewModel)
                }
            }
            .toolbar {
                if allowDismissal {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                        .tint(.secondary)
                    }
                }
            }
        }
        .onChange(of: viewModel.isComplete) { _, newValue in
            guard newValue, let plan = viewModel.resultingPlan else { return }
            onComplete(plan)
            dismiss()
        }
        .background(Color.appBackground)
    }
    
    private func push(_ step: OnboardingStep) {
        if let last = path.last, last == step { return }
        path.append(step)
    }
}

// MARK: - Step Views

private struct WelcomeStep: View {
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressHeader(
                title: "Welcome to MealSnap",
                subtitle: "Let’s tailor your nutrition plan before your first snap.",
                step: OnboardingStep.welcome.position,
                total: OnboardingStep.totalSteps
            )
            Spacer()
            Card {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(LinearGradient(colors: [.accentPrimary, .accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("Personalize your dashboard")
                        .font(.title2.weight(.semibold))
                    Text("We’ll take a minute to learn about you and craft a plan that adapts to your goals.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            PrimaryButton(title: "Get Started", systemImage: "arrow.right") {
                onNext()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Color.appBackground.ignoresSafeArea())
    }
}

private struct ProfileStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onNext: () -> Void
    
    @FocusState private var focusField: Field?
    
    enum Field: Hashable {
        case name, age, height, heightFeet, heightInches, weight, weightLbs
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ProgressHeader(
                    title: "Tell us about you",
                    subtitle: "These basics help MealSnap understand your energy needs.",
                    step: OnboardingStep.profile.position,
                    total: OnboardingStep.totalSteps
                )
                
                Card {
                    VStack(spacing: 18) {
                        nameField
                        ageField
                        heightSection
                        weightSection
                        sexPicker
                    }
                }
            }
            
            PrimaryButton(title: "Next", systemImage: "arrow.right") {
                onNext()
            }
            .disabled(!viewModel.isStepValid(.profile))
            .opacity(viewModel.isStepValid(.profile) ? 1 : 0.6)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Profile")
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Subviews
private extension ProfileStep {
    var nameField: some View {
        VStack {
            LabeledField(
                title: "Name",
                placeholder: "You",
                text: $viewModel.name,
                autocapitalization: .words
            )
            .focused($focusField, equals: .name)
            if let error = viewModel.nameError {
                fieldError(error)
            }
        }
    }

    var ageField: some View {
        VStack {
            LabeledField(
                title: "Age",
                placeholder: "28",
                text: $viewModel.age,
                keyboardType: .numberPad,
                autocapitalization: .none
            )
            .focused($focusField, equals: .age)
            .onChange(of: viewModel.age) { _, newValue in
                viewModel.age = newValue.filter { $0.isNumber }
            }
            if let error = viewModel.ageError {
                fieldError(error)
            }
        }
    }

    var heightSection: some View {
        VStack(spacing: 16) {
            UnitToggle(
                title: "Height units",
                selection: $viewModel.heightUnit,
                options: HeightUnit.allCases
            ) { unit in
                unit.display
            }

            if viewModel.heightUnit == .metric {
                LabeledField(
                    title: "Height",
                    placeholder: "170",
                    text: $viewModel.heightCM,
                    keyboardType: .decimalPad,
                    autocapitalization: .none
                )
                .focused($focusField, equals: .height)
                .onChange(of: viewModel.heightCM) { _, newValue in
                    viewModel.heightCM = sanitizeDecimal(newValue)
                }
            } else {
                imperialHeightFields
            }

            if let error = viewModel.heightError {
                fieldError(error)
            }
        }
    }

    var imperialHeightFields: some View {
        HStack(spacing: 16) {
            LabeledField(
                title: "Feet",
                placeholder: "5",
                text: $viewModel.heightFeet,
                keyboardType: .numberPad,
                autocapitalization: .none
            )
            .focused($focusField, equals: .heightFeet)
            .onChange(of: viewModel.heightFeet) { _, newValue in
                viewModel.heightFeet = newValue.filter { $0.isNumber }
            }

            LabeledField(
                title: "Inches",
                placeholder: "9",
                text: $viewModel.heightInches,
                keyboardType: .numberPad,
                autocapitalization: .none
            )
            .focused($focusField, equals: .heightInches)
            .onChange(of: viewModel.heightInches) { _, newValue in
                viewModel.heightInches = newValue.filter { $0.isNumber }
            }
        }
    }

    var weightSection: some View {
        VStack(spacing: 16) {
            UnitToggle(
                title: "Weight units",
                selection: $viewModel.weightUnit,
                options: WeightUnit.allCases
            ) { unit in
                unit.display
            }

            if viewModel.weightUnit == .metric {
                LabeledField(
                    title: "Weight",
                    placeholder: "65",
                    text: $viewModel.weightKG,
                    keyboardType: .decimalPad,
                    
                    autocapitalization: .none
                )
                .focused($focusField, equals: .weight)
                .onChange(of: viewModel.weightKG) { _, newValue in
                    viewModel.weightKG = sanitizeDecimal(newValue)
                }
            } else {
                LabeledField(
                    title: "Weight",
                    placeholder: "145",
                    text: $viewModel.weightLBS,
                    keyboardType: .decimalPad,
                    autocapitalization: .none
                )
                .focused($focusField, equals: .weightLbs)
                .onChange(of: viewModel.weightLBS) { _, newValue in
                    viewModel.weightLBS = sanitizeDecimal(newValue)
                }
            }

            if let error = viewModel.weightError {
                fieldError(error)
            }
        }
    }

    var sexPicker: some View {
        Picker("Sex", selection: $viewModel.sex) {
            ForEach(Sex.allCases) { sex in
                Text(sex.displayName).tag(sex)
            }
        }
        .pickerStyle(.segmented)
    }

    func sanitizeDecimal(_ value: String) -> String {
        var filtered = value.filter { "0123456789.,".contains($0) }
        if let firstDot = filtered.firstIndex(of: ".") {
            let suffix = filtered[firstDot...].dropFirst().replacingOccurrences(of: ".", with: "")
            filtered = String(filtered[..<filtered.index(after: firstDot)]) + suffix
        }
        if let firstComma = filtered.firstIndex(of: ",") {
            let suffix = filtered[firstComma...].dropFirst().replacingOccurrences(of: ",", with: "")
            filtered = String(filtered[..<filtered.index(after: firstComma)]) + suffix
        }
        return filtered
    }

    @ViewBuilder
    func fieldError(_ message: String) -> some View {
        ErrorText(message: message)
            .transition(.opacity)
    }
}

private struct ActivityStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            header
            activityOptions
            Spacer()
            nextButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Activity")
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - Subviews
    private var header: some View {
        ProgressHeader(
            title: "How active are you?",
            subtitle: "Helps us estimate how many calories you burn in a day.",
            step: OnboardingStep.activity.position,
            total: OnboardingStep.totalSteps
        )
    }
    
    private var activityOptions: some View {
        VStack(spacing: 16) {
            ForEach(ActivityLevel.allCases, id: \.id) { level in
                SelectableOption(
                    title: level.displayName,
                    subtitle: level.description,
                    isSelected: viewModel.activity == level,
                    systemImage: icon(for: level)
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.activity = level
                    }
                }
            }
        }
    }

    
    private var nextButton: some View {
        PrimaryButton(title: "Next", systemImage: "arrow.right") {
            onNext()
        }
    }
    
    private func icon(for level: ActivityLevel) -> String {
        switch level {
        case .sedentary: return "chair.fill"
        case .light: return "figure.walk"
        case .moderate: return "bicycle"
        case .active: return "figure.run"
        }
    }
}


private struct GoalStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            header
            goalOptions
            Spacer()
            nextButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Goal")
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        ProgressHeader(
            title: "Choose your goal",
            subtitle: "MealSnap will tune your calories and macros around this.",
            step: OnboardingStep.goal.position,
            total: OnboardingStep.totalSteps
        )
    }
    
    private var goalOptions: some View {
        VStack(spacing: 16) {
            ForEach(Goal.allCases) { goal in
                goalOption(for: goal)
            }
        }
    }
    
    private func goalOption(for goal: Goal) -> some View {
        SelectableOption(
            title: goal.displayName,
            subtitle: goalSubtitle(goal),
            isSelected: viewModel.goal == goal,
            systemImage: goalIcon(goal)
        ) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.goal = goal
            }
        }
    }
    
    private var nextButton: some View {
        PrimaryButton(title: "Next", systemImage: "arrow.right") {
            onNext()
        }
    }
    
    // MARK: - Helpers
    
    private func goalSubtitle(_ goal: Goal) -> String {
        switch goal {
        case .loseWeight: return "Lean down while eating nourishing meals."
        case .maintain: return "Hold steady with balanced energy."
        case .gainMuscle: return "Build strength with supportive fueling."
        }
    }
    
    private func goalIcon(_ goal: Goal) -> String {
        switch goal {
        case .loseWeight: return "scalemass"
        case .maintain: return "circle.lefthalf.filled"
        case .gainMuscle: return "dumbbell.fill"
        }
    }
}

private struct PaceStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ProgressHeader(
                title: "Preferred pace",
                subtitle: "Adjust how fast you’d like to move toward your goal.",
                step: OnboardingStep.pace.position,
                total: OnboardingStep.totalSteps
            )

            paceOptions

            Spacer()

            PrimaryButton(title: "Next", systemImage: "arrow.right") {
                onNext()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Pace")
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // 👇 Split ForEach out to reduce type inference load
    private var paceOptions: some View {
        VStack(spacing: 16) {
            ForEach(Pace.allCases, id: \.id) { pace in
                SelectableOption(
                    title: pace.displayName,
                    subtitle:"",
                    // ❌ Removed subtitle: pace.description
                    isSelected: viewModel.pace == pace,
                    systemImage: paceIcon(pace)
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.pace = pace
                    }
                }
            }
        }
    }


    private func paceIcon(_ pace: Pace) -> String {
        switch pace {
        case .slow: return "tortoise.fill"
        case .moderate: return "gauge.medium"
        case .fast: return "hare.fill"
        case .description:
           return "hare.fill"
        }
    }
}


private struct ReviewStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onNext: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ProgressHeader(
                    title: "Here’s your plan",
                    subtitle: "We built these targets based on your info.",
                    step: OnboardingStep.review.position,
                    total: OnboardingStep.totalSteps
                )
                
                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Vitals")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 12) {
                            metricRow(title: "BMI", value: "\(viewModel.bmi.formatted(.number.precision(.fractionLength(1)))) • \(viewModel.bmiCategory)")
                            metricRow(title: "BMR", value: "\(Int(viewModel.bmr.rounded())) kcal")
                            metricRow(title: "TDEE", value: "\(Int(viewModel.tdee.rounded())) kcal")
                        }
                    }
                }
                
                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily targets")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 12) {
                            metricRow(title: "Calories", value: "\(Int(viewModel.targetCalories.rounded())) kcal")
                            let macros = viewModel.macroTargets
                            metricRow(title: "Protein", value: "\(macros.protein) g")
                            metricRow(title: "Carbs", value: "\(macros.carbs) g")
                            metricRow(title: "Fat", value: "\(macros.fat) g")
                        }
                    }
                }
                
                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Summary")
                            .font(.headline)
                        Text("\(viewModel.trimmedName) •  \(viewModel.ageValue ?? 0)")
                            .font(.title3.weight(.semibold))
                        Text("\(viewModel.goal.displayName) • \(viewModel.pace.displayName) pace • \(viewModel.activity.displayName) activity")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            PrimaryButton(title: "Looks Good", systemImage: "checkmark.circle.fill") {
                onNext()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Review")
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}

private struct PermissionsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressHeader(
                title: "Stay in sync",
                subtitle: "MealSnap will soon connect with Apple Health to sync activity and nutrition.",
                step: OnboardingStep.permissions.position,
                total: OnboardingStep.totalSteps
            )
            
            Card {
                VStack(alignment: .leading, spacing: 18) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.accentPrimary)
                    Text("Health permissions coming soon")
                        .font(.title3.weight(.semibold))
                    Text("You’ll get a one-tap prompt when Health sync is ready. For now, MealSnap keeps everything private on-device.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                onNext()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Health")
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct DoneStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressHeader(
                title: "All set",
                subtitle: "Your personalized plan is ready. Start scanning meals with confidence.",
                step: OnboardingStep.done.position,
                total: OnboardingStep.totalSteps
            )
            
            Card {
                VStack(alignment: .leading, spacing: 18) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.accentSecondary)
                    Text("Next up: capture your first meal")
                        .font(.title2.weight(.semibold))
                    Text("We’ll guide you along with smart detections, reminders, and friendly progress tracking.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            PrimaryButton(title: "Launch MealSnap", systemImage: "sparkles") {
                viewModel.complete()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Ready")
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Shared

private struct SelectableOption: View {
    var title: String
    var subtitle: String
    var isSelected: Bool
    var systemImage: String
    var action: () -> Void
    
    var body: some View {
        let iconBackground = isSelected ? Color.accentSecondary.opacity(0.3) : Color.appSurface
        let cardFill = isSelected ? Color.accentPrimary.opacity(0.26) : Color.appSurface
        let strokeColor = isSelected ? Color.accentPrimary.opacity(0.7) : Color.white.opacity(0.05)
        let shadowColor = Color.black.opacity(isSelected ? 0.4 : 0.2)
        let shadowRadius: CGFloat = isSelected ? 16 : 10
        let shadowYOffset: CGFloat = isSelected ? 12 : 8
        let strokeWidth: CGFloat = isSelected ? 2 : 1
        
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(iconBackground)
                    )
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentPrimary)
                        .font(.title2)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowYOffset)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}


struct ErrorText: View {
    var message: String

    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
            .transition(.opacity)
    }
}

#Preview {
    OnboardingView(
        viewModel: OnboardingViewModel(plan: nil),
        allowDismissal: true,
        onComplete: { _ in }
    )
    .preferredColorScheme(.dark)
}
