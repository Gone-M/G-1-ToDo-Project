import SwiftUI


struct ContentView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingAddTask = false
    @State private var showingAddTaskType = false
    @State private var selectedFilter: TaskStatus?
    
    var filteredTasks: [Task] {
        guard let filter = selectedFilter else { return viewModel.tasks }
        return viewModel.tasks.filter { $0.status == filter }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            FilterChip(
                                title: status.rawValue,
                                isSelected: selectedFilter == status,
                                color: status.color
                            ) {
                                if selectedFilter == status {
                                    selectedFilter = nil
                                } else {
                                    selectedFilter = status
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                List {
                    ForEach(filteredTasks) { task in
                        TaskRow(task: task, viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingAddTaskType = true }) {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddTaskType) {
                AddTaskTypeView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - TaskRow

struct TaskRow: View {
    let task: Task
    let viewModel: TaskViewModel
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack {
                Circle()
                    .fill(task.taskType.color)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                    
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Image(systemName: "clock")
                        Text(task.dueDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    StatusBadge(status: task.status)
                    PriorityBadge(priority: task.priority)
                }
            }
            .padding(.vertical, 8)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteTask(task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingDetail) {
            TaskDetailView(task: task, viewModel: viewModel)
        }
    }
}

// MARK: - StatusBadge

struct StatusBadge: View {
    let status: TaskStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .clipShape(Capsule())
    }
}

// MARK: - PriorityBadge

struct PriorityBadge: View {
    let priority: TaskPriority
    
    var body: some View {
        HStack {
            ForEach(0..<priorityLevel, id: \.self) { _ in
                Circle()
                    .fill(priorityColor)
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    private var priorityLevel: Int {
        switch priority {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.2))
                .foregroundColor(isSelected ? .white : color)
                .clipShape(Capsule())
        }
    }
}

// MARK: - AddTaskView

struct AddTaskView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var selectedTaskType: TaskType?
    @State private var priority = TaskPriority.medium
    @State private var tags = ""
    @State private var reminderDate: Date?
    @State private var showingReminderPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Task Type")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.taskTypes) { type in
                                TaskTypeButton(
                                    type: type,
                                    isSelected: selectedTaskType?.id == type.id,
                                    action: { selectedTaskType = type }
                                )
                            }
                        }
                    }
                }
                
                Section(header: Text("Date and Time")) {
                    DatePicker("Due Date", selection: $dueDate)
                    
                    Toggle("Set Reminder", isOn: .init(
                        get: { showingReminderPicker },
                        set: { newValue in
                            showingReminderPicker = newValue
                            if !newValue {
                                reminderDate = nil
                            }
                        }
                    ))
                    
                    if showingReminderPicker {
                        DatePicker("Reminder", selection: .init(
                            get: { reminderDate ?? dueDate },
                            set: { reminderDate = $0 }
                        ))
                    }
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Tags")) {
                    TextField("Add tags (comma separated)", text: $tags)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        guard let taskType = selectedTaskType else { return }
                        let tagSet = Set(tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                        
                        viewModel.addTask(
                            title: title,
                            description: description,
                            dueDate: dueDate,
                            taskType: taskType,
                            priority: priority,
                            tags: tagSet,
                            reminderDate: reminderDate
                        )
                        dismiss()
                    }
                    .disabled(title.isEmpty || selectedTaskType == nil)
                }
            }
        }
    }
}

// MARK: - TaskTypeButton

struct TaskTypeButton: View {
    let type: TaskType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                Text(type.name)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .frame(width: 100, height: 80)
            .background(isSelected ? type.color : type.color.opacity(0.2))
            .foregroundColor(isSelected ? .white : type.color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - TaskDetailView

struct TaskDetailView: View {
    let task: Task
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingEditTask = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with task icon and color
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: task.taskType.icon)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(task.taskType.color)
                        .clipShape(Circle())
                        .shadow(color: task.taskType.color.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(task.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        Text(task.taskType.name)
                            .font(.subheadline)
                            .foregroundColor(task.taskType.color)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal)
                
                // Description Card
                Group {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.headline)
                            .foregroundColor(task.taskType.color)
                        
                        if task.description.isEmpty {
                            Text("No description")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            Text(task.description)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .padding(.horizontal)
                }
                
                // Dates Card
                Group {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Dates", systemImage: "calendar")
                            .font(.headline)
                            .foregroundColor(task.taskType.color)
                        
                        EnhancedDateInfoRow(
                            title: "Due Date",
                            date: task.dueDate,
                            icon: "calendar",
                            color: task.taskType.color
                        )
                        
                        if let reminderDate = task.reminderDate {
                            EnhancedDateInfoRow(
                                title: "Reminder",
                                date: reminderDate,
                                icon: "bell.fill",
                                color: task.taskType.color
                            )
                        }
                        
                        if let completedDate = task.completedDate {
                            EnhancedDateInfoRow(
                                title: "Completed",
                                date: completedDate,
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .padding(.horizontal)
                }
                
                // Tags Card
                if !task.tags.isEmpty {
                    Group {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Tags", systemImage: "tag")
                                .font(.headline)
                                .foregroundColor(task.taskType.color)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(Array(task.tags), id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Image(systemName: "number")
                                            .font(.caption)
                                        Text(tag)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(task.taskType.color.opacity(0.15))
                                    .foregroundColor(task.taskType.color)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    if task.status != .completed {
                        Button(action: {
                            viewModel.completeTask(task)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark as Completed")
                                    .fontWeight(.semibold)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(task.taskType.color)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: task.taskType.color.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                    } else {
                        Button(action: {
                            viewModel.revertTaskCompletion(task)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                Text("Remove Completed Status")
                                    .fontWeight(.semibold)
                            }
                            .font(.headline)
                            .foregroundColor(task.taskType.color)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(task.taskType.color.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    Button(action: {
                        // Açıklama: Düzenleme görünümünü sunmak için
                        showingEditTask = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.pencil")
                            Text("Edit Task")
                        }
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                        )
                    }
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showingEditTask) {
            EditTaskView(task: task, viewModel: viewModel)
        }
    }
}

// MARK: - EnhancedDateInfoRow

struct EnhancedDateInfoRow: View {
    let title: String
    let date: Date
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(date.formatted(date: .long, time: .shortened))
                    .font(.body)
            }
        }
    }
}

// MARK: - AddTaskTypeView

struct AddTaskTypeView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var selectedIcon = "star"
    @State private var selectedColor = Color.blue
    
    let icons = [
        "star", "heart", "person", "house", "cart", "book", "briefcase",
        "car", "airplane", "phone", "bolt", "flag", "gift", "tag", "moon",
        "sun.max", "leaf", "hammer", "wand.and.stars", "gamecontroller"
    ]
    
    let colorOptions: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink,
        .yellow, .mint, .cyan, .indigo, .teal
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with preview
                HStack {
                    Image(systemName: selectedIcon)
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(selectedColor)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text(name.isEmpty ? "New Task Type" : name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading)
                    
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                
                Form {
                    Section(header: Text("Task Type Details")) {
                        TextField("Name", text: $name)
                            .padding(.vertical, 8)
                    }
                    
                    Section(header: Text("Icon Selection")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(icons, id: \.self) { icon in
                                    Button(action: {
                                        selectedIcon = icon
                                    }) {
                                        VStack {
                                            Image(systemName: icon)
                                                .font(.title)
                                                .frame(width: 48, height: 48)
                                                .foregroundColor(selectedIcon == icon ? .white : .primary)
                                                .background(selectedIcon == icon ? selectedColor : Color(UIColor.systemGray5))
                                                .clipShape(Circle())
                                            
                                            Text(icon.replacingOccurrences(of: ".", with: " "))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 60)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    Section(header: Text("Color")) {
                        VStack(alignment: .leading, spacing: 16) {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                                ForEach(colorOptions, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                                .padding(2)
                                                .opacity(selectedColor == color ? 1 : 0)
                                        )
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .opacity(selectedColor == color ? 1 : 0)
                                        )
                                        .onTapGesture {
                                            selectedColor = color
                                        }
                                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                }
                            }
                            
                            ColorPicker("Select custom color", selection: $selectedColor)
                                .padding(.top, 8)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("New Task Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newType = TaskType(
                            name: name,
                            icon: selectedIcon,
                            color: selectedColor
                        )
                        viewModel.addTaskType(newType)
                        dismiss()
                    }
                    .font(.headline)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - EditTaskView

/// Yeni özellik: Mevcut görevin düzenlenmesi için görünüm.
struct EditTaskView: View {
    let task: Task
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date
    @State private var selectedTaskType: TaskType
    @State private var priority: TaskPriority
    @State private var tags: String
    @State private var reminderDate: Date?
    @State private var showingReminderPicker: Bool
    
    init(task: Task, viewModel: TaskViewModel) {
        self.task = task
        self.viewModel = viewModel
        // Initialize state with the current task values
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        _dueDate = State(initialValue: task.dueDate)
        _selectedTaskType = State(initialValue: task.taskType)
        _priority = State(initialValue: task.priority)
        _tags = State(initialValue: task.tags.joined(separator: ", "))
        _reminderDate = State(initialValue: task.reminderDate)
        _showingReminderPicker = State(initialValue: task.reminderDate != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Task Type")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.taskTypes) { type in
                                TaskTypeButton(
                                    type: type,
                                    isSelected: selectedTaskType.id == type.id,
                                    action: { selectedTaskType = type }
                                )
                            }
                        }
                    }
                }
                
                Section(header: Text("Date and Time")) {
                    DatePicker("Due Date", selection: $dueDate)
                    
                    Toggle("Set Reminder", isOn: .init(
                        get: { showingReminderPicker },
                        set: { newValue in
                            showingReminderPicker = newValue
                            if !newValue {
                                reminderDate = nil
                            }
                        }
                    ))
                    
                    if showingReminderPicker {
                        DatePicker("Reminder", selection: .init(
                            get: { reminderDate ?? dueDate },
                            set: { reminderDate = $0 }
                        ))
                    }
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Tags")) {
                    TextField("Add tags (comma separated)", text: $tags)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Düzenlenmiş görevi güncelle
                        let tagSet = Set(tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                        var updatedTask = task
                        updatedTask.title = title
                        updatedTask.description = description
                        updatedTask.dueDate = dueDate
                        updatedTask.taskType = selectedTaskType
                        updatedTask.priority = priority
                        updatedTask.tags = tagSet
                        updatedTask.reminderDate = reminderDate
                        
                        viewModel.updateTask(updatedTask)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
