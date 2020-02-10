//
//  JobsPostgreSQLDriver.swift
//  App
//
//  Created by TJ on 14/02/2019.
//

import Foundation
import Vapor
import Jobs
import FluentPostgresDriver
import NIO
import Fluent
import FluentSQL

extension Application.Jobs.Provider {
    
    public static func postgre(deleteCompletedJobs: Bool = false) -> Self {
        .init { (application: Application) in
            application.jobs.use(custom: JobsPostgreSQLDriver.init(databases: application.databases, deleteCompletedJobs: deleteCompletedJobs, on: application.eventLoopGroup))
        }
    }
}

public struct JobsPostgreSQLDriver {
    let logger = Logger(label: "codes.vapor.postgres")
    /// Completed jobs should be deleted
    public let deleteCompletedJobs: Bool
    public let databases: Databases
    
    public init(databases: Databases, deleteCompletedJobs: Bool, on eventLoopGroup: EventLoopGroup) {
        self.deleteCompletedJobs = deleteCompletedJobs
        self.databases = databases
    }
}

extension JobsPostgreSQLDriver: JobsDriver {
    
    public func makeQueue(with context: JobContext) -> JobsQueue {
        _JobsPosgtresQueue(
            database: self.databases.database(.psql, logger: logger, on: context.eventLoop)!,
            deleteCompletedJobs: deleteCompletedJobs,
            context: context
        )
    }
    
    public func shutdown() {
        //self.pool.shutdown()
    }
}

struct _JobsPosgtresQueue {
    let database: Database
    let deleteCompletedJobs: Bool
    let context: JobContext
}

enum _JobsPosgtresError: Error {
    case missingJob
    case invalidIdentifier
}

extension JobIdentifier {
    var key: String {
        "job:\(self.string)"
    }
}

extension _JobsPosgtresQueue: JobsQueue {
    
    func get(_ id: JobIdentifier) -> EventLoopFuture<JobData> {
        let sqlQuery: SQLQueryString = """
        SELECT * FROM job
        WHERE key = '\(id.key)'
        """
        
        print("🚀 \(type(of: self)) : \(#function) for key = \(id.key)")
        
        guard let postgresDatabase = self.database as? PostgresDatabase else {
            let error = Abort(.internalServerError, reason: "could not set db")
            return self.eventLoop.makeFailedFuture(error)
        }
        
        return postgresDatabase.withConnection { (postgresConnection) -> EventLoopFuture<JobData> in
            postgresConnection.sql().raw(sqlQuery).first(decoding: JobModel.self).flatMapThrowing { (jobModel) -> JobData in
                guard let data = jobModel?.data else { throw _JobsPosgtresError.missingJob }
                let decoder = try JSONDecoder().decode(DecoderUnwrapper.self, from: data)
                return try JobData(from: decoder.decoder)
            }
        }
    }
    
    func set(_ id: JobIdentifier, to data: JobData) -> EventLoopFuture<Void> {
        // Establish a database connection
        return self.database.withConnection { database -> EventLoopFuture<Void> in
            // Encode and save the Job
            let _data = try! JSONEncoder().encode(data)
            return JobModel(key: id.key, jobId: id.string, data: _data).save(on: database)
        }
    }
    
    func clear(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        print("🚀 \(type(of: self)) : \(#function) id.key = \(id.key)")
        return self.database.withConnection { database -> EventLoopFuture<Void> in
            // Update the state
            print("I must delete \(id.key)")
            return JobModel.query(on: database)
                .filter(\.$key == id.key)
                .first()
                .flatMap { jobModel in
                    if let jobModel = jobModel {
                        print("🚀 \(type(of: self)) : \(#function) we have found this job for clearing \(jobModel)")
                        // If we are just deleting completed jobs, then delete the job
                        if self.deleteCompletedJobs {
                            return jobModel.delete(on: database).transform(to: ())
                        }
                        // Otherwise, update the state
                        jobModel.state = JobState.completed.rawValue
                        jobModel.updatedAt = Date()
                        return jobModel.save(on: database)
                    }
                    return database.eventLoop.future()
            }
        }
    }
    
    func pop() -> EventLoopFuture<JobIdentifier?> {
        print("pop()")
        let sqlQuery: SQLQueryString = """
        UPDATE job SET state = 'processing',
        updated_at = clock_timestamp()
        WHERE id = (
        SELECT id
        FROM job
        WHERE
        state = 'pending'
        ORDER BY id
        FOR UPDATE SKIP LOCKED
        LIMIT 1
        )
        RETURNING *
        """
        
        guard let postgresDatabase = self.database as? PostgresDatabase else {
            let error = Abort(.internalServerError, reason: "could not set db")
            return self.eventLoop.makeFailedFuture(error)
        }
        
        return postgresDatabase.withConnection { (postgresConnection) -> EventLoopFuture<JobIdentifier?> in
            return postgresConnection.sql().raw(sqlQuery).first(decoding: JobModel.self).flatMapThrowing { jobModel in
                guard let jobModel = jobModel else {
                    return nil
                }
                
                return .init(string: jobModel.job_id)
            }
        }
    }
    
    func push(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        return self.eventLoop.future()
    }
}

struct DecoderUnwrapper: Decodable {
    let decoder: Decoder
    init(from decoder: Decoder) { self.decoder = decoder }
}

enum JobState: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
}
public final class JobModel: Model, Content {
    public static let schema = "job"
    
    @ID(key: "id")
    public var id: Int?
    
    /// The Job key
    @Field(key: "key")
    var key: String
    
    /// The unique Job uuid
    @Field(key: "job_id")
    var job_id: String
    
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
         jobId: String,
         data: Data,
         state: JobState = .pending,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.key = key
        self.job_id = jobId
        self.data = data
        self.state = state.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
