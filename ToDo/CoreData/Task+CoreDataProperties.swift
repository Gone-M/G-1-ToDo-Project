//
//  Task+CoreDataProperties.swift
//  ToDo
//
//  Created by Civan Metin on 2025-01-19.
//

import Foundation
import CoreData

extension TaskEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var taskDescription: String?
    @NSManaged public var dueDate: Date?
    @NSManaged public var taskTypeName: String?
    @NSManaged public var status: String?
    @NSManaged public var priority: String?
    @NSManaged public var tags: String?
    @NSManaged public var completedDate: Date?
    @NSManaged public var reminderDate: Date?
}
