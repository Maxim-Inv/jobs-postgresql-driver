//
//  File.swift
//  
//
//  Created by Maxim Anisimov on 14.04.2020.
//

import Vapor
import Fluent
import Queues

enum JobState: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
}

public final class JobModel: Model, Content {
    
    public static let schema = "job"
    
    @ID(custom: "id")
    public var id: Int?
    
    /// The Job key
    @Field(key: "key")
    var key: String
        
    /// The Job data
    @Field(key: "data")
    var data: Data
    
    /// The current state of the Job
    @Field(key: "state")
    var state: String
    
    /// The created timestamp
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    /// The updated timestamp
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
    
    /// Codable keys
    enum CodingKeys: String, CodingKey {
        case id
        case key
        case jobId = "job_id"
        case data
        case state
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init() {
    }
    
    init(key: String,
         data: Data,
         state: JobState = .pending,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.key = key
        self.data = data
        self.state = state.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
