import Foundation

//public struct Order {
    //let userName : String
    //public init(userName:String){
      //  self.userName = userName
    //}
    //public func printUserName(){
      //  print(userName)
  //  }
//}


    
public let userNames = ["Michael1", "Dwight1", "Jim1", "Pam1", "Angela1", "Kevin1",
             "Oscar1", "Phillys1", "Stanley1", "Andy1", "Toby1", "Kelly1",
             "Ryan1", "David1", "Gabe1", "Robert1", "Creed1", "Roy1", "Darryl1",
             "Jan1", "Holly1", "Mose1", "Joe1"]




public struct Item : Codable {
    
     let price : Double
     let users : [String]
    public init(price:Double, users:[String]){
        self.price = price
        self.users = users
    }
    public func getPrice()->Double{return self.price}
    public func getUsers()->[String]{return self.users}

}

public struct Order : Codable {
     let userName : String
     let receipt : [Item]
     var paid : Bool
     let time : String
    public init(userName:String, receipt:[Item], paid:Bool, time:String){
        self.userName = userName
        self.receipt = receipt
        self.paid = paid
        self.time = time
    }
    public func getUserName()->String{return self.userName}
    public func getReceipt()->[Item]{return self.receipt}
    public func getPaid()->Bool{return self.paid}
    public func getTime()->String{return self.time}
}

public struct UserInfo : Codable {
     let userName : String
     let password : String
    public init(userName:String, password:String){
        self.userName = userName
        self.password = password
    }
    public func getUserName()->String{return self.userName}
    public func getPassword()->String{return self.password}
}

public func getRandomSetOfUserNames()->Set<String>{
    let numUserNames = Int.random(in: 2..<userNames.count/3)
    var setOfUserNames = Set<String>()
    for _ in 0..<numUserNames {
        var randInt = Int.random(in: 0..<userNames.count)
        while (setOfUserNames.contains(userNames[randInt])){
            randInt = Int.random(in: 0..<userNames.count)
        }
        setOfUserNames.insert(userNames[randInt])
    }
    return setOfUserNames
}

public func getRandomOrder(userNames:[String])->Order{
    //userNames has length of at least 2
    //userNames shoudl be list of DISTINCT strings
    //example:["Arthur2", "Marie123", "Victor12"]
    //one of these will be the user who pays
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "M/d/y, HH:mm:ss"//"YY/MM/dd"
    let payerNameIndex = Int.random(in: 0..<userNames.count)
    var receipt = [Item]()
    let numItems = Int.random(in: 2...15)//2...15 is arbitrary and small for testing, could make much bigger though
    for _ in 0..<numItems{
        let numUsers = Int.random(in: 1...userNames.count)
        var setOfIndices = Set<Int>()
        for _ in 0..<numUsers {
            //get a name from names randomly
            var index = Int.random(in: 0..<userNames.count)
            while (setOfIndices.contains(index)){
                index = Int.random(in: 0..<userNames.count)
                //to prevent repeat names
            }
            setOfIndices.insert(index)
        }
        var users = [String]()
        for i in setOfIndices{
            users.append(userNames[i])
        }
        let price = Double.random(in: 0.5...50.0)//0.5...50.0 is arbitrary
        let priceRounded = Double(round(100*price)/100)
        let item = Item(price: priceRounded, users: users)
        receipt.append(item)
    }
    let date = Date()
 
    let order = Order(userName:userNames[payerNameIndex], receipt:receipt, paid: false, time:dateFormatter.string(from:date))
    
    return order
}