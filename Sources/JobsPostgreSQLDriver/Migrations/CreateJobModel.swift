import Fluent

public struct CreateJob: Migration {
    
    public init() {}
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("job")
            .field("id", .int, .identifier(auto: true))
            .field("key", .string, .required)
            .field("job_id", .string, .required)
            .field("data", .data, .required)
            .field("state", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("todos").delete()
    }
}
