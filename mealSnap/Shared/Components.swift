//
//  Components.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 12/10/2025.
//

import SwiftUI

// MARK: - Primary Button
struct PrimaryButton: View {
    var title: String
    var systemImage: String? = nil
    var action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline.weight(.semibold))
                }
                Text(title)
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [.accentSecondary, .accentPrimary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .accentPrimary.opacity(0.4), radius: 16, x: 0, y: 12)
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(title)
        .accessibilityHint("Activates the \(title) action.")
    }
}

// MARK: - Card
struct Card<Content: View>: View {
    var edges: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        let base = RoundedRectangle(cornerRadius: 24, style: .continuous)
        content()
            .padding(edges)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [.appSurface, .appSurfaceElevated],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: base
            )
            .overlay(base.strokeBorder(Color.white.opacity(0.04)))
            .shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 14)
    }
}

// MARK: - Macro Pill
struct MacroPill: View {
    var label: String
    var value: Double
    var unit: String
    var tint: Color
    var secondaryText: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(Int(value)) \(unit)")
                .font(.headline)
                .fontWeight(.medium)
            if let secondaryText {
                Text(secondaryText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(tint.opacity(0.22), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(tint.opacity(0.34)))
    }
}

// MARK: - Confidence Tag
struct ConfidenceTag: View {
    var confidence: Double
    var body: some View {
        Text(confidence, format: .percent.precision(.fractionLength(0)))
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentPrimary.opacity(0.25), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.accentSecondary.opacity(0.6)))
            .accessibilityLabel("Confidence \(confidence.formatted(.percent))")
    }
}

// MARK: - Calorie Ring
struct CalorieRing: View {
    var progress: Double
    var calories: Double
    var goal: Double
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.08), lineWidth: 22)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.accentPrimary, .accentSecondary, .accentTertiary]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 22, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.accentPrimary.opacity(0.5), radius: 16, x: 0, y: 12)
            
            VStack(spacing: 6) {
                Text("\(Int(calories))")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("of \(Int(goal)) kcal")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 220, height: 220)
        .padding()
        .drawingGroup() // GPU optimized
        .onAppear { withAnimation(.easeInOut(duration: 1.0)) { animatedProgress = min(progress, 1) } }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.6)) { animatedProgress = min(newValue, 1) }
        }
    }
}

// MARK: - Detection Overlay (for Object Detection Integration)
struct DetectionBox: View {
    var label: String
    var confidence: Double
    var color: Color
    var rect: CGRect
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .stroke(color, lineWidth: 3)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).bold().foregroundColor(.white)
                Text("\(Int(confidence * 100))%").font(.caption2).foregroundColor(.white.opacity(0.9))
            }
            .padding(6)
            .background(Color.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .offset(x: rect.minX, y: rect.minY - 22)
        }
    }
}

