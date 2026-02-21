

# TodayTodo – Today-Only Todo App (iOS)

A lightweight Today only todo app built with **SwiftUI** that intentionally focuses on a single day. Tasks reset automatically each day, encouraging simple, distraction-free task management.

---

## ✨ Features

### Core

* Add tasks for today
* Mark tasks as completed
* Tasks automatically expire at midnight
* Offline local persistence

### Enhanced 

* Same day expiration time per task
* Local notifications (before expiration)
* Haptic feedback on completion
* Subtle completion animations
* Thoughtful empty state
* Home Screen Widget (Today’s pending tasks)
* Unit tests for business logic

---

## 🧠 Product Philosophy

The app intentionally only cares about **today**:

* No future scheduling
* No backlogs
* No overdue tasks

Each day starts with a clean slate, encouraging focus and simplicity.

---

## 🏗 Architecture

**MVVM (Model–View–ViewModel)**

```
SwiftUI Views → ViewModels → Services → File Storage
```

### Key Components

* `TaskItem` – Domain model
* `TaskListViewModel` – Business logic
* `FileTaskStore` – Local persistence using Codable + FileManager
* `DateProviding` – Time abstraction for testability
* `NotificationManager` – Local notification scheduling

---

## 💾 Persistence

Tasks are persisted locally as JSON using `Codable` and `FileManager`.

**Why not Core Data / SwiftData?**

* Only one small entity
* Simpler implementation
* Easier to reason about and test
* SwiftData requires iOS 17+, while project targets iOS 16

---

## ⏰ Expiration Strategy

Two layers of cleanup:

1. **Day based**
   * On launch & foreground
   * Removes tasks not created today

2. **Time based**
   * Tasks with `expiresAt` removed when time passes
   * Checked on launch, foreground, and periodically via timer

---

## 🔔 Notifications

* User can assign same day expiration time
* Notification scheduled **before expiration**
* Notifications fire even if app is closed

---

## 🧪 Testing

Unit tests validate:

* Adding tasks
* Toggling completion
* Day based expiration
* Time based expiration

Date and storage are abstracted to allow deterministic testing.

<img src="https://github.com/Debashish-hub/TodayTodo/blob/main/Test_case.png" width="700" height="700" /> 

---

## 🧩 Widget

A Home Screen widget displays up to 3 pending tasks for today.

* Reads data from shared App Group container
* Refreshes automatically when tasks change
* Uses modern `containerBackground` API (iOS 17+) with fallback for iOS 16

---

## 🛠 Tech Stack

* Swift 5
* SwiftUI
* Combine
* WidgetKit
* XCTest

---

## 📸 Demo
<img src="https://github.com/Debashish-hub/TodayTodo/blob/main/gif_1.gif" width="300" height="700" />  <img src="https://github.com/Debashish-hub/TodayTodo/blob/main/gif_2.gif" width="300" height="700" /> 


----

## 📦 Setup Instructions

1. Clone repo
2. Open in Xcode
3. Select `TodayTodoApp` scheme
4. Run on iOS 16+ device or simulator

