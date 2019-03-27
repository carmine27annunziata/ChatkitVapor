import Vapor

extension WebSocket {
    func send(_ json: [String: String]) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        //let js = try json.makeBytes()
        try send(jsonString!)
    }
}
