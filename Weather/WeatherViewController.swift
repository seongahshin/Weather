//
//  WeatherViewController.swift
//  Weather
//
//  Created by 신승아 on 2022/08/17.
//

import UIKit

import Alamofire
import SwiftyJSON
import Kingfisher

// L1. import
import CoreLocation

var answer: [String] = []

class WeatherViewController: UIViewController {
    

    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var huminityLabel: UILabel!
    @IBOutlet weak var windLabel: UILabel!
    @IBOutlet weak var byeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var WeatherImage: UIImageView!
    
    
    
    // Location2. 위치에 대한 대부분을 담당
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key.description)
        }
        
        
        
        // Location3. 프로토콜 연결
        locationManager.delegate = self
        self.tempLabel.text = ""
        
        locationLabelDesign()
        view.backgroundColor = .blue
        WeatherImage.backgroundColor = .white
        locationLabel.backgroundColor = .white
        
    }
    
    func locationLabelDesign() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM월 dd일 HH시 mm분"
        let current_date_string = formatter.string(from: Date())
        dateLabel.text = current_date_string
        
    }
    
    
    func labelDesign() {
        print(#function)
        let labelList: [UILabel] = [locationLabel, tempLabel, huminityLabel, windLabel, byeLabel]
        guard let imp = UserDefaults.standard.array(forKey: "weatherInfoList") else { return }
        
        for num in 0...labelList.count - 1 {
            labelList[num].text = imp[num] as! String
            labelList[num].labelDetailDesign()
            labelList[num].layer.masksToBounds = true
            labelList[num].layer.cornerRadius = 10
        }
        
    }
    
    
    func callRequest() {
        
        let url = "\(EndPoint.WeatherURL)\(UserDefaults.standard.double(forKey: "latitude"))&lon=\(UserDefaults.standard.double(forKey:"longitude"))&appid=\(APIKey.WeatherKey)"
        var weatherInfoList: [String] = []
        
        
        AF.request(url, method: .get).validate().responseData { [self] response in
            switch response.result {
                    case .success(let value):

                        let json = JSON(value)
                        print("JSON: \(json)")
                
                var answer: [String] = []
                

                weatherInfoList.append(json["name"].stringValue)
                weatherInfoList.append("지금은 \(round(json["main"]["temp"].doubleValue - 273.15))도에요")
                weatherInfoList.append("\(json["main"]["humidity"].intValue)% 만큼 습해요")
                weatherInfoList.append("\(round(json["wind"]["speed"].doubleValue))m/s의 바람이 불어요")
                weatherInfoList.append("오늘도 행복한 하루 보내세요")
                weatherInfoList.append("\(EndPoint.WeatherIconURl)\(json["weather"][0]["icon"].stringValue)@2x.png")
                
               let url = URL(string: weatherInfoList[5])
                WeatherImage.kf.setImage(with: url)
                
                answer = weatherInfoList
                print(answer)
                UserDefaults.standard.set(answer, forKey: "weatherInfoList")
                labelDesign()
                
                
                
                    
                    case .failure(let error):
                        print(error)
            }
        }
    }
    
    func showRequestLocationServiceAlert() {
        print(#function)
      let requestLocationServiceAlert = UIAlertController(title: "위치정보 이용", message: "위치 서비스를 사용할 수 없습니다. 기기의 '설정>개인정보 보호'에서 위치 서비스를 켜주세요.", preferredStyle: .alert)
      let goSetting = UIAlertAction(title: "설정으로 이동", style: .destructive) { _ in
          if let appSetting = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.open(appSetting)
          }
      }
        
      let cancel = UIAlertAction(title: "취소", style: .default) { _ in
          let labelList: [UILabel] = [self.locationLabel, self.tempLabel, self.huminityLabel, self.windLabel, self.byeLabel]
          
          for num in 0...labelList.count - 1 {
              labelList[num].text = "위치권한이 꺼져있어요"
          }
          
          
          
      }
      requestLocationServiceAlert.addAction(cancel)
      requestLocationServiceAlert.addAction(goSetting)
      present(requestLocationServiceAlert, animated: true, completion: nil)
    }
    
    @IBAction func loadButtonClicked(_ sender: UIButton) {
        
        locationLabelDesign()
        callRequest()
        if self.tempLabel.text == "위치권한이 꺼져있어요" {
            showRequestLocationServiceAlert()
        }
    }
    
    
}

extension UILabel {
    func labelDetailDesign() {
        
        self.backgroundColor = .white
    }
}

// 위치 관련된 메서드 (User Defined 메서드)
extension WeatherViewController {
    
    // Location7. iOS 버전에 따른 분기 처리 및 iOS 위치 서비스 활성화 여부
    // 위치 서비스가 켜져있다면 권한을 요청하고, 꺼져 있다면 커스텀 Allert으로 상황 알려주기
    // CLAuthorizationStatus
    // - denied: 허용 안함 / 설정에서 추후에 거부 / 위치 서비스 중지 / 비행기 모드
    // - restricted: 앱에서 권한 자체가 없는 경우 / 자녀 보호 기능 같은 걸로 아예 제한
    func checkUserDeviceLocationServiceAuthorization() {
        print(#function)
        
        let authorizationStatus: CLAuthorizationStatus
        
        if #available(iOS 14.0, *) {
            // 인스턴스를 통해 locationManager가 가지고 있는 상태를 가져옴
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        // iOS 위치 서비스 활성화 여부 체크
        if CLLocationManager.locationServicesEnabled() {
            // 위치 서비스가 활성화 되어 있으므로, 위치 권한 요청 가능해서 위치 권한을 요청함
            checkUserCurrentLocationAuthorization(authorizationStatus)
        } else {
            print("위치 서비스가 꺼져있어 위치 권한 요청을 못합니다.")
        }
        
    }
    
    // Location 8. 사용자의 위치 권한 상태 확인
    // 사용자가 위치권한을 허용했는지, 거부했는지, 아직 선택하지 않았는지 등을 확인 (단, 사전에 iOS 위치 서비스 활성화 꼭 확인)
    func checkUserCurrentLocationAuthorization(_ authorizationStatus: CLAuthorizationStatus) {
        print(#function)
        switch authorizationStatus {
        case .notDetermined:
            print("NOTDETERMINED")
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            // 앱을 사용하는 동안에 위치 권한 요청
            // plist WhenInUse -> request 메서드 OK
//            locationManager.startUpdatingLocation()
            
        case .restricted, .denied:
            print("DENIED, 아이폰 설정으로 유도")
            
            showRequestLocationServiceAlert()
            
            
        
        case .authorizedWhenInUse:
            print("WHEN IN USE")
            // 사용자가 위치를 허용해둔 상태라면, startUpdatingLocation을 통해 didUpdateLocations 메서드가 실행
            locationManager.startUpdatingLocation()
            
        default: print("DEFAULT")
        }
    }
}



// Location4. 프로토콜 선언
extension WeatherViewController: CLLocationManagerDelegate {
    
    // Location5. 사용자의 위치를 성공적으로 가져온 경우에 해당
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(#function)
        
        // ex. 위도, 경도 기반으로 날씨 정보를 조회
        // ex. 지도를 다시 세팅
        
        
        if let coordinate = locations.last?.coordinate {
            
            let latitude = coordinate.latitude
            let longitude = coordinate.longitude
            UserDefaults.standard.set(latitude, forKey: "latitude")
            UserDefaults.standard.set(longitude, forKey: "longitude")
            callRequest()
            print("현재 위치의 위도: \(UserDefaults.standard.double(forKey: "latitude"))")
            print("현재 위치의 경도: \(UserDefaults.standard.double(forKey: "longitude"))")
            
            
//            labelDesign()
        }
            
        
        // 위치 업데이트 멈춰!
        locationManager.stopUpdatingLocation()
        
    }
    
    // Location6. 사용자의 위치를 가져오지 못한 경우에 해당
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(#function)

        callRequest()
        
        
        
    }
    
    // Location9. 사용자의 권한 상태가 바뀔 때를 알려줌
    // 거부했다가 설정에서 변경했거나, notDetermined에서 허용을 했거나 등
    // 허용을 해서 위치를 가져오는 도중에, 설정에서 거부하고 돌아온다면?
    // iOS 14 이상:
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print(#function)
        checkUserDeviceLocationServiceAuthorization()
    }
    
    // iOS 14 미만
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
    }
    
    
}




