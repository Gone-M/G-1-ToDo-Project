import SwiftUI

// MARK: - Priority

enum TaskPriority: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

// MARK: -Status

enum TaskStatus: String, CaseIterable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
    case overdue = "Overdue"
    case closeToDueDate = "Close to Due Date"
    
    var color: Color {
        switch self {
        case .pending: return .blue
        case .inProgress: return .yellow
        case .completed: return .green
        case .overdue: return .red
        case .closeToDueDate: return .orange
        }
    }
}

// MARK: - Task Type

struct TaskType: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var icon: String // SF Symbol name
    var color: Color
}

// MARK: - Task Model

struct Task: Identifiable {
    let id: UUID
    var title: String
    var description: String
    var dueDate: Date
    var taskType: TaskType
    var status: TaskStatus
    var priority: TaskPriority
    var tags: Set<String>
    var completedDate: Date?
    var reminderDate: Date?
    
    init(id: UUID = UUID(),
         title: String,
         description: String,
         dueDate: Date,
         taskType: TaskType,
         status: TaskStatus,
         priority: TaskPriority,
         tags: Set<String>,
         completedDate: Date? = nil,
         reminderDate: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.taskType = taskType
        self.status = status
        self.priority = priority
        self.tags = tags
        self.completedDate = completedDate
        self.reminderDate = reminderDate
    }
}
