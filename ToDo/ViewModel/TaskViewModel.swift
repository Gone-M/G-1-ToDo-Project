import Foundation
import Combine
import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var taskTypes: [TaskType] = [
        TaskType(name: "Work", icon: "briefcase", color: .blue),
        TaskType(name: "Personal", icon: "person", color: .green),
        TaskType(name: "Shopping", icon: "cart", color: .purple),
        TaskType(name: "Health", icon: "heart", color: .red)
    ]
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupTimer()
        // Uygulama foreground oldugunda durum güncellemesi yap
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.updateStatuses()
            }
            .store(in: &cancellables)
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    private func setupTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.updateStatuses()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func addTask(title: String, description: String, dueDate: Date, taskType: TaskType, priority: TaskPriority, tags: Set<String>, reminderDate: Date?) {
        let status = determineStatus(dueDate: dueDate)
        let newTask = Task(
            title: title,
            description: description,
            dueDate: dueDate,
            taskType: taskType,
            status: status,
            priority: priority,
            tags: tags,
            reminderDate: reminderDate
        )
        tasks.append(newTask)
        sortTasks()
        
        if let _ = reminderDate {
            NotificationManager.shared.scheduleTaskReminder(for: newTask)
        }
    }
    
    func addTaskType(_ type: TaskType) {
        guard !taskTypes.contains(where: { $0.name == type.name }) else { return }
        taskTypes.append(type)
        objectWillChange.send()
    }
    
    func deleteTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            NotificationManager.shared.cancelTaskReminder(for: task)
            tasks.remove(at: index)
            objectWillChange.send()
        }
    }
    
    func determineStatus(dueDate: Date) -> TaskStatus {
        let now = Date()
        if dueDate < now {
            return .overdue
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: now, to: dueDate)
        if let hours = components.hour, hours <= 24 {
            return .closeToDueDate
        }
        return .pending
    }
    
    func updateStatuses() {
        var needsUpdate = false
        tasks = tasks.map { task in
            var updatedTask = task
            if task.status != .completed {
                let newStatus = determineStatus(dueDate: task.dueDate)
                if newStatus != task.status {
                    updatedTask.status = newStatus
                    needsUpdate = true
                }
            }
            return updatedTask
        }
        if needsUpdate {
            objectWillChange.send()
            sortTasks()
        }
    }
    
    func completeTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            updatedTask.status = .completed
            updatedTask.completedDate = Date()
            tasks[index] = updatedTask
            
            NotificationManager.shared.cancelTaskReminder(for: task)
            
            objectWillChange.send()
            sortTasks()
        }
    }
    
    /// Yeni özellik: Tamamlanan görevin durumunu geri alma.
    func revertTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            updatedTask.status = determineStatus(dueDate: task.dueDate)
            updatedTask.completedDate = nil
            tasks[index] = updatedTask
            
            objectWillChange.send()
            sortTasks()
        }
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            if let _ = task.reminderDate {
                NotificationManager.shared.cancelTaskReminder(for: task)
                NotificationManager.shared.scheduleTaskReminder(for: task)
            }
            objectWillChange.send()
            sortTasks()
        }
    }
    
    private func sortTasks() {
        tasks.sort { task1, task2 in
            if task1.priority != task2.priority {
                return task1.priority.rawValue > task2.priority.rawValue
            }
            return task1.dueDate < task2.dueDate
        }
    }
    
    func tasksForStatus(_ status: TaskStatus) -> [Task] {
        tasks.filter { $0.status == status }
    }
    
    func tasksForType(_ type: TaskType) -> [Task] {
        tasks.filter { $0.taskType.id == type.id }
    }
    
    func tasksWithTag(_ tag: String) -> [Task] {
        tasks.filter { $0.tags.contains(tag) }
    }
    
    func overdueTasks() -> [Task] {
        tasks.filter { $0.status == .overdue }
    }
    
    func upcomingTasks(within days: Int = 7) -> [Task] {
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .day, value: days, to: Date())!
        return tasks.filter { task in
            task.status != .completed &&
            task.dueDate <= futureDate &&
            task.status != .overdue
        }
    }
}
