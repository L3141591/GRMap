//
//  ContentView.swift
//  GRMap WatchKit Extension
//
//  Created by Wayne Lin on 2020/11/26.
//

import SwiftUI
import MapKit

struct ContentView: View {
    
    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var showSettingView: Bool = false
    @ObservedObject private var apiManager: FetchGRBatteryAPI = FetchGRBatteryAPI()
    
    private let locationManager: CLLocationManager = CLLocationManager()
    
    init() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    var body: some View {
        let regionBinding = Binding(
            get: {
                region
            },
            set: {
                region = $0
            })
        ZStack {
            Map(coordinateRegion: regionBinding, showsUserLocation: true, userTrackingMode: $userTrackingMode, annotationItems: apiManager.batteryList,  annotationContent: { place -> MapMarker in
                let marker = MapMarker(coordinate: place.coordinate)
                return marker
            })
            VStack {
                Spacer()
                HStack{
                    Spacer()
                    Button(action: {
                        withAnimation {
                            showSettingView = true
                        }
                    }, label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 25))
                            .foregroundColor(.gray).opacity(0.9)
                    })
                    .frame(width: 30, height: 30)
                    .padding([.trailing, .bottom], /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                }
            }
            if showSettingView {
                SettingView() {
                    withAnimation {
                        showSettingView = false
                    }
                }
            }
            if apiManager.isFinish == false {
                Group {
                    Color.black.opacity(0.5)
                    ProgressView()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct SettingView: View {
    let closeView: () -> Void
    
    var body: some View {
        Group {
            Color.black
            VStack {
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                    /*@START_MENU_TOKEN@*/Text("Button")/*@END_MENU_TOKEN@*/
                })
                Button(action: {
                    closeView()
                }, label: {
                    /*@START_MENU_TOKEN@*/Text("Button")/*@END_MENU_TOKEN@*/
                })
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct GRBatteryPlace: Identifiable {
    var id = UUID()
    let latitude: Double
    let longitude: Double
    var coordinate: CLLocationCoordinate2D {
      CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


class FetchGRBatteryAPI: ObservableObject {
    @Published var batteryList: [Battery] = [Battery]()
    @Published var isFinish: Bool = false
    
    init() {
        if let localData = UserDefaults.standard.data(forKey: "localData"), let decodedData = try? JSONDecoder().decode([BatteryAPIData].self, from: localData) {
            let batteryData = decodedData.map { (data) -> Battery in
                return Battery(id: data.Id, data: data)
            }
            DispatchQueue.main.async {
                self.batteryList = batteryData
            }
            isFinish = true
        } else {
            let url = URL(string: "https://webapi.gogoro.com/api/vm/list")!
            URLSession.shared.dataTask(with: url) {(data, response, error) in
                do {
                    if let batteryData = data {
                        let decodedData = try JSONDecoder().decode([BatteryAPIData].self, from: batteryData)
                        let batteryData = decodedData.map { (data) -> Battery in
                            return Battery(id: data.Id, data: data)
                        }
                        if batteryData.isEmpty == false {
                            if let encoded = try? JSONEncoder().encode(decodedData) {
                                UserDefaults.standard.set(encoded, forKey: "localData")
                            }
                        }
                        DispatchQueue.main.async {
                            self.batteryList = batteryData
                        }
                        print("data \(batteryData.count)")
                    } else {
                        print("No data")
                    }
                    self.isFinish = true
                } catch {
                    print(error)
                    self.isFinish = true
                }
            }.resume()
        }
    }
}

struct Battery: Identifiable {
    var id: String
    var data: BatteryAPIData
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: data.Latitude, longitude: data.Longitude)
    }
}

struct BatteryAPIData: Codable {
    var Id: String
    var Latitude: Double
    var Longitude: Double
}
