import SwiftUI

enum TaskPriority: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

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

struct TaskType: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var icon: String // SF Symbol name
    var color: Color
}

struct Task: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    var dueDate: Date
    var taskType: TaskType
    var status: TaskStatus
    var priority: TaskPriority
    var tags: Set<String>
    var completedDate: Date?
    var reminderDate: Date?
}
