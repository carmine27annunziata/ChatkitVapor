import Vapor

class Room {
    var connections: [String: WebSocket]

    func bot(_ message: String) {
        send(name: "Bot", message: message)
    }

    func send(name: String, message: String) {
        let message = message.truncated(to: 256)
        
        let messageNode: [String: String] = [
            "username": name,
            "message": message
        ]
        
        for (username, socket) in connections {
            guard username != name else {
                continue
            }
            
            try? socket.send(messageNode)
        }
    }
    
    /*func send(name: String, message: String) {
        let message = message.truncated(to: 256)
        
        for (username, socket) in connections {
            guard username != name else {
                continue
            }
            
            try? socket.send(message)
        }
        
        /*let messageNode: String = message

        guard let json = try? JSON(node: messageNode) else {
            return
        }

        */
    }*/

    init() {
        connections = [:]
    }
}
