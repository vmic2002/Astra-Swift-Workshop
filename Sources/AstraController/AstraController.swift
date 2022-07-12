import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
import Model
import Env

//structs used to PATCH -> change paid status or change password
public struct Paid :Codable {
    var paid :Bool
}
public struct Password: Codable{
    var password:String
}

public final class AstraController {
    var orders : [Order]//has to be global because getRequest is async
    var gotOrders : Bool//same reason as above
    var localOrderDB : [String:Order]
    var gotUserInfo : Bool
    var localUserInfoDB : [String:UserInfo]

    //these are needed because we are calling async functions from command line
    var postedUserInfo : Bool
    var postedOrder : Bool
    var deletedDoc : Bool
    var changedPassword : Bool
    var setToPaid : Bool

    var pageState :String// ""//pageState is initialized as empty on purpose, see getAllOrdersForUserName

    public init(){
        orders = [Order]()//has to be global because getRequest is async
     gotOrders = false//same reason as above
     localOrderDB = [String:Order]()
     gotUserInfo = false
     localUserInfoDB = [String:UserInfo]()

    //these are needed because we are calling async functions from command line
     postedUserInfo = false
     postedOrder = false
     deletedDoc = false
     changedPassword = false
     setToPaid = false

     pageState = ""//pageState is initialized as empty on purpose, see getAllOrdersForUserName

    }
   
   public func printAllOrdersFor(userName:String){
    print("Fetching all orders for \(userName)...")
    let orders1 = getAllOrdersForUserName(userName: userName).orders
    printOrders(orders: orders1)
    print("There are \(orders1.count) orders")
}

public func printUserInfoFor(userName:String){
    let userInfoDict1 = getUserInfoForUserName(userName: userName)
    if (userInfoDict1.count==0){
        print("No account with username: \(userName)")
        return
    }
    for (_,userInfo) in userInfoDict1 {
        print("Username: \(userInfo.getUserName()), Password: \(userInfo.getPassword())")
        //for loop should only iterate once because usernames are unique
    }
}

//returns an order summary
public func computeAmoundOwed(order:Order)->String{
    var dict = [String:Double]()
    computeAmountOwed(order: order, dict: &dict)
    var result = ""
    for (key,value) in dict{
        result+="\(key) owes \(value) to \(order.getUserName()) \n"
    }
    return result
}

private func computeAmountOwed(order:Order, dict: inout [String:Double]){
    if (order.getPaid()==true){
        print("Order.paid is true. No need to compute amount owed")
        return//only compute amount owed for orders that have not been paid
    }
    //need dictionary of ["user":amountOwed]
    //dont need to count for user that is payerName
    //function could return dictionary
    //print("start of compute amount owed method")
    //printOrder(order:order)
    //var dict = [String:Double]()
    for item in order.getReceipt(){
        let amount = Double(item.getPrice())/Double(item.getUsers().count)
        for user in item.getUsers() {
            if (user != order.getUserName()){
                //no need to keep track how much the person paid owes themselves
                //this is assuming that every person has a different name
                if (dict[user]==nil){
                    dict[user]=0.0
                }
                dict[user]!+=Double(amount)//truncatetruncate
            }
        }
    }
    //each user owes dict[user] to order.userName
    //for (key,value) in dict{
   //     print("\(key) owes \(value) to \(order.userName)")
   // }
    //print("end of compute amound owed method")
    //  return dict
}

public func printOrder(order:Order){
    print("Payer user name: \(order.getUserName())")
    print("Receipt: ")
    for item in order.getReceipt() {
        //print("item price: \(item.price)")
        print("\(item.getPrice())")
        print("User: ", terminator: "")
         for user in item.getUsers() {//
             print("\(user) ", terminator: "")
         }
         print()
    }
    
}

public func printOrders(orders:[Order]){
    for order in orders {
        printOrder(order:order)
    }
}

//returns true if user can sign in and false otherwise
//is also used to check if user can change password
private func signIn(userName:String, password:String)->Bool{
    let dict = getUserInfoForUserName(userName: userName)
    if (dict.count==0){
       // shared.errMsgColor = Color.red
        //shared.errorMessage = "There is no account with username \(userName)."
        print("There is no account with username \(userName).")
        return false
    }
    if (dict[dict.startIndex].value.getPassword()==password){//dict should have only one entry since usernames are unique
        print("Correct password.")
        return true
    } else {
        //shared.errMsgColor = Color.red
        //shared.errorMessage = "Incorrect password."// Could not sign in."commented because sign in func is also used for changing password
        print("Incorrect password.")
        return false
    }
}

//for a user to sign up (create account)
public func createAccount(userName:String, password:String){
    let userInfoDict = getUserInfoForUserName(userName: userName)
    if (userInfoDict.count>0){
        // ContentView.setErrMsg("Cannot create account with username: \(userName) because one already exists.")
        //shared.errMsgColor = Color.red
       // shared.errorMessage = "Cannot create account with username: \(userName) because one already exists."
        print("Cannot create account with username: \(userName) because one already exists.")
        return
    }
    postRequest(userInfo: UserInfo(userName: userName, password: password))
   // shared.errMsgColor = Color.green
  //  shared.errorMessage = "Account created successfully."
}

public func deleteAccount(userName:String, password:String){
    print("Deleting acount... Please wait")

    
    //get user info and doc id from astra db
    let userInfoDB = getUserInfoForUserName(userName: userName)
    //returns dict of docID:UserInfo
    //because doc id is needed to delete from db
    //for loop DELETES USER INFO
    //WHICH IS DELETING ACCOUNT
    if (userInfoDB.count==0){
       // shared.errMsgColor = Color.red
       // shared.errorMessage = "Cannot delete account with username: \(userName) because none exists."
        print("Cannot delete account with username: \(userName) because none exists.")
        return
    }
    
    for (docID, userInfo) in userInfoDB {
        if (userInfo.getPassword()==password){
            deleteUserInfoRequest(docID: docID)
        } else {
            //shared.errMsgColor = Color.red
            //shared.errorMessage = "Incorrect password. Cannot delete account."
            print("Incorrect password. Cannot delete account.")
            
            return
        }
        //for loop should only iterate once because usernames should be unique
    }
    
    
    //now to delete all orders with this username
    
    
    deleteOrdersForUserName(userName:userName)
    
    
   // let db = getAllOrdersForUserName(userName: userName).localOrderDB
    
  //  print("Deleting orders")
   // for (docID, _) in db {
   //     deleteOrderRequest(docID: docID)
   // }
    
    //shared.errMsgColor = Color.green
    //shared.errorMessage = "Account deleted successfully"
    print("Account deleted successfully")
}

private func deleteOrdersForUserName(userName:String){
    /*
     get all orders for username and get all their DOC IDs
     then go through each ID and delete
     */
     print("Deleting all orders for \(userName)")
    let orderDB = getAllOrdersForUserName(userName: userName).localOrderDB//to get doc ID because can only delete from database with doc ID (at least from what I know)
    print("There are \(orderDB.count) order(s) to delete...")
    for (docID, _) in orderDB {
        deleteOrderRequest(docID: docID)
        //print("Deleting doc \(docID)")
    }
}

//if user has lots of receipts he wants to compute in one go
public func computeAllOrdersFor(userName:String){
    print("Fetching all orders for \(userName)...")
    let orders1 = getAllOrdersForUserName(userName: userName).orders
    var dict = [String:Double]()
    print("Computing \(orders1.count) order(s)...")
    print()
    for order in orders1{
        computeAmountOwed(order: order, dict: &dict)
    }
    for (key,value) in dict{
        //print("\(key) owes \(value) to \(userName)")
        print(String(format: "\(key) owes %.2f to \(userName)", value))
    }
    print("All orders computed successfully.")
}

public func populateUserInfoDB(){
    createAccount(userName: "Michael1", password: "thatswhatshesaid")
    createAccount(userName: "Dwight1", password: "bearsbeetsbattlestargallactica")
    createAccount(userName: "Jim1", password: "beesley!")
    createAccount(userName: "Pam1", password: "sprinkleofcinnamon")
    createAccount(userName: "Angela1", password: "cats")
    createAccount(userName: "Kevin1", password: "cookies")
    createAccount(userName: "Oscar1", password: "accountant")
    createAccount(userName: "Phillys1", password: "damnitphyllis")
    createAccount(userName: "Stanley1", password: "crosswordpuzzles")
    createAccount(userName: "Andy1", password: "itsdrewnow")
    createAccount(userName: "Toby1", password: "goingtocostarica")
    createAccount(userName: "Kelly1", password: "attention")
    createAccount(userName: "Ryan1", password: "hottestintheoffice")
    createAccount(userName: "David1", password: "corporate")
    createAccount(userName: "Gabe1", password: "birdman")
    createAccount(userName: "Robert1", password: "lizardking")
    createAccount(userName: "Creed1", password: "scrantonstrangler")
    createAccount(userName: "Roy1", password: "wharehouseandpam")
    createAccount(userName: "Darryl1", password: "rogers")
    createAccount(userName: "Jan1", password: "loveshunter")
    createAccount(userName: "Holly1", password: "michaelslove")
    createAccount(userName: "Mose1", password: "dwightsbrother")
    createAccount(userName: "Joe1", password: "ceoofsabre")
}

public func populateOrdersDB(numNewOrders:Int){
    for _ in 0..<numNewOrders{
        let order = getRandomOrder(userNames: Array(getRandomSetOfUserNames()))
        //printOrder(order:order)
        postRequest(order: order)
        print("Posting random order...")
    }
    print("Orders db populated with \(numNewOrders) new random orders.")//assuming no mistakes occured
}

//get all UserInfo where username = something in real time
private func getUserInfoForUserName(userName:String)-> [String:UserInfo]{
    getRequestUserInfo(userName:userName)
    //userinfo isnt computed even after getRequestUserInfo is finished
    //need while loop
    while self.gotUserInfo==false{
        Thread.sleep(forTimeInterval: 0.01)
        //after while loop orders will be complete
    }
    if (self.localUserInfoDB.count==1){
       // print("Account for \(userName) exists.")
    } else {
       // print("No account found for \(userName).")
    }
    //print("There is \(localUserInfoDB.count) user info with username: \(userName)")
    
    
    var localUserInfoDBCpy = [String:UserInfo]()
    for (docID, userInfo) in self.localUserInfoDB {
        
        localUserInfoDBCpy[docID] = UserInfo(userName: userInfo.getUserName(), password: userInfo.getPassword())
        //for loop should iterate just once because usernames are unique
        //structs are passed as copies
    }
    //reinitialize gotOrders and orders and localOrderDB
    self.gotUserInfo = false
    self.localUserInfoDB.removeAll()
    return localUserInfoDBCpy
}

private func getAllOrdersForUserNameAsString(userName:String)->(result:String, numOrders:Int){
    let pastOrders = getAllOrdersForUserName(userName: userName).orders
    var result = ""
    for order in pastOrders {
        result += getOrderAsString(order:order)
        result += "\n"
        //result += "Paid:"
        //for item in order.receipt {
           // result += "Price: \(item.price) -- Users: "
           // for user in item.users {
            //    result += "\(user) "
            //}
           // result+="\n"
       // }
       // result+="\n-----------------------\n"
    }
    //print("RESULTTTTT")
    //print(result)
    return (result, pastOrders.count)
}

public func getOrderAsString(order:Order)->String{
    var result = "Paid: \(order.getPaid()), Date: \(order.getTime())\n"
    for item in order.getReceipt() {
        result += "Price: \(item.getPrice()) -- Users: "
        for user in item.getUsers() {
            result += "\(user) "
        }
        result+="\n"
    }
    result+="\n-----------------------\n"
    return result
}

/*
 get all orders where userName = something in real time
 so that a user can see all past orders
 */
private func getAllOrdersForUserName(userName:String)->(orders: [Order], localOrderDB: [String:Order]) {
    var ordersCpy = [Order]()
    var localOrderDBCpy = [String:Order]()
    getRequestOrders(userName:userName, maxNumOrders: 20)
    //max number of orders to get back is 20 -> max num of docs that can be returned
    //TO GET ALL ORDERS: do get request with page-size size 20
    //then get operation with page-state = val of page state from first get request
    
    //orders isnt computed even after getRequestOrders is finished
    //need while loop
    while self.gotOrders==false{
        Thread.sleep(forTimeInterval: 0.01)
        //after while loop orders will be complete
    }
    //print("there are \(orders.count) orders")
    
    for (docID, order) in self.localOrderDB {
        if localOrderDBCpy[docID]==nil {//to prevent duplicate docs
            let o = Order(userName: order.getUserName(), receipt: order.getReceipt(), paid: order.getPaid(), time: order.getTime())
            ordersCpy.append(o)
            localOrderDBCpy[docID] = o
        }
    }
    //reinitialize gotOrders and orders and localOrderDB
    self.gotOrders = false
    self.orders = [Order]()
    self.localOrderDB.removeAll()
    if (self.pageState.isEmpty){
        return (ordersCpy, localOrderDBCpy)
    }
    while (!(self.pageState.isEmpty)){
        //print("Pagestate is \(pageState)")
        let str = "/namespaces/keyspacename1/collections/orders?where={\"userName\":{\"$eq\":\"\(userName)\"}}&page-size=20&page-state=\(pageState)"
        self.pageState = ""//re initialize pageState
        getRequest(orderOrUserInfo: true, str: str)
        while self.gotOrders==false{
            Thread.sleep(forTimeInterval: 0.01)
        }
        //   print("there are \(orders.count) orders")
        for (docID, order) in self.localOrderDB {
            if localOrderDBCpy[docID]==nil {
                let o = Order(userName: order.getUserName(), receipt: order.getReceipt(), paid: order.getPaid(), time: order.getTime())
                ordersCpy.append(o)
                localOrderDBCpy[docID] = o
            }
        }
        //reinitialize gotOrders and orders and localOrderDB
        self.gotOrders = false
        self.orders = [Order]()
        self.localOrderDB.removeAll()
    }
    //dont need to reinitialize pageState to empty string because
    //if the while loop finished that means it is already empty
    //print("OrdersCpy.count: \(ordersCpy.count) == localOrderDBCpy.count: \(localOrderDBCpy.count) should be TRUE")
    return (ordersCpy, localOrderDBCpy)
}

//orderOrUserInfo is true to perform order get request
//and false to perform user info get request
private func getRequest(orderOrUserInfo:Bool, str:String){
    let request = httpRequest(httpMethod: "GET", endUrl: str)
    let task = URLSession.shared.dataTask(with: request){ data, response, error in
        if let _ = error {
            //shared.errorMessage = "error: \(error)"
            
            //print (shared.errorMessage)
            return
        }
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            //shared.errorMessage = "server error"
            //COMMENTED line above because of bug:Publishing changes from background threads is not allowed; make sure to publish values from the main thread (via operators like receive(on:)) on model updates.
            //print (shared.errorMessage)
            //print(response)
            return
        }
        if let mimeType = response.mimeType,
           mimeType == "application/json",
           let data = data,
           var dataString = String(data: data, encoding: .utf8) {
            // print ("got data: \(dataString)")
            /*
             JSON data is of the form
             {“data”:
             {
             “docID”: Order,
             “docID”:Order
             }
             }
             OR (if there are more docs than page-size or 20)
             {"pageState":"JDZjN2Y5MGQ5LWYyZGItNGRkNS05Mzk3LTZiNDE5NzYzNGMwZQDwf_____B_____","data":{
             
             “docID”: Order,
             “docID”:Order
             }
             }
             */
            //TO SOLVE PROBLEM FIND FIRST OCCURENCE OF DATA, PAGE STATE SHOULD ESSENTIALLY NEVER HAVE WORD DATA IN IT WOUKLD
            //BE VERY UNLUCKY
            
            if (orderOrUserInfo==true){//no page state if looking for user info
                
                let y = 64//length of page-state
                if (dataString[dataString.index(dataString.startIndex, offsetBy: 2)]=="p"){
                    self.pageState = String(dataString[dataString.index(dataString.startIndex, offsetBy: 14)...dataString.index(dataString.startIndex, offsetBy: 14+y-1)])
                }
            }
            
            let str = "data"
            var j = 0
            var indx = dataString.startIndex//arbitrary
            for i in 2..<dataString.count {
                if (dataString[dataString.index(dataString.startIndex, offsetBy: i)]==str[str.index(str.startIndex, offsetBy: j)]){
                    if (j<3){
                        //i is incremented because of for loop
                        j+=1
                    } else {//if j==3 then str has been found in dataString
                        //indx = i + 3
                        indx = dataString.index(dataString.startIndex, offsetBy: i+3)
                        break
                    }
                } else {
                    if (!(j==0)) {
                        j=0//if mismatch set j back to 0
                    }
                }
            }
            //indx is at start of desired JSON string
            
            
            //get substirng of dataString from indx to endIndex-1 (or remove last char after)
            //DO THIS!!!!
            let x = dataString.startIndex..<indx
            dataString.removeSubrange(x)
            dataString.removeLast()//to remove last }
            
            // print("dataString should be nicely formatted now")
            // print("dataString: \(dataString)")
            /*
             by now dataString is of form:
             {
             “docID”: Order,
             “docID”:Order
             }
             */
            //https://medium.com/@boguslaw.parol/decoding-dynamic-json-with-unknown-properties-names-and-changeable-values-with-swift-and-decodable-127e437e8000
            if (orderOrUserInfo==true){
                typealias Values = [String: Order]
                if let jsonData = dataString.data(using: .utf8) {
                    let events = try? JSONDecoder().decode(Values.self, from: jsonData)
                    for (key, eventData) in events! {
                        //event data should be an Order
                        //key should be a docID
                        // print("KEY: "+key + " NAME: " + eventData.payerName)
                        self.localOrderDB[key]=eventData
                        self.orders.append(eventData)
                    }
                    self.gotOrders = true
                } else {
                    print("Could not convert to type Data")
                   // shared.errorMessage = "Error occured while fetching from database"
                }
            } else {
                typealias Values = [String: UserInfo]
                if let jsonData = dataString.data(using: .utf8) {
                    let events = try? JSONDecoder().decode(Values.self, from: jsonData)
                    for (key, eventData) in events! {
                        //event data should be an UserInfo
                        //key should be a docID
                        // print("KEY: "+key + " NAME: " + eventData.payerName)
                        self.localUserInfoDB[key]=eventData
                        //localUserInfoDB is dictionary even though we only expect the number of entries to be at most one
                        //since usernames are unique
                    }
                    self.gotUserInfo = true
                } else {
                    print("Could not convert to type Data")
                    //shared.errorMessage = "Error occured while fetching from database"
                }
                
            }
            
        }
    }
    task.resume()
    //print("end of get request method")
}

//can be used to know if a doc with a certain username exists
//helps to know if account already exists
private func getRequestUserInfo(userName:String){
    let str = "/namespaces/keyspacename1/collections/userInfo?where={\"userName\":{\"$eq\":\"\(userName)\"}}&page-size=1"
    getRequest(orderOrUserInfo: false, str: str)
}

//sets correct values to orders and localOrderDB vars
private func getRequestOrders(userName:String, maxNumOrders:Int){
    //param is username of person to retrieve all orders
    //print("in get request method"+">> /namespaces/keyspacename1/collections/orders?where=\\{\"firstname\":\\{\"$eq\":\""+name+"\"\\}\\}")
    // let str = "/namespaces/keyspacename1/collections/orders?where=\\{\"payerName\":\\{\"$eq\":\"\(name)\"\\}\\}"
    let str = "/namespaces/keyspacename1/collections/orders?where={\"userName\":{\"$eq\":\"\(userName)\"}}&page-size=\(maxNumOrders)"
    //print("str is:"+str)
    getRequest(orderOrUserInfo: true, str: str)
    
}

//makes sure username and password are correct then updates to newPassword if credentials were valid
public func changePassword(userName:String, password:String, newPassword:String){
      //signIn and changePassword both call getUserInfoForUserName, could be done only once
      if !(signIn(userName:userName, password:password)){
        print("Could not change password.")
        return
      }
      
      changePassword(newPassword:newPassword, userName:userName)
      while self.changedPassword==false{
        Thread.sleep(forTimeInterval: 0.01)
        //after while loop orders will be complete
    }
    self.changedPassword = true
}

//this method is called in ChangePassword view, which means that the user has a valid username
//and one userInfo
//call func changePassword(userName:String, password:String, newPassword:String)
private func changePassword(newPassword:String, userName:String){
    let dict = getUserInfoForUserName(userName: userName)
    //  let userInfo = dict[dict.startIndex].value
    let docID = dict[dict.startIndex].key
    //let newUserInfo = UserInfo(userName:userName, password: newPassword)
    //print("USING PATCH")
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let uploadData = try? encoder.encode(Password(password: newPassword)) else {
        return
        //could not convert to type data
    }
    
    let request = httpRequest(httpMethod: "PATCH", endUrl: "/namespaces/keyspacename1/collections/userInfo/\(docID)")
    let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
        if let error = error {
            print ("error: \(error)")
            self.changedPassword = true
            return
        }
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            print ("server error")
            self.changedPassword = true
            return
        }
        if let mimeType = response.mimeType,
           mimeType == "application/json",
           let data = data,
           // let _ = String(data: data, encoding: .utf8) {
           let dataString = String(data: data, encoding: .utf8) {
            self.changedPassword = true
            print("Password changed successfully.")
            print("New password for \(userName): \(newPassword).")
            print ("got data: \(dataString)")
            
            //dataString is of form:
            /*
             {"documentId":"58171bbd-cd42-4c54-a5f7-ed146097d1dc"}
             */
        }
        self.changedPassword = true//might not be neccessary
    }
    task.resume()
}

private func postRequest(uploadData:Data, collection:String){
    /*swagger UI link to use *post* a *document* using Document API:
     https://ASTRA_DB_ID-ASTRA_DB_REGION.apps.astra.datastax.com/api/rest/v2/namespaces/{namespace-id}/collections/{collection-id}
     */
    let request = httpRequest(httpMethod: "POST", endUrl: "/namespaces/keyspacename1/collections/\(collection)")
    let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
        if let error = error {
            //shared.errorMessage = "error: \(error)"
            print ("error: \(error)")
            if (collection=="userInfo"){
            self.postedUserInfo = true
            } else {
                 self.postedOrder = true
            }
            return
        }
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            //shared.errorMessage = "server error"
            print ("server error")
             if (collection=="userInfo"){
            self.postedUserInfo = true
            } else {
                self.postedOrder = true
            }
            return
        }
        if let mimeType = response.mimeType,
           mimeType == "application/json",
           let data = data,
           // let _ = String(data: data, encoding: .utf8) {
           let dataString = String(data: data, encoding: .utf8) {
           // print("POST to \(collection) successful")
            if (collection.elementsEqual("userInfo")){
                //shared.errorMessage = "Account created successfully"
                print("Account created successfully")
            }
            print ("got data: \(dataString)")
        if (collection=="userInfo"){
            self.postedUserInfo = true
            } else {
                self.postedOrder = true
            }
            //dataString is of form:
            /*
             {"documentId":"58171bbd-cd42-4c54-a5f7-ed146097d1dc"}
             */
        }
    }
    task.resume()
    //print("end of post request method")
}

//creates account for user with userInfo
private func postRequest(userInfo:UserInfo){
    //print("in post request method")
    //to turn userInfo into JSON
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let uploadData = try? encoder.encode(userInfo) else {
        return
        //could not convert to type data
    }
    // print("Here is JSON uploadData:")
    //print(String(data: uploadData, encoding: .utf8)!)
    postRequest(uploadData: uploadData, collection: "userInfo")
    while self.postedUserInfo==false{
        Thread.sleep(forTimeInterval: 0.01)
        //after while loop orders will be complete
    }
    self.postedUserInfo = false//re initialize
}

public func postRequest(order:Order){
    //print("in post request method")
    //to turn order into JSON
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let uploadData = try? encoder.encode(order) else {
        return
        //could not convert to type data
    }
    // print("Here is JSON uploadData:")
    postRequest(uploadData: uploadData, collection: "orders")
     while self.postedOrder==false{
        Thread.sleep(forTimeInterval: 0.01)
        //after while loop orders will be complete
    }
    self.postedOrder = false//re initialize
}

public func getOrdersWhereTotalIs(total:Double, userName:String)->[Order]{
    let orders1 = getAllOrdersForUserName(userName: userName).orders
    var result = [Order]()
    for order in orders1 {
        var sum = 0.0
        for item in order.getReceipt(){
            sum+=item.getPrice()
        }
        if (sum == total){
            result.append(order)
        }
    }
    print("There are \(result.count) order(s) whose total is \(total) for \(userName)")
    return result
}

public func setOrderToPaid(docID:String){
    //does not check whether docID exists in db
    //if docID does not exist in db, this will create a new doc with only one param,
    //paid : true
    setOrderStatusToPaid(docID:docID)
    while (self.setToPaid==false){
        Thread.sleep(forTimeInterval: 0.01)
    }
    self.setToPaid = false
    print("Order \(docID) set to paid = true.")
}

private func setOrderStatusToPaid(docID:String){
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let uploadData = try? encoder.encode(Paid(paid:true)) else {
        setToPaid = true//to avoid infinite loop in setOrderToPaid
        return
        //could not convert to type data
    }
    
    let request = httpRequest(httpMethod: "PATCH", endUrl: "/namespaces/keyspacename1/collections/orders/\(docID)")
    let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
        if let error = error {
            print ("error: \(error)")
            self.setToPaid = true
            return
        }
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            print ("server error")
            self.setToPaid = true
            return
        }
        if let mimeType = response.mimeType,
           mimeType == "application/json",
           let data = data,
           // let _ = String(data: data, encoding: .utf8) {
           let dataString = String(data: data, encoding: .utf8) {
            self.setToPaid = true
            print ("got data: \(dataString)")
            
            //dataString is of form:
            /*
             {"documentId":"58171bbd-cd42-4c54-a5f7-ed146097d1dc"}
             */
        }
        self.setToPaid = true//might not be necessary
    }
    task.resume()
}


private func httpRequest(httpMethod: String, endUrl: String)-> URLRequest {
    /*
     code for this function is taken/copied from : https://developer.apple.com/documentation/foundation/url_loading_system/uploading_data_to_a_website
     */
    // print("start of httprequest method")
    //print("endURL is: "+endUrl)
    // print("https://"+ASTRA_DB_ID+"-"+ASTRA_DB_REGION+".apps.astra.datastax.com/api/rest/v2"+endUrl)
    let str = "https://"+ASTRA_DB_ID+"-"+ASTRA_DB_REGION+".apps.astra.datastax.com/api/rest/v2"+endUrl
    //let url = URL(string: str)!
    let encodedStr = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    // print("encodedStr = \(encodedStr)")
    
    let url = URL.init(string:encodedStr)! //"https://"+ASTRA_DB_ID+"-"+ASTRA_DB_REGION+".apps.astra.datastax.com/api/rest/v2/namespaces/keyspacename1/collections/orders")!
    
    var request = URLRequest(url: url)
    request.httpMethod = httpMethod//"POST" or "GET
    if (httpMethod=="POST"){
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    request.setValue("application/json", forHTTPHeaderField: "accept")
    request.setValue(ASTRA_DB_TOKEN, forHTTPHeaderField: "X-Cassandra-Token")
    // print("end of httprequest method")
    return request
}

private func deleteUserInfoRequest(docID:String){
    deleteRequest(docID: docID, collectionID: "userInfo")
}

public func deleteOrderRequest(docID:String){
    deleteRequest(docID: docID, collectionID: "orders")
}

private func deleteRequest(docID:String, collectionID:String){
    let request = httpRequest(httpMethod: "DELETE", endUrl: "/namespaces/keyspacename1/collections/\(collectionID)/\(docID)")
    let task = URLSession.shared.dataTask(with: request){ data, response, error in
        if let error = error {
           // shared.errorMessage = "error: \(error)"
            print ("error: \(error)")
            self.deletedDoc = true
            return
        }
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            //shared.errorMessage = "server error"
            print ("server error")
            self.deletedDoc = true
            return
        }
        self.deletedDoc = true
        print("Deletion successful")
    }
    task.resume()
    while self.deletedDoc==false{
        Thread.sleep(forTimeInterval: 0.01)
    }
    self.deletedDoc = false//re initialize
    //print("end of delete doc function")
}

public func printSortedOrdersFor(userName:String){
    print("Fetching orders...")
    let orders1 = getAllOrdersForUserName(userName: userName).orders.sorted(by: {
                 $0.getTime().compare($1.getTime()) == .orderedDescending//sorts so that newer orders are at the top
             })
    //printOrders(orders:orders1)
    for order in orders1 {
        print(getOrderAsString(order:order))
    }
    print("There are \(orders1.count) order(s).")
}

public func printNotSortedOrdersFor(userName:String){
    print("Fetching orders...")
    let (str, num) = getAllOrdersForUserNameAsString(userName:userName)
    print(str)
    print("There are \(num) order(s).")
}

   
}