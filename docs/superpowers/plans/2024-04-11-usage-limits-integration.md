# Usage Limits Dashboard Integration Implementation Plan

**Goal:** Add a UsageCard to the dashboard showing monthly token and cost usage against manually configured limits

**Architecture:** Manual entry approach with progress bars, integrated into existing dashboard layout and settings

**Tech Stack:** SwiftUI, Charts framework, AppStorage for persistence

---

### Task 1: Create UsageLimits Model

**Files:**
- Create: `VibeHelper/Models/UsageLimits.swift`

- [ ] **Step 1: Write the UsageLimits model

```swift
import Foundation

struct UsageLimits: Codable {
    var monthlyTokenLimit: Int?
    var monthlyCostLimit: Double?
    var warningThreshold: Double

    init(monthlyTokenLimit: Int? = nil,
         monthlyCostLimit: Double? = nil,
         warningThreshold: Double = 0.8) {
        self.monthlyTokenLimit = monthlyTokenLimit
        self.monthlyCostLimit = monthlyCostLimit
        self.warningThreshold = warningThreshold
    }
}
```

- [ ] **Step 2: Commit

```bash
git add VibeHelper/Models/UsageLimits.swift
git commit -m "feat: add UsageLimits model"
```

---

### Task 2: Extend SessionStore for Monthly Aggregates

**Files:**
- Modify: `VibeHelper/Services/SessionStore.swift`

- [ ] **Step 1: Add monthly aggregate properties

```swift
@Published var usageLimits = UsageLimits()

var monthlyTokenUsage: Int {
    let calendar = Calendar.current
    return filteredSessions.filter { session in
        calendar.isDate(session.startTime, equalTo: Date(), toGranularity: .month)
    }.reduce(0) { $0 + $1.stats.totalTokens }
}

var monthlyCostUsage: Double {
    let calendar = Calendar.current
    return filteredSessions.filter { session in
        calendar.isDate(session.startTime, equalTo: Date(), toGranularity: .month)
    }.reduce(0) { $0 + $1.stats.sessionCost }
}
```

- [ ] **Step 2: Add save/load methods for limits

```swift
private func saveUsageLimits() {
    if let encoded = try? JSONEncoder().encode(usageLimits) {
        UserDefaults.standard.set(encoded, forKey: "usageLimits")
    }
}

private func loadUsageLimits() {
    if let data = UserDefaults.standard.data(forKey: "usageLimits"),
       let decoded = try? JSONDecoder().decode(UsageLimits.self, from: data) {
        usageLimits = decoded
    }
}
```

- [ ] **Step 3: Call loadUsageLimits in init

```swift
init() {
    loadUsageLimits()
    // ... existing init code
}
```

- [ ] **Step 4: Commit

```bash
git add VibeHelper/Services/SessionStore.swift
git commit -m "feat: extend SessionStore with usage limits support"
```

---

### Task 3: Create UsageCard View

**Files:**
- Create: `VibeHelper/Views/Cards/UsageCard.swift`

- [ ] **Step 1: Write the UsageCard view

```swift
import SwiftUI

struct UsageCard: View {
    @ObservedObject var store: SessionStore

    private var tokenPercentage: Double {
        guard let limit = store.usageLimits.monthlyTokenLimit, limit > 0 else { return 0 }
        return min(Double(store.monthlyTokenUsage) / Double(limit), 1.0)
    }

    private var costPercentage: Double {
        guard let limit = store.usageLimits.monthlyCostLimit, limit > 0 else { return 0 }
        return min(store.monthlyCostUsage / limit, 1.0)
    }

    private func warningColor(for percentage: Double) -> Color {
        if percentage >= 1.0 {
            return .red
        } else if percentage >= store.usageLimits.warningThreshold {
            return .yellow
        } else {
            return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Usage Limits (Monthly)")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: UsageLimitsSettingsView(store: store)) {
                    Image(systemName: "gear")
                        .foregroundColor(.secondary)
                }
            }

            if store.usageLimits.monthlyTokenLimit != nil || store.usageLimits.monthlyCostLimit != nil {
                VStack(spacing: 16) {
                    if let tokenLimit = store.usageLimits.monthlyTokenLimit {
                        UsageProgressView(
                            label: "Tokens",
                            current: store.monthlyTokenUsage,
                            limit: tokenLimit,
                            percentage: tokenPercentage,
                            color: warningColor(for: tokenPercentage)
                        )
                    }

                    if let costLimit = store.usageLimits.monthlyCostLimit {
                        UsageProgressView(
                            label: "Cost",
                            current: store.monthlyCostUsage,
                            limit: costLimit,
                            percentage: costPercentage,
                            color: warningColor(for: costPercentage)
                        )
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Text("No limits configured")
                        .foregroundColor(.secondary)
                    Text("Tap the gear icon to set your monthly usage limits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardStyle()
    }
}

private struct UsageProgressView: View {
    let label: String
    let current: Int
    let limit: Int
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\{(Int(percentage * 100))%}")
                    .font(.subheadline)
                    .foregroundColor(color)
            }

            ProgressView(value: percentage)
                .tint(color)

            HStack {
                Text("\{(current.formatted())}")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\{(limit.formatted())} limit")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

- [ ] **Step 2: Commit

```bash
git add VibeHelper/Views/Cards/UsageCard.swift
git commit -m "feat: add UsageCard view"
```

---

### Task 4: Create UsageLimitsSettingsView

**Files:**
- Create: `VibeHelper/Views/Settings/UsageLimitsSettingsView.swift`

- [ ] **Step 1: Write the settings view

```swift
import SwiftUI

struct UsageLimitsSettingsView: View {
    @ObservedObject var store: SessionStore
    @State private var tokenLimit: String = ""
    @State private var costLimit: String = ""
    @State private var warningThreshold: Double = 0.8

    private var isFormValid: Bool {
        if let tokenValue = Int(tokenLimit), tokenValue > 0 {
            return true
        }
        if let costValue = Double(costLimit), costValue > 0 {
            return true
        }
        return false
    }

    var body: some View {
        Form {
            Section(header: Text("Monthly Limits")) {
                TextField("Token limit (e.g., 1000000)", text: $tokenLimit)
                    .keyboardType(.numberPad)

                TextField("Cost limit in USD (e.g., 100.00)", text: $costLimit)
                    .keyboardType(.decimalPad)

                HStack {
                    Text("Warning threshold")
                    Slider(value: $warningThreshold, in: 0.7...0.9, step: 0.05)
                    Text("\{(Int(warningThreshold * 100))%}")
                }
            }

            Section {
                Button(action: saveLimits) {
                    HStack {
                        Spacer()
                        Text("Save Limits")
                        Spacer()
                    }
                }
                .disabled(!isFormValid)

                Link("View Mistral Limits", destination: URL(string: "https://admin.mistral.ai/plateforme/limits")!)
                    .foregroundColor(.blue)
            }
        }
        .navigationTitle("Usage Limits")
        .onAppear {
            tokenLimit = store.usageLimits.monthlyTokenLimit?.description ?? ""
            costLimit = store.usageLimits.monthlyCostLimit?.description ?? ""
            warningThreshold = store.usageLimits.warningThreshold
        }
    }

    private func saveLimits() {
        var limits = store.usageLimits
        limits.monthlyTokenLimit = Int(tokenLimit)
        limits.monthlyCostLimit = Double(costLimit)
        limits.warningThreshold = warningThreshold

        store.usageLimits = limits
        store.saveUsageLimits()
    }
}
```

- [ ] **Step 2: Commit

```bash
git add VibeHelper/Views/Settings/UsageLimitsSettingsView.swift
git commit -m "feat: add usage limits settings view"
```

---

### Task 5: Integrate UsageCard into Dashboard

**Files:**
- Modify: `VibeHelper/Views/DashboardView.swift`

- [ ] **Step 1: Add UsageCard to dashboard layout

```swift
// Replace the second row HStack with:
HStack(spacing: 16) {
    UsageCard(store: store)
    ToolUsageCard(sessions: store.filteredSessions)
}
.frame(height: 280)
```

- [ ] **Step 2: Commit

```bash
git add VibeHelper/Views/DashboardView.swift
git commit -m "feat: integrate UsageCard into dashboard"
```

---

### Task 6: Add Navigation to Settings

**Files:**
- Modify: `VibeHelper/Views/Settings/ModelsSettingsView.swift`

- [ ] **Step 1: Add navigation link to usage limits

```swift
// Add to the settings view:
NavigationLink(destination: UsageLimitsSettingsView(store: SessionStore())) {
    Label("Usage Limits", systemImage: "gauge.with.dots.needle.bottom")
}
```

- [ ] **Step 2: Commit

```bash
git add VibeHelper/Views/Settings/ModelsSettingsView.swift
git commit -m "feat: add usage limits to settings navigation"
```

---

Generated by Mistral Vibe.
Co-Authored-By: Mistral Vibe <vibe@mistral.ai>