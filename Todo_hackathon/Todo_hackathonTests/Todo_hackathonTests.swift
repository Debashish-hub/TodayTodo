import XCTest
@testable import Todo_hackathon

// MARK: - Test doubles

struct MockDateProvider: DateProviding {
    let date: Date
    func now() -> Date { date }
}

final class InMemoryTaskStore: TaskStoring {
    private(set) var tasks: [TaskItem] = []

    func load() -> [TaskItem] {
        tasks
    }

    func save(_ tasks: [TaskItem]) {
        self.tasks = tasks
    }
}

// Tests use TaskListLogic (pure functions) and store only — no ViewModel, so no @Published/Combine crash.

// MARK: - TaskListLogic tests (ViewModel behavior tested without instantiating ViewModel)

final class TaskListViewModelTests: XCTestCase {

    // MARK: - Toggle (TaskListLogic.toggleTask)

    func test_toggleTask_changesCompletionState() {
        let now = Date()
        let task = TaskItem(id: UUID(), title: "Walk dog", isCompleted: false, createdAt: now, expiresAt: nil)
        let result = TaskListLogic.toggleTask(task, in: [task])
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.first!.isCompleted)
    }

    func test_toggleTask_twice_restoresIncompleteState() {
        let now = Date()
        let task = TaskItem(id: UUID(), title: "Task", isCompleted: false, createdAt: now, expiresAt: nil)
        let once = TaskListLogic.toggleTask(task, in: [task])!
        let twice = TaskListLogic.toggleTask(task, in: once)!
        XCTAssertFalse(twice.first!.isCompleted)
    }

    // MARK: - Day expiry (TaskListLogic.filterExpiredDayTasks)

    func test_removeExpiredDayTasks_removesYesterdayTasks() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let oldTask = TaskItem(id: UUID(), title: "Old", isCompleted: false, createdAt: yesterday, expiresAt: nil)
        let result = TaskListLogic.filterExpiredDayTasks([oldTask], now: today)
        XCTAssertTrue(result.isEmpty)
    }

    func test_removeExpiredDayTasks_keepsTodayTasks() {
        let today = Date()
        let task = TaskItem(id: UUID(), title: "Today", isCompleted: false, createdAt: today, expiresAt: nil)
        let result = TaskListLogic.filterExpiredDayTasks([task], now: today)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Today")
    }

    // MARK: - Time expiry (TaskListLogic.filterIndividuallyExpired)

    func test_removeIndividuallyExpiredTasks_removesExpiredTask() {
        let now = Date()
        let expiredTask = TaskItem(
            id: UUID(),
            title: "Expired",
            isCompleted: false,
            createdAt: now,
            expiresAt: Calendar.current.date(byAdding: .minute, value: -1, to: now)
        )
        let result = TaskListLogic.filterIndividuallyExpired([expiredTask], now: now)
        XCTAssertTrue(result.isEmpty)
    }

    func test_nonExpiredTask_remains() {
        let now = Date()
        let activeTask = TaskItem(
            id: UUID(),
            title: "Still valid",
            isCompleted: false,
            createdAt: now,
            expiresAt: Calendar.current.date(byAdding: .minute, value: 10, to: now)
        )
        let result = TaskListLogic.filterIndividuallyExpired([activeTask], now: now)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Still valid")
    }

    func test_taskWithNoExpiry_remains() {
        let now = Date()
        let task = TaskItem(id: UUID(), title: "No expiry", isCompleted: false, createdAt: now, expiresAt: nil)
        let result = TaskListLogic.filterIndividuallyExpired([task], now: now)
        XCTAssertEqual(result.count, 1)
    }

    // MARK: - Add task (data shape + store)

    func test_addTask_appendsTaskAndPersists() {
        let now = Date()
        let store = InMemoryTaskStore()
        let task = TaskItem(id: UUID(), title: "New task", isCompleted: false, createdAt: now, expiresAt: nil)
        store.save([task])
        XCTAssertEqual(store.load().count, 1)
        XCTAssertEqual(store.load().first?.title, "New task")
        XCTAssertFalse(store.load().first!.isCompleted)
    }

    func test_addTask_withExpiry_setsExpiresAt() {
        let now = Date()
        let expiry = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
        let task = TaskItem(id: UUID(), title: "With expiry", isCompleted: false, createdAt: now, expiresAt: expiry)
        XCTAssertEqual(task.expiresAt, expiry)
    }

    // MARK: - Toggle + persist (logic then store)

    func test_toggle_persistsToStore() {
        let now = Date()
        let task = TaskItem(id: UUID(), title: "Persist", isCompleted: false, createdAt: now, expiresAt: nil)
        let store = InMemoryTaskStore()
        store.save([task])
        let toggled = TaskListLogic.toggleTask(task, in: store.load())!
        store.save(toggled)
        XCTAssertTrue(store.load().first!.isCompleted)
    }

    // MARK: - TaskListLogic edge cases

    func test_toggleTask_withTaskNotInList_returnsNil() {
        let task = TaskItem(id: UUID(), title: "A", isCompleted: false, createdAt: Date(), expiresAt: nil)
        let other = TaskItem(id: UUID(), title: "B", isCompleted: false, createdAt: Date(), expiresAt: nil)
        let result = TaskListLogic.toggleTask(task, in: [other])
        XCTAssertNil(result)
    }

    func test_toggleTask_withEmptyList_returnsNil() {
        let task = TaskItem(id: UUID(), title: "Only", isCompleted: false, createdAt: Date(), expiresAt: nil)
        let result = TaskListLogic.toggleTask(task, in: [])
        XCTAssertNil(result)
    }

    func test_toggleTask_withMultipleTasks_onlyTogglesMatchingTask() {
        let now = Date()
        let taskA = TaskItem(id: UUID(), title: "A", isCompleted: false, createdAt: now, expiresAt: nil)
        let taskB = TaskItem(id: UUID(), title: "B", isCompleted: false, createdAt: now, expiresAt: nil)
        let result = TaskListLogic.toggleTask(taskA, in: [taskA, taskB])
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.count, 2)
        XCTAssertTrue(result![0].isCompleted)
        XCTAssertFalse(result![1].isCompleted)
    }

    func test_toggleTask_withAlreadyCompletedTask_togglesToIncomplete() {
        let now = Date()
        let task = TaskItem(id: UUID(), title: "Done", isCompleted: true, createdAt: now, expiresAt: nil)
        let result = TaskListLogic.toggleTask(task, in: [task])
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.first!.isCompleted)
    }

    func test_filterExpiredDayTasks_emptyArray_returnsEmpty() {
        let result = TaskListLogic.filterExpiredDayTasks([], now: Date())
        XCTAssertTrue(result.isEmpty)
    }

    func test_filterExpiredDayTasks_mixedTodayAndYesterday_keepsOnlyToday() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let oldTask = TaskItem(id: UUID(), title: "Old", isCompleted: false, createdAt: yesterday, expiresAt: nil)
        let todayTask = TaskItem(id: UUID(), title: "Today", isCompleted: false, createdAt: today, expiresAt: nil)
        let result = TaskListLogic.filterExpiredDayTasks([oldTask, todayTask], now: today)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Today")
    }

    func test_filterExpiredDayTasks_taskAtStartOfDay_keepsTask() {
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let task = TaskItem(id: UUID(), title: "Midnight", isCompleted: false, createdAt: startOfDay, expiresAt: nil)
        let result = TaskListLogic.filterExpiredDayTasks([task], now: today)
        XCTAssertEqual(result.count, 1)
    }

    func test_filterIndividuallyExpired_emptyArray_returnsEmpty() {
        let result = TaskListLogic.filterIndividuallyExpired([], now: Date())
        XCTAssertTrue(result.isEmpty)
    }

    func test_filterIndividuallyExpired_expiresAtExactlyNow_removesTask() {
        let now = Date()
        let task = TaskItem(id: UUID(), title: "Due now", isCompleted: false, createdAt: now, expiresAt: now)
        let result = TaskListLogic.filterIndividuallyExpired([task], now: now)
        XCTAssertTrue(result.isEmpty)
    }

    func test_filterIndividuallyExpired_mixedExpiredNonExpiredNoExpiry_keepsOnlyValid() {
        let now = Date()
        let expired = TaskItem(
            id: UUID(),
            title: "Expired",
            isCompleted: false,
            createdAt: now,
            expiresAt: Calendar.current.date(byAdding: .minute, value: -1, to: now)
        )
        let valid = TaskItem(
            id: UUID(),
            title: "Valid",
            isCompleted: false,
            createdAt: now,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 1, to: now)
        )
        let noExpiry = TaskItem(id: UUID(), title: "No expiry", isCompleted: false, createdAt: now, expiresAt: nil)
        let result = TaskListLogic.filterIndividuallyExpired([expired, valid, noExpiry], now: now)
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains(where: { $0.title == "Valid" }))
        XCTAssertTrue(result.contains(where: { $0.title == "No expiry" }))
    }

    func test_filterExpiredDayTasks_multipleYesterdayTasks_allRemoved() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let t1 = TaskItem(id: UUID(), title: "Y1", isCompleted: false, createdAt: yesterday, expiresAt: nil)
        let t2 = TaskItem(id: UUID(), title: "Y2", isCompleted: true, createdAt: yesterday, expiresAt: nil)
        let result = TaskListLogic.filterExpiredDayTasks([t1, t2], now: today)
        XCTAssertTrue(result.isEmpty)
    }

    func test_filterExpiredDayTasks_taskJustBeforeMidnight_removed() {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let yesterdayEnd = cal.date(byAdding: .second, value: -1, to: todayStart)!
        let task = TaskItem(id: UUID(), title: "Late", isCompleted: false, createdAt: yesterdayEnd, expiresAt: nil)
        let result = TaskListLogic.filterExpiredDayTasks([task], now: todayStart)
        XCTAssertTrue(result.isEmpty)
    }

    func test_filterIndividuallyExpired_allExpired_returnsEmpty() {
        let now = Date()
        let past = Calendar.current.date(byAdding: .minute, value: -5, to: now)!
        let t1 = TaskItem(id: UUID(), title: "E1", isCompleted: false, createdAt: now, expiresAt: past)
        let t2 = TaskItem(id: UUID(), title: "E2", isCompleted: false, createdAt: now, expiresAt: past)
        let result = TaskListLogic.filterIndividuallyExpired([t1, t2], now: now)
        XCTAssertTrue(result.isEmpty)
    }

    func test_filterIndividuallyExpired_preservesOrder() {
        let now = Date()
        let future = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
        let a = TaskItem(id: UUID(), title: "A", isCompleted: false, createdAt: now, expiresAt: future)
        let b = TaskItem(id: UUID(), title: "B", isCompleted: false, createdAt: now, expiresAt: nil)
        let c = TaskItem(id: UUID(), title: "C", isCompleted: false, createdAt: now, expiresAt: future)
        let result = TaskListLogic.filterIndividuallyExpired([a, b, c], now: now)
        XCTAssertEqual(result.map(\.title), ["A", "B", "C"])
    }

    func test_filterExpiredDayTasks_preservesOrder() {
        let today = Date()
        let t1 = TaskItem(id: UUID(), title: "First", isCompleted: false, createdAt: today, expiresAt: nil)
        let t2 = TaskItem(id: UUID(), title: "Second", isCompleted: false, createdAt: today, expiresAt: nil)
        let result = TaskListLogic.filterExpiredDayTasks([t1, t2], now: today)
        XCTAssertEqual(result.map(\.title), ["First", "Second"])
    }

    func test_toggleTask_preservesOtherTasksUnchanged() {
        let now = Date()
        let a = TaskItem(id: UUID(), title: "A", isCompleted: false, createdAt: now, expiresAt: nil)
        let b = TaskItem(id: UUID(), title: "B", isCompleted: true, createdAt: now, expiresAt: nil)
        let result = TaskListLogic.toggleTask(a, in: [a, b])!
        XCTAssertEqual(result[0].title, "A")
        XCTAssertTrue(result[0].isCompleted)
        XCTAssertEqual(result[1].title, "B")
        XCTAssertTrue(result[1].isCompleted)
    }

    func test_fullPipeline_dayFilterThenIndividualFilter() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let expiredTime = Calendar.current.date(byAdding: .minute, value: -1, to: today)!
        let validTime = Calendar.current.date(byAdding: .hour, value: 1, to: today)!
        let oldExpired = TaskItem(id: UUID(), title: "OldExp", isCompleted: false, createdAt: yesterday, expiresAt: expiredTime)
        let todayExpired = TaskItem(id: UUID(), title: "TodayExp", isCompleted: false, createdAt: today, expiresAt: expiredTime)
        let todayValid = TaskItem(id: UUID(), title: "TodayValid", isCompleted: false, createdAt: today, expiresAt: validTime)
        let todayNoExp = TaskItem(id: UUID(), title: "TodayNoExp", isCompleted: false, createdAt: today, expiresAt: nil)
        let afterDay = TaskListLogic.filterExpiredDayTasks([oldExpired, todayExpired, todayValid, todayNoExp], now: today)
        let afterIndiv = TaskListLogic.filterIndividuallyExpired(afterDay, now: today)
        XCTAssertEqual(afterIndiv.count, 2)
        XCTAssertTrue(afterIndiv.contains(where: { $0.title == "TodayValid" }))
        XCTAssertTrue(afterIndiv.contains(where: { $0.title == "TodayNoExp" }))
    }

    func test_toggleTask_singleElementList() {
        let now = Date()
        let task = TaskItem(id: UUID(), title: "Only", isCompleted: false, createdAt: now, expiresAt: nil)
        let result = TaskListLogic.toggleTask(task, in: [task])
        XCTAssertEqual(result?.count, 1)
        XCTAssertTrue(result!.first!.isCompleted)
    }

    func test_filterExpiredDayTasks_allToday_returnsAll() {
        let today = Date()
        let t1 = TaskItem(id: UUID(), title: "A", isCompleted: false, createdAt: today, expiresAt: nil)
        let t2 = TaskItem(id: UUID(), title: "B", isCompleted: false, createdAt: today, expiresAt: nil)
        let result = TaskListLogic.filterExpiredDayTasks([t1, t2], now: today)
        XCTAssertEqual(result.count, 2)
    }

    func test_filterIndividuallyExpired_allNoExpiry_returnsAll() {
        let now = Date()
        let t1 = TaskItem(id: UUID(), title: "A", isCompleted: false, createdAt: now, expiresAt: nil)
        let t2 = TaskItem(id: UUID(), title: "B", isCompleted: false, createdAt: now, expiresAt: nil)
        let result = TaskListLogic.filterIndividuallyExpired([t1, t2], now: now)
        XCTAssertEqual(result.count, 2)
    }

    func test_toggleTask_returnsNewArray_doesNotMutateInput() {
        let now = Date()
        let task = TaskItem(id: UUID(), title: "T", isCompleted: false, createdAt: now, expiresAt: nil)
        let input = [task]
        _ = TaskListLogic.toggleTask(task, in: input)
        XCTAssertFalse(input.first!.isCompleted)
    }
}

// MARK: - TaskItem tests

final class TaskItemTests: XCTestCase {

    func test_taskItem_encodeDecode_roundtrips() throws {
        let id = UUID()
        let createdAt = Date()
        let expiresAt = Date().addingTimeInterval(3600)
        let task = TaskItem(
            id: id,
            title: "Encoded task",
            isCompleted: true,
            createdAt: createdAt,
            expiresAt: expiresAt
        )
        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(TaskItem.self, from: data)
        XCTAssertEqual(decoded.id, id)
        XCTAssertEqual(decoded.title, "Encoded task")
        XCTAssertEqual(decoded.isCompleted, true)
        XCTAssertEqual(decoded.createdAt.timeIntervalSince1970, createdAt.timeIntervalSince1970, accuracy: 0.001)
//        XCTAssertEqual(decoded.expiresAt?.timeIntervalSince1970, expiresAt.timeIntervalSince1970, accuracy: 0.001)
    }

    func test_taskItem_encodeDecode_withNilExpiry() throws {
        let task = TaskItem(
            id: UUID(),
            title: "No expiry",
            isCompleted: false,
            createdAt: Date(),
            expiresAt: nil
        )
        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(TaskItem.self, from: data)
        XCTAssertEqual(decoded.title, task.title)
        XCTAssertNil(decoded.expiresAt)
    }

    func test_taskItem_identifiable_idIsStable() {
        let id = UUID()
        let task = TaskItem(id: id, title: "T", isCompleted: false, createdAt: Date(), expiresAt: nil)
        XCTAssertEqual(task.id, id)
    }

    func test_taskItem_emptyTitle_encodeDecode() throws {
        let task = TaskItem(id: UUID(), title: "", isCompleted: false, createdAt: Date(), expiresAt: nil)
        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(TaskItem.self, from: data)
        XCTAssertEqual(decoded.title, "")
    }

    func test_taskItem_decodeArray_emptyJSON_returnsEmptyArray() throws {
        let data = "[]".data(using: .utf8)!
        let decoded = try JSONDecoder().decode([TaskItem].self, from: data)
        XCTAssertTrue(decoded.isEmpty)
    }

    func test_taskItem_decodeArray_multipleTasks() throws {
        let id1 = UUID(), id2 = UUID()
        let now = Date()
        let tasks = [
            TaskItem(id: id1, title: "One", isCompleted: false, createdAt: now, expiresAt: nil),
            TaskItem(id: id2, title: "Two", isCompleted: true, createdAt: now, expiresAt: nil)
        ]
        let data = try JSONEncoder().encode(tasks)
        let decoded = try JSONDecoder().decode([TaskItem].self, from: data)
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].id, id1)
        XCTAssertEqual(decoded[0].title, "One")
        XCTAssertEqual(decoded[1].id, id2)
        XCTAssertTrue(decoded[1].isCompleted)
    }

    func test_taskItem_longTitle_encodeDecode() throws {
        let longTitle = String(repeating: "a", count: 10_000)
        let task = TaskItem(id: UUID(), title: longTitle, isCompleted: false, createdAt: Date(), expiresAt: nil)
        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(TaskItem.self, from: data)
        XCTAssertEqual(decoded.title, longTitle)
    }

    func test_taskItem_specialCharactersInTitle_encodeDecode() throws {
        let title = "Task \"quoted\" & <html> \n \t café 日本語"
        let task = TaskItem(id: UUID(), title: title, isCompleted: false, createdAt: Date(), expiresAt: nil)
        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(TaskItem.self, from: data)
        XCTAssertEqual(decoded.title, title)
    }

    func test_taskItem_isCompletedTrue_roundtrips() throws {
        let task = TaskItem(id: UUID(), title: "Done", isCompleted: true, createdAt: Date(), expiresAt: nil)
        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(TaskItem.self, from: data)
        XCTAssertTrue(decoded.isCompleted)
    }

    func test_taskItem_createdAt_roundtrips() throws {
        let createdAt = Date(timeIntervalSince1970: 1000000)
        let task = TaskItem(id: UUID(), title: "T", isCompleted: false, createdAt: createdAt, expiresAt: nil)
        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(TaskItem.self, from: data)
        XCTAssertEqual(decoded.createdAt.timeIntervalSince1970, createdAt.timeIntervalSince1970, accuracy: 0.001)
    }

    func test_taskItem_twoTasks_sameTitle_differentIds() {
        let id1 = UUID(), id2 = UUID()
        let task1 = TaskItem(id: id1, title: "Same", isCompleted: false, createdAt: Date(), expiresAt: nil)
        let task2 = TaskItem(id: id2, title: "Same", isCompleted: true, createdAt: Date(), expiresAt: nil)
        XCTAssertNotEqual(task1.id, task2.id)
        XCTAssertEqual(task1.title, task2.title)
    }

    func test_taskItem_mutableTitle() {
        var task = TaskItem(id: UUID(), title: "Original", isCompleted: false, createdAt: Date(), expiresAt: nil)
        task.title = "Updated"
        XCTAssertEqual(task.title, "Updated")
    }

    func test_taskItem_mutableIsCompleted() {
        var task = TaskItem(id: UUID(), title: "T", isCompleted: false, createdAt: Date(), expiresAt: nil)
        task.isCompleted = true
        XCTAssertTrue(task.isCompleted)
    }

    func test_taskItem_mutableExpiresAt() {
        var task = TaskItem(id: UUID(), title: "T", isCompleted: false, createdAt: Date(), expiresAt: nil)
        let expiry = Date().addingTimeInterval(100)
        task.expiresAt = expiry
        XCTAssertEqual(task.expiresAt, expiry)
    }

    func test_taskItem_equatableById() {
        let id = UUID()
        let d = Date()
        let a = TaskItem(id: id, title: "A", isCompleted: false, createdAt: d, expiresAt: nil)
        let b = TaskItem(id: id, title: "B", isCompleted: true, createdAt: d, expiresAt: nil)
        XCTAssertEqual(a.id, b.id)
    }
}

// MARK: - InMemoryTaskStore tests

final class InMemoryTaskStoreTests: XCTestCase {

    func test_load_empty_returnsEmptyArray() {
        let store = InMemoryTaskStore()
        XCTAssertTrue(store.load().isEmpty)
    }

    func test_saveThenLoad_returnsSavedTasks() {
        let store = InMemoryTaskStore()
        let task = TaskItem(
            id: UUID(),
            title: "Stored",
            isCompleted: false,
            createdAt: Date(),
            expiresAt: nil
        )
        store.save([task])
        let loaded = store.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.title, "Stored")
    }

    func test_save_overwritesPreviousTasks() {
        let store = InMemoryTaskStore()
        let task1 = TaskItem(id: UUID(), title: "First", isCompleted: false, createdAt: Date(), expiresAt: nil)
        let task2 = TaskItem(id: UUID(), title: "Second", isCompleted: false, createdAt: Date(), expiresAt: nil)
        store.save([task1])
        store.save([task2])
        let loaded = store.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.title, "Second")
    }

    func test_save_emptyArray_thenLoad_returnsEmpty() {
        let store = InMemoryTaskStore()
        store.save([])
        XCTAssertTrue(store.load().isEmpty)
    }

    func test_save_multipleTasks_loadReturnsAll() {
        let store = InMemoryTaskStore()
        let task1 = TaskItem(id: UUID(), title: "A", isCompleted: false, createdAt: Date(), expiresAt: nil)
        let task2 = TaskItem(id: UUID(), title: "B", isCompleted: true, createdAt: Date(), expiresAt: nil)
        store.save([task1, task2])
        let loaded = store.load()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded.map(\.title), ["A", "B"])
        XCTAssertFalse(loaded[0].isCompleted)
        XCTAssertTrue(loaded[1].isCompleted)
    }

    func test_load_afterSave_returnsSameContent() {
        let store = InMemoryTaskStore()
        let task = TaskItem(id: UUID(), title: "Same", isCompleted: false, createdAt: Date(), expiresAt: nil)
        store.save([task])
        let first = store.load()
        let second = store.load()
        XCTAssertEqual(first.count, second.count)
        XCTAssertEqual(first.first?.id, second.first?.id)
        XCTAssertEqual(first.first?.title, second.first?.title)
    }

    func test_save_sameArrayTwice_loadUnchanged() {
        let store = InMemoryTaskStore()
        let task = TaskItem(id: UUID(), title: "Once", isCompleted: false, createdAt: Date(), expiresAt: nil)
        let list = [task]
        store.save(list)
        store.save(list)
        let loaded = store.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.title, "Once")
    }

    func test_save_emptyAfterNonEmpty_loadReturnsEmpty() {
        let store = InMemoryTaskStore()
        let task = TaskItem(id: UUID(), title: "Gone", isCompleted: false, createdAt: Date(), expiresAt: nil)
        store.save([task])
        store.save([])
        XCTAssertTrue(store.load().isEmpty)
    }

    func test_save_largeNumberOfTasks_loadReturnsAll() {
        let store = InMemoryTaskStore()
        let tasks = (0..<100).map { i in
            TaskItem(id: UUID(), title: "Task \(i)", isCompleted: i % 2 == 0, createdAt: Date(), expiresAt: nil)
        }
        store.save(tasks)
        let loaded = store.load()
        XCTAssertEqual(loaded.count, 100)
        XCTAssertEqual(loaded[0].title, "Task 0")
        XCTAssertEqual(loaded[99].title, "Task 99")
    }

    func test_load_returnsIndependentCopy() {
        let store = InMemoryTaskStore()
        let task = TaskItem(id: UUID(), title: "Original", isCompleted: false, createdAt: Date(), expiresAt: nil)
        store.save([task])
        var loaded = store.load()
        loaded[0].title = "Mutated"
        let loadedAgain = store.load()
        XCTAssertEqual(loadedAgain.first?.title, "Original")
    }
}

// MARK: - TaskStoring protocol (InMemoryTaskStore conformance)

final class TaskStoringTests: XCTestCase {

    func test_inMemoryTaskStore_conformsToTaskStoring() {
        let store: TaskStoring = InMemoryTaskStore()
        XCTAssertTrue(store.load().isEmpty)
        let task = TaskItem(id: UUID(), title: "P", isCompleted: false, createdAt: Date(), expiresAt: nil)
        store.save([task])
        XCTAssertEqual(store.load().count, 1)
    }

    func test_taskStoring_saveThenLoad_roundtripsContent() {
        let store: TaskStoring = InMemoryTaskStore()
        let id = UUID()
        let tasks = [TaskItem(id: id, title: "Round", isCompleted: true, createdAt: Date(), expiresAt: nil)]
        store.save(tasks)
        let loaded = store.load()
        XCTAssertEqual(loaded.first?.id, id)
        XCTAssertEqual(loaded.first?.title, "Round")
        XCTAssertTrue(loaded.first?.isCompleted ?? false)
    }
}

// MARK: - DateProvider tests

final class DateProviderTests: XCTestCase {

    func test_mockDateProvider_returnsGivenDate() {
        let fixed = Date(timeIntervalSince1970: 1234567890)
        let provider = MockDateProvider(date: fixed)
        XCTAssertEqual(provider.now(), fixed)
    }

    func test_mockDateProvider_differentDates_returnCorrectly() {
        let d1 = Date(timeIntervalSince1970: 0)
        let d2 = Date(timeIntervalSince1970: 999999)
        XCTAssertEqual(MockDateProvider(date: d1).now(), d1)
        XCTAssertEqual(MockDateProvider(date: d2).now(), d2)
    }

    func test_systemDateProvider_returnsDateNearNow() {
        let provider = SystemDateProvider()
        let before = Date()
        let result = provider.now()
        let after = Date()
        XCTAssertGreaterThanOrEqual(result.timeIntervalSince1970, before.timeIntervalSince1970 - 1)
        XCTAssertLessThanOrEqual(result.timeIntervalSince1970, after.timeIntervalSince1970 + 1)
    }
}

// MARK: - AddTaskView / AddTaskLogic tests

final class AddTaskViewTests: XCTestCase {

    func test_mergeTimeWithToday_setsHourAndMinuteOnToday() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.date(from: DateComponents(year: 2025, month: 2, day: 19))!
        let time = cal.date(from: DateComponents(hour: 14, minute: 30))!
        let result = AddTaskLogic.mergeTimeWithToday(time, calendar: cal, today: today)
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: result)
        XCTAssertEqual(comps.year, 2025)
        XCTAssertEqual(comps.month, 2)
        XCTAssertEqual(comps.day, 19)
        XCTAssertEqual(comps.hour, 14)
        XCTAssertEqual(comps.minute, 30)
    }

    func test_mergeTimeWithToday_midnight() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.date(from: DateComponents(year: 2025, month: 2, day: 19))!
        let time = cal.date(from: DateComponents(hour: 0, minute: 0))!
        let result = AddTaskLogic.mergeTimeWithToday(time, calendar: cal, today: today)
        let comps = cal.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(comps.hour, 0)
        XCTAssertEqual(comps.minute, 0)
    }

    func test_mergeTimeWithToday_endOfDay_23_59() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.date(from: DateComponents(year: 2025, month: 2, day: 19))!
        let time = cal.date(from: DateComponents(hour: 23, minute: 59))!
        let result = AddTaskLogic.mergeTimeWithToday(time, calendar: cal, today: today)
        let comps = cal.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(comps.hour, 23)
        XCTAssertEqual(comps.minute, 59)
    }

    func test_canSubmit_emptyTitle_returnsFalse() {
        XCTAssertFalse(AddTaskLogic.canSubmit(title: ""))
    }

    func test_canSubmit_whitespaceOnly_returnsFalse() {
        XCTAssertFalse(AddTaskLogic.canSubmit(title: "   "))
        XCTAssertFalse(AddTaskLogic.canSubmit(title: "\n\t"))
    }

    func test_canSubmit_nonEmptyTitle_returnsTrue() {
        XCTAssertTrue(AddTaskLogic.canSubmit(title: "Task"))
        XCTAssertTrue(AddTaskLogic.canSubmit(title: " a "))
    }

    func test_canSubmit_singleCharacter_returnsTrue() {
        XCTAssertTrue(AddTaskLogic.canSubmit(title: "x"))
    }

    func test_mergeTimeWithToday_usesProvidedCalendarAndToday() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.date(from: DateComponents(year: 2030, month: 12, day: 31))!
        let time = cal.date(from: DateComponents(hour: 11, minute: 45))!
        let result = AddTaskLogic.mergeTimeWithToday(time, calendar: cal, today: today)
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: result)
        XCTAssertEqual(comps.year, 2030)
        XCTAssertEqual(comps.month, 12)
        XCTAssertEqual(comps.day, 31)
        XCTAssertEqual(comps.hour, 11)
        XCTAssertEqual(comps.minute, 45)
    }

    func test_mergeTimeWithToday_secondsAreZero() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.date(from: DateComponents(year: 2025, month: 6, day: 15))!
        let time = cal.date(from: DateComponents(hour: 10, minute: 30, second: 59))!
        let result = AddTaskLogic.mergeTimeWithToday(time, calendar: cal, today: today)
        let sec = cal.component(.second, from: result)
        XCTAssertEqual(sec, 0)
    }

    func test_canSubmit_titleWithNewlines_trimmedThenNonEmpty_returnsTrue() {
        XCTAssertTrue(AddTaskLogic.canSubmit(title: "  real title  "))
        XCTAssertFalse(AddTaskLogic.canSubmit(title: "\n\n"))
    }

    func test_canSubmit_unicodeAndEmoji_returnsTrue() {
        XCTAssertTrue(AddTaskLogic.canSubmit(title: "Café"))
        XCTAssertTrue(AddTaskLogic.canSubmit(title: "Task ✓"))
        XCTAssertTrue(AddTaskLogic.canSubmit(title: "📋 Reminder"))
    }

    func test_canSubmit_tabsOnly_trimmedEmpty_returnsFalse() {
        XCTAssertFalse(AddTaskLogic.canSubmit(title: "\t"))
    }

    func test_mergeTimeWithToday_resultIsOnSameDayAsToday() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.date(from: DateComponents(year: 2025, month: 3, day: 10))!
        let time = cal.date(from: DateComponents(hour: 9, minute: 15))!
        let result = AddTaskLogic.mergeTimeWithToday(time, calendar: cal, today: today)
        XCTAssertTrue(cal.isDate(result, inSameDayAs: today))
    }

    func test_mergeTimeWithToday_defaultParameters_usesCurrentCalendarAndToday() {
        let time = Date()
        let result = AddTaskLogic.mergeTimeWithToday(time)
        let cal = Calendar.current
        XCTAssertTrue(cal.isDate(result, inSameDayAs: Date()))
        let comps = cal.dateComponents([.hour, .minute], from: time)
        let resultComps = cal.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(resultComps.hour, comps.hour)
        XCTAssertEqual(resultComps.minute, comps.minute)
    }

    func test_mergeTimeWithToday_noon() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.date(from: DateComponents(year: 2025, month: 7, day: 4))!
        let time = cal.date(from: DateComponents(hour: 12, minute: 0))!
        let result = AddTaskLogic.mergeTimeWithToday(time, calendar: cal, today: today)
        let comps = cal.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(comps.hour, 12)
        XCTAssertEqual(comps.minute, 0)
    }
}

// MARK: - TaskRowView / TaskRowLogic tests

final class TaskRowViewTests: XCTestCase {

    func test_iconName_incomplete_returnsCircle() {
        XCTAssertEqual(TaskRowLogic.iconName(isCompleted: false), "circle")
    }

    func test_iconName_completed_returnsCheckmarkCircleFill() {
        XCTAssertEqual(TaskRowLogic.iconName(isCompleted: true), "checkmark.circle.fill")
    }

    func test_shouldStrikethrough_incomplete_returnsFalse() {
        XCTAssertFalse(TaskRowLogic.shouldStrikethrough(isCompleted: false))
    }

    func test_shouldStrikethrough_completed_returnsTrue() {
        XCTAssertTrue(TaskRowLogic.shouldStrikethrough(isCompleted: true))
    }
}

// MARK: - NotificationManager / TaskNotificationContent tests

final class NotificationManagerTests: XCTestCase {

    func test_taskNotificationContent_fromTaskWithExpiry_returnsContent() {
        let id = UUID()
        let expiresAt = Date().addingTimeInterval(3600)
        let task = TaskItem(id: id, title: "Buy milk", isCompleted: false, createdAt: Date(), expiresAt: expiresAt)
        let content = TaskNotificationContent.from(task: task)
        XCTAssertNotNil(content)
        XCTAssertEqual(content!.title, "Task Reminder")
        XCTAssertEqual(content!.body, "Buy milk")
        XCTAssertEqual(content!.identifier, id.uuidString)
        XCTAssertNotNil(content!.dateComponents.year)
        XCTAssertNotNil(content!.dateComponents.hour)
    }

    func test_taskNotificationContent_fromTaskWithoutExpiry_returnsNil() {
        let task = TaskItem(id: UUID(), title: "No expiry", isCompleted: false, createdAt: Date(), expiresAt: nil)
        let content = TaskNotificationContent.from(task: task)
        XCTAssertNil(content)
    }

    func test_taskNotificationContent_reminderTitleConstant() {
        XCTAssertEqual(TaskNotificationContent.reminderTitle, "Task Reminder")
    }

    func test_taskNotificationContent_bodyIsTaskTitle() {
        let task = TaskItem(id: UUID(), title: "Custom title", isCompleted: false, createdAt: Date(), expiresAt: Date())
        let content = TaskNotificationContent.from(task: task)
        XCTAssertEqual(content?.body, "Custom title")
    }

    func test_taskNotificationContent_identifierIsTaskId() {
        let id = UUID()
        let task = TaskItem(id: id, title: "T", isCompleted: false, createdAt: Date(), expiresAt: Date())
        let content = TaskNotificationContent.from(task: task)
        XCTAssertEqual(content?.identifier, id.uuidString)
    }

    func test_taskNotificationContent_dateComponents_matchExpiresAt() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let expiresAt = cal.date(from: DateComponents(year: 2025, month: 3, day: 1, hour: 9, minute: 15))!
        let task = TaskItem(id: UUID(), title: "T", isCompleted: false, createdAt: Date(), expiresAt: expiresAt)
        let content = TaskNotificationContent.from(task: task, calendar: cal)
        XCTAssertNotNil(content)
        XCTAssertEqual(content!.dateComponents.year, 2025)
        XCTAssertEqual(content!.dateComponents.month, 3)
        XCTAssertEqual(content!.dateComponents.day, 1)
        XCTAssertEqual(content!.dateComponents.hour, 9)
        XCTAssertEqual(content!.dateComponents.minute, 15)
    }

    func test_taskNotificationContent_emptyTaskTitle_bodyIsEmpty() {
        let task = TaskItem(id: UUID(), title: "", isCompleted: false, createdAt: Date(), expiresAt: Date())
        let content = TaskNotificationContent.from(task: task)
        XCTAssertEqual(content?.body, "")
    }

    func test_taskNotificationContent_differentCalendars_produceSameIdentifier() {
        let id = UUID()
        let task = TaskItem(id: id, title: "T", isCompleted: false, createdAt: Date(), expiresAt: Date())
        let c1 = TaskNotificationContent.from(task: task, calendar: Calendar(identifier: .gregorian))
        var iso = Calendar(identifier: .gregorian)
        iso.timeZone = TimeZone(identifier: "UTC")!
        let c2 = TaskNotificationContent.from(task: task, calendar: iso)
        XCTAssertEqual(c1?.identifier, id.uuidString)
        XCTAssertEqual(c2?.identifier, id.uuidString)
    }
}

// MARK: - TaskNotificationScheduling spy (tests protocol usage without UNUserNotificationCenter)

final class NotificationSchedulerSpyTests: XCTestCase {

    func test_spy_recordsScheduleCalls() {
        let spy = NotificationSchedulerSpy()
        let task = TaskItem(id: UUID(), title: "Scheduled", isCompleted: false, createdAt: Date(), expiresAt: Date())
        spy.schedule(for: task)
        XCTAssertEqual(spy.scheduledTaskIds.count, 1)
        XCTAssertEqual(spy.scheduledTaskIds.first, task.id)
    }

    func test_spy_recordsCancelCalls() {
        let spy = NotificationSchedulerSpy()
        let task = TaskItem(id: UUID(), title: "Cancelled", isCompleted: false, createdAt: Date(), expiresAt: nil)
        spy.cancel(for: task)
        XCTAssertEqual(spy.cancelledTaskIds.count, 1)
        XCTAssertEqual(spy.cancelledTaskIds.first, task.id)
    }

    func test_spy_scheduleWithNoExpiry_doesNotRecord() {
        let spy = NotificationSchedulerSpy()
        let task = TaskItem(id: UUID(), title: "No expiry", isCompleted: false, createdAt: Date(), expiresAt: nil)
        spy.schedule(for: task)
        XCTAssertTrue(spy.scheduledTaskIds.isEmpty)
    }

    func test_spy_multipleScheduleCalls_recordsAll() {
        let spy = NotificationSchedulerSpy()
        let t1 = TaskItem(id: UUID(), title: "A", isCompleted: false, createdAt: Date(), expiresAt: Date())
        let t2 = TaskItem(id: UUID(), title: "B", isCompleted: false, createdAt: Date(), expiresAt: Date())
        spy.schedule(for: t1)
        spy.schedule(for: t2)
        XCTAssertEqual(spy.scheduledTaskIds.count, 2)
        XCTAssertEqual(spy.scheduledTaskIds[0], t1.id)
        XCTAssertEqual(spy.scheduledTaskIds[1], t2.id)
    }

    func test_spy_cancelSameTaskTwice_recordsBoth() {
        let spy = NotificationSchedulerSpy()
        let task = TaskItem(id: UUID(), title: "T", isCompleted: false, createdAt: Date(), expiresAt: nil)
        spy.cancel(for: task)
        spy.cancel(for: task)
        XCTAssertEqual(spy.cancelledTaskIds.count, 2)
    }
}

/// Spy that conforms to TaskNotificationScheduling and records calls (for testing callers).
final class NotificationSchedulerSpy: TaskNotificationScheduling {
    private(set) var scheduledTaskIds: [UUID] = []
    private(set) var cancelledTaskIds: [UUID] = []

    func schedule(for task: TaskItem) {
        guard task.expiresAt != nil else { return }
        scheduledTaskIds.append(task.id)
    }

    func cancel(for task: TaskItem) {
        cancelledTaskIds.append(task.id)
    }
}


// MARK: - Integration (AddTaskLogic + TaskListLogic + store)

final class IntegrationTests: XCTestCase {

    func test_addTaskFlow_mergeTimeFilterAndPersist() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.date(from: DateComponents(year: 2025, month: 2, day: 20))!
        let pickerTime = cal.date(from: DateComponents(hour: 15, minute: 0))!
        let expiresAt = AddTaskLogic.mergeTimeWithToday(pickerTime, calendar: cal, today: today)
        let task = TaskItem(
            id: UUID(),
            title: "Meeting",
            isCompleted: false,
            createdAt: today,
            expiresAt: expiresAt
        )
        let store = InMemoryTaskStore()
        store.save([task])
        let filtered = TaskListLogic.filterIndividuallyExpired(store.load(), now: today)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "Meeting")
        let dayFiltered = TaskListLogic.filterExpiredDayTasks(filtered, now: today)
        XCTAssertEqual(dayFiltered.count, 1)
    }

    func test_emptyTitle_cannotSubmit_consistentWithCanSubmit() {
        XCTAssertFalse(AddTaskLogic.canSubmit(title: ""))
    }
}
