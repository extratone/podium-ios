//
//  StoryStatsModel.swift
//  outsider
//
//  Created by Michael Jach on 18/09/2024.
//

import Foundation

struct StoryStatsModel: Codable, Equatable {
  let uuid: UUID
  let viewed_by: UUID
  let story_uuid: UUID
}
