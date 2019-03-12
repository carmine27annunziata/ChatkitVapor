import Foundation
import Vapor
import Fluent
import FluentSQLite
import Crypto

class UserController: RouteCollection {
    //1
    func boot(router: Router) throws {
        let group = router.grouped("api", "users")
        group.post(User.self, at: "register", use: registerUserHandler)
    }
}

//MARK: Helper
private extension UserController {
    
    func registerUserHandler(_ request: Request, newUser: User) throws -> Future<HTTPResponseStatus> {
        
        //2
        return try User.query(on: request).filter(\.email == newUser.email).first().flatMap { existingUser in
            
            //3
            guard existingUser == nil else {
                throw Abort(.badRequest, reason: "a user with this email already exists" , identifier: nil)
            }
            
            //4
            let digest = try request.make(BCryptDigest.self)
            let hashedPassword = try digest.hash(newUser.password)
            let persistedUser = User(id: nil, email: newUser.email, password: hashedPassword)
            
            //5
            return persistedUser.save(on: request).transform(to: .created)
        }
    }
    
    
}
