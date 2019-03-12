
import Vapor
import FluentSQLite
import Authentication

/// Called before your application initializes.
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services) throws {
    
    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    // Configure the rest of your application here
    let directoryConfig = DirectoryConfig.detect()
    services.register(directoryConfig)
    
    // Configure Fluents SQL provider
    try services.register(FluentSQLiteProvider())
    
    // Configure the authentication provider
    try services.register(AuthenticationProvider())
    
    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
    
    // Configure our database
    var databaseConfig = DatabasesConfig()
    let db = try SQLiteDatabase(storage: .file(path: "\(directoryConfig.workDir)auth.db"))
    databaseConfig.add(database: db, as: .sqlite)
    services.register(databaseConfig)
    
    // Configure our model migrations
    var migrationConfig = MigrationConfig()
    migrationConfig.add(model: User.self, database: .sqlite)
    migrationConfig.add(model: Todo.self, database: .sqlite)
    services.register(migrationConfig)
}

