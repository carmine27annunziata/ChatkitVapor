
import Vapor
import FluentSQLite
import Authentication

let room = Room()

public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    let serverConfiure = NIOServerConfig.default(hostname: "0.0.0.0", port: 9090)
    services.register(serverConfiure)
    
    let wss = NIOWebSocketServer.default()
    
    wss.get("chat") { ws, req in
        var pingTimer: DispatchSourceTimer? = nil
        var username: String? = nil
        
        pingTimer = DispatchSource.makeTimerSource()
        pingTimer?.schedule(deadline: .now(), repeating: .seconds(25))
        //pingTimer?.setEventHandler { try? ws.ping() }
        pingTimer?.resume()
        
        ws.onText { ws, text in
            if let decoded = try? JSONDecoder().decode(Username.self, from: text) {
                username = decoded.username
                room.connections[decoded.username] = ws
                room.bot("\(decoded.username) has joined. 👋")
            }
            
            if let u = username, let decoded = try? JSONDecoder().decode(Message.self, from: text) {
                room.send(name: u, message: decoded.message)
            }
            
           //ws.send(text)
        }
        
        ws.onClose { ws in
            pingTimer?.cancel()
            pingTimer = nil
            
            guard let u = username else {
                return
            }
            
            room.bot("\(u) has left")
            room.connections.removeValue(forKey: u)
        }
        
        /*var pingTimer: DispatchSourceTimer? = nil
        var username: String? = nil
        
        pingTimer = DispatchSource.makeTimerSource()
        pingTimer?.schedule(deadline: .now(), repeating: .seconds(25))
        pingTimer?.setEventHandler { try? ws.ping() }
        pingTimer?.resume()
        
        ws.onText { ws, text in
            let json = try JSON(bytes: text.makeBytes())
            
            if let u = json.object?["username"]?.string {
                username = u
                room.connections[u] = ws
                room.bot("\(u) has joined. 👋")
            }
            
            if let u = username, let m = json.object?["message"]?.string {
                room.send(name: u, message: m)
            }
        }*/
        
        /*ws.onClose { ws, _, _, _ in
            pingTimer?.cancel()
            pingTimer = nil
            
            guard let u = username else {
                return
            }
            
            room.bot("\(u) has left")
            room.connections.removeValue(forKey: u)
        }*/
        
        // Add a new on text callback
        /*ws.onText { ws, text in
            // Simply echo any received text
            ws.send(text)
        }*/
    }
    
    services.register(wss, as: WebSocketServer.self)
    
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

