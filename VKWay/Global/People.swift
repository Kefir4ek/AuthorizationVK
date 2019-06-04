
import UIKit
import Foundation
import Alamofire
import RealmSwift


fileprivate struct PeopleElement:Codable{
    var id:Int
    var first_name:String
    var last_name:String
    var photo_100:String
}
fileprivate struct PeopleData:Codable{
    var response:[PeopleElement]
}


class AllPeople{
    
    static var request = AllPeople()
    private init() {}
    
    func setPeopleDetails(people:People)  {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.vk.com"
        urlComponents.path = "/method/users.get"
        urlComponents.queryItems = [
            URLQueryItem(name: "access_token", value: Session.current.token),
            URLQueryItem(name: "user_ids", value: "\(people.id)"),
            URLQueryItem(name: "v", value: "5.95"),
            URLQueryItem(name: "fields", value: "nickname, photo_100")
        ]
        
        guard let url = urlComponents.url else { return }
        
        AF.request(url).response{ response in
            guard response.error==nil, let data = response.data else { return }
            
            guard let peopleData = try? JSONDecoder().decode(PeopleData.self, from: data) else { return }
            
            guard peopleData.response.count > 0 else { return }
            let element = peopleData.response[0]
            
            let name = element.first_name+" "+element.last_name
            people.name         = name
            people.avatarURL    = element.photo_100
            people.avatar       = FileSystem.current.getImage(url: element.photo_100)
            
        }
        
        
    }
    
}


class People{
    
    var name:String = ""
    var avatar:UIImage?
    var avatarURL:String = ""
    var id:Int = 0
    
    init(id:Int) {
        self.id = id
    }
    
    init(id:Int, name:String, avatar:String="") {
        self.name       = name
        self.id         = id
        self.avatarURL  = avatar
    }
    
    init(realmObject: PeopleRealm) {
        self.name       = realmObject.name
        self.id         = realmObject.id
        self.avatarURL  = realmObject.avatarURL
        if let imageData = realmObject.avatar {
            self.avatar     = UIImage(data: imageData)
        }
    }
    
}



class PeopleRealm: Object{
    
    @objc dynamic var name:String = ""
    @objc dynamic var avatarURL:String = ""
    @objc dynamic var id:Int = 0
    @objc dynamic var avatar:Data?
    
    convenience init(_ people:People) {
        self.init()
        self.id         = people.id
        self.avatarURL  = people.avatarURL
        self.name       = people.name
        self.avatar     = people.avatar?.jpegData(compressionQuality: 1)
    }
    
    convenience init(_ id:Int, _ name:String, _ avatarURL:String) {
        self.init()
        self.id         = id
        self.avatarURL  = avatarURL
        self.name       = name
        self.avatar     = UIImage(url: avatarURL)?.jpegData(compressionQuality: 1)
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}

