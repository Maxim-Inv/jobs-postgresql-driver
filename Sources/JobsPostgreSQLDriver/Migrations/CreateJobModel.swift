import Fluent

public struct CreateJob: Migration {
    
    public init() {}
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(JobModel.schema)
            .field("id", .int, .identifier(auto: true))
            .field("key", .string, .required)
            .field("data", .data, .required)
            .field("state", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .field("deleted_at", .datetime)
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(JobModel.schema).delete()
    }
}
