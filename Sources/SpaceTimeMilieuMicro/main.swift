import Foundation
import SpaceTimeMilieuModel
import Kitura
import Dispatch
import LoggerAPI
import HeliumLogger

private let Default_APIKey="Get one from https://algorithmia.com"

#if os(Linux)
    import Glibc
#endif

let ourLogger = HeliumLogger(.info)
ourLogger.dateFormat = "YYYY/MM/dd-HH:mm:ss.SSS"
ourLogger.format = "(%type): (%date) - (%msg)"
ourLogger.details = false
Log.logger = ourLogger

let myCertPath = "./cert.pem"
let myKeyPath = "./key.pem"
let myChainPath = "./chain.pem"

let remoteURLList: [URL]
let rawURLList = getenv("URLS")
if let urlList = rawURLList, let urlListString = String(utf8String: urlList) {
    var tmpURLList = [URL]()
    let urlStringList = NSString(string: urlListString).components(separatedBy:CharacterSet.whitespaces)
    for urlString in urlStringList {
        if let url = URL(string:urlString) {
            tmpURLList.append(url)
        }
    }
    if (tmpURLList.count <= 0) {
        fatalError("Failed to create URL list from URLS environment variable (which should be whitespace delimited)")
    }
    remoteURLList = tmpURLList
} else {
//no SSL for mac
#if os(Linux)
    guard let tmpRemoteURLList = [URL(string: "https://ssldemo.linuxswift.com:8091/api")] as? [URL] else {
        fatalError("Failed to create URL list from hardcoded strings")
    }
    remoteURLList = tmpRemoteURLList
#else
    guard let tmpRemoteURLList = [URL(string: "http://127.0.0.1:8091/api")] as? [URL] else {
        fatalError("Failed to create URL list from hardcoded strings")
    }
    remoteURLList = tmpRemoteURLList
#endif
}

//Enable Core Dumps on Linux
#if os(Linux)
    
let unlimited = rlimit.init(rlim_cur: rlim_t(INT32_MAX), rlim_max: rlim_t(INT32_MAX))
    
let corelimit = UnsafeMutablePointer<rlimit>.allocate(capacity: 1)
corelimit.initialize(to: unlimited)
    
let coreType = Int32(RLIMIT_CORE.rawValue)
    
let status = setrlimit(coreType, corelimit)
if (status != 0) {
    print("\(errno)")
}
    
corelimit.deallocate(capacity: 1)
#endif

//Don't do SSL on macOS
#if os(Linux)
let mySSLConfig =  SSLConfig(withCACertificateFilePath: myChainPath, usingCertificateFile: myCertPath, withKeyFile: myKeyPath, usingSelfSignedCerts: false)
#endif

let APIKey: String
let rawAPIKey = getenv("APIKEY")
if let key = rawAPIKey, let keyString = String(utf8String: key) {
    APIKey = keyString
} else {
    APIKey = Default_APIKey
}

let router = Router()

//Log page responses
router.all { (request, response, next) in
    var previousOnEndInvoked: LifecycleHandler? = nil
    let onEndInvoked: LifecycleHandler = { [weak response, weak request] in
        Log.info("\(response?.statusCode.rawValue ?? 0) \(request?.originalURL ?? "unknown")")
        previousOnEndInvoked?()
    }
    previousOnEndInvoked = response.setOnEndInvoked(onEndInvoked    )
    next()
}

router.post("/api") { request, response, next in
    
    let bodyRaw: Data?
    do {
        bodyRaw = try BodyParser.readBodyData(with: request)
    } catch {
        Log.error("Could not read request body \(error)! Giving up!")
        response.headers["Content-Type"] = "text/plain; charset=utf-8"
        try? response.status(.preconditionFailed).send("Could not read request body \(error)! Giving up!").end()
        return
    }
    
    guard let bodyData = bodyRaw else {
        Log.error("Could not get bodyData from Raw Body! Giving up!")
        response.headers["Content-Type"] = "text/plain; charset=utf-8"
        try? response.status(.preconditionFailed).send("Could not get bodyData from Raw Body! Giving up!").end()
        return
    }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = Point.iso8601Format

    let bodyPointArray: [Point]
    do {
        bodyPointArray = try Point.decodeJSON(data: bodyData)
    } catch {
        Log.error("Could not get Points from Body JSON! Giving up!")
        response.headers["Content-Type"] = "text/plain; charset=utf-8"
        try response.status(.preconditionFailed).send("Could not get Point from Body JSON \(error)! Giving up!").end()
        return
    }
    
    let fetchGroup = DispatchGroup()
    
     let dictUpdateQueue =
        DispatchQueue(
            label: "com.ibm.swift.dictUpdateQueue",
            attributes: .concurrent)

    var decorationsToReturn = [Decoration]()
    
    for remoteURL in remoteURLList {
        fetchGroup.enter()
        
        var request = URLRequest(url: remoteURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try Point.encodeJSON(points: bodyPointArray)
            //            let jsonToPrint = String(data: request.httpBody!, encoding: .utf8)
            //            print("result: '\(jsonToPrint!)'")
        } catch {
            Log.error("Could not create remote JSON Payload \(error)! Giving up!")
            response.headers["Content-Type"] = "text/plain; charset=utf-8"
            try? response.status(.internalServerError).send("Could not create remote JSON Payload \(error)! Giving up!").end()
            fetchGroup.leave()
            return
        }
        
        let session = URLSession(configuration:URLSessionConfiguration.default)
        
        let task = session.dataTask(with: request){ fetchData,fetchResponse,fetchError in
            guard fetchError == nil else {
                Log.error("Got fetch Error: \(fetchError?.localizedDescription ?? "Error with no description")")
                response.headers["Content-Type"] = "text/plain; charset=utf-8"
                try? response.status(.internalServerError).send(fetchError?.localizedDescription ?? "Error with no description").end()
                fetchGroup.leave()
                return
            }
            guard let fetchData = fetchData else {
                Log.error("Nil fetched data with no error")
                response.headers["Content-Type"] = "text/plain; charset=utf-8"
                try? response.status(.internalServerError).send("Nil fetched data with no error").end()
                fetchGroup.leave()
                return
            }
            //print("Got \(fetchData) is not nil")
            if let debug = getenv("DEBUG") { //debug
                //OK to crash if debugging turned on
                let jsonToPrint = String(data: fetchData, encoding: .utf8)
                print("result: \(jsonToPrint!)")
            }
            
            do {
                let decorations = try Decoration.decodeJSON(data: fetchData)
                dictUpdateQueue.async(flags: .barrier) {
                    decorationsToReturn.append(contentsOf: decorations)
                    fetchGroup.leave()
                }
                return
            } catch {
                Log.error("Could not parse remote JSON Payload \(error)! Giving up!")
                response.headers["Content-Type"] = "text/plain; charset=utf-8"
                try? response.status(.internalServerError).send("Could not parse remote JSON Payload \(error)! Giving up!").end()
                fetchGroup.leave()
                    return
                }
            }
            task.resume()
    }
    
    let timedout = fetchGroup.wait(timeout: DispatchTime.now() + 60)
    do {
        response.headers["Content-Type"] = "application/json; charset=utf-8"
        response.status(.OK).send(data:try Decoration.encodeJSON(decorations: decorationsToReturn, dateFormatter: dateFormatter))
        next()
    } catch {
        Log.error("Could not create JSON Payload to return \(error)! Giving up!")
        response.headers["Content-Type"] = "text/plain; charset=utf-8"
        try? response.status(.internalServerError).send("Could not create JSON Payload to return \(error)! Giving up!").end()
    }
}

// Handles any errors that get set
router.error { request, response, next in
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    let errorDescription: String
    if let error = response.error {
        errorDescription = "\(error)"
    } else {
        errorDescription = "Unknown error"
    }
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    try response.send("Caught the error: \(errorDescription)").end()
}

//MARK: /ping
router.get("/ping") { request, response, next in
    //Health check
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    try response.send("OK").end()
}

//Don't do SSL on macOS
#if os(Linux)
    Kitura.addHTTPServer(onPort: 8090, with: router, withSSL: mySSLConfig)
#else
    Kitura.addHTTPServer(onPort: 8090, with: router)
#endif
Kitura.run()
