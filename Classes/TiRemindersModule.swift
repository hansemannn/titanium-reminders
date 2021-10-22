//
//  TiRemindersModule.swift
//  titanium-reminders
//
//  Created by Hans Knöchel
//  Copyright (c) 2021 Hans Knöchel. All rights reserved.
//

import UIKit
import EventKit
import TitaniumKit

@objc(TiRemindersModule)
class TiRemindersModule: TiModule {

  var eventStore: EKEventStore!
  
  func moduleGUID() -> String {
    return "1364eb96-f2c1-4e9c-9207-6fda5db80c53"
  }
  
  override func moduleId() -> String! {
    return "ti.reminders"
  }

  override func _configure() {
    super._configure()
    eventStore = EKEventStore()
  }

  ///
  /// Request reminders permissions
  ///
  @objc(requestRemindersPermissions:)
  func requestRemindersPermissions(unused: Any?) -> JSValue? {
    let promise = KrollPromise(in: currentContext())
    
    self.eventStore.requestAccess(to: .reminder) { success, error in
      guard success else {
        promise?.resolve([false])
        return
      }
  
      promise?.resolve([true])
    }
    
    return promise?.jsValue
  }

  ///
  /// Fetch an array of reminders (mapped as objects)
  ///
  @objc(fetchReminders:)
  func fetchReminders(unused: Any) -> JSValue? {
    let promise = KrollPromise(in: currentContext())

    let predicate = self.eventStore.predicateForReminders(in: nil)
    self.eventStore.fetchReminders(matching: predicate) { (reminders: [EKReminder]?) in
      guard let reminders = reminders else {
        promise?.resolve([[]])
        return
      }

      var mappedReminders: [[String: Any]] = []
      for reminder in reminders {
        var element: [String: Any] = [
          "identifier": reminder.calendarItemIdentifier,
          "list": reminder.calendar.title,
          "completed": reminder.isCompleted,
          "priority": reminder.priority
        ]
  
        // Append optional title
        if let title = reminder.title {
          element["title"] = title
        }

        // Append optional start date
        if let startDate = reminder.startDateComponents?.date {
          element["startDate"] = startDate
        }
        
        // Append optional due date
        if let dueDate = reminder.dueDateComponents?.date {
          element["dueDate"] = dueDate
        }
        
        // Append optional completion date
        if let completionDate = reminder.completionDate {
          element["completionDate"] = completionDate
        }
        mappedReminders.append(element)
      }

      promise?.resolve([mappedReminders])
    }

    return promise?.jsValue
  }

  ///
  /// Update a reminder (currently only marks it as completed)
  ///
  @objc(updateReminder:)
  func updateReminder(identifier: [Any]) -> JSValue? {
    guard let identifier = identifier.first as? String else { return nil }

    let promise = KrollPromise(in: currentContext())
    let predicate = self.eventStore.predicateForReminders(in: nil)

    self.eventStore.fetchReminders(matching: predicate) { (reminders: [EKReminder]?) in
      guard let reminders = reminders else {
        promise?.reject([["success": false, "error": "Cannot get reminders"]])
        return
      }

      if let reminder = reminders.first(where: { $0.calendarItemIdentifier == identifier }) {
        reminder.isCompleted = true
        try! self.eventStore.save(reminder, commit: true)
        promise?.resolve([["success": true]])
      }
    }
    
    return promise?.jsValue
  }

  ///
  /// Remove a reminder completely
  ///
  @objc(removeReminder:)
  func removeReminder(identifier: [Any]) -> JSValue? {
    guard let identifier = identifier.first as? String else { return nil }

    let promise = KrollPromise(in: currentContext())
    let predicate = self.eventStore.predicateForReminders(in: nil)

    self.eventStore.fetchReminders(matching: predicate) { (reminders: [EKReminder]?) in
      guard let reminders = reminders else {
        promise?.reject([["success": false, "error": "Cannot get reminders"]])
        return
      }

      if let reminder = reminders.first(where: { $0.calendarItemIdentifier == identifier }) {
        try! self.eventStore.remove(reminder, commit: true)
        promise?.resolve([["success": true]])
      }
    }
    
    return promise?.jsValue
  }
}
