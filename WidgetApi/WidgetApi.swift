//
//  WidgetApi.swift
//  WidgetApi
//
//  Created by Randimal Geeganage on 2021-06-17.
//

import WidgetKit
import SwiftUI

// first creating model for wodget data

struct Model : TimelineEntry {
    var date : Date
    var widgetData : [JSONModel]
}

//creating model for json data

struct JSONModel: Decodable,Hashable {
    var date : CGFloat
    var units : Int
}


//provider for providing data for widget
  
struct Provider : TimelineProvider {
    
    
    func getSnapshot(in context: Context, completion: @escaping (Model) -> ()) {
        let loadingData = Model(date: Date(), widgetData: Array(repeating: JSONModel(date: 0, units: 0), count: 6))
        completion(loadingData)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Model>) -> ()) {
        
        //parsing json data and displaying...
         
        getData{ (modelData) in
            
            let date = Date()
            let data = Model(date: date, widgetData: modelData)
            
            //creating timeline
            //reloading every 15 min
            
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15 , to: date)
            let timeLine = Timeline(entries: [data], policy: .after(nextUpdate!))
            
            completion(timeLine)
        }
    }
    
    func placeholder(in context: Context) -> Model {
        
        return Model(date: Date(), widgetData: Array(repeating: JSONModel(date: 0, units: 0), count: 6))
        
    }
}

struct WidgetView:View {
    var data : Model
    
    var colors = [Color.red, Color.green, Color.blue, Color.yellow, Color.purple, Color.black]
    var body: some View{
        VStack(alignment: .center, spacing: 15) {
            HStack(spacing:15) {
                Text("Unit Sold")
                    .font(.title)
                    .fontWeight(.bold)
                Text(Date(),style:.time)
                    .font(.caption2)
            }.padding()
            
            HStack( spacing: 15) {
                ForEach(data.widgetData,id:\.self){value in
                    if value.units == 0 && value.date == 0 {
                        
                        //data is loading

                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.black)
                    }
                    else{
                        VStack(spacing:15){
                            Text("\(value.units)")
                            
                            //graph
                            
                            GeometryReader{g in
                                VStack{
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(colors.randomElement()!)
                                        .frame( height:getHeight(value: CGFloat(value.units), height: g.frame(in: .global).height))
                                }
                            }
                            
                            //date
                            
                            Text(getData(value: value.date))
                            font(.caption2)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    func getHeight(value:CGFloat,height:CGFloat) -> CGFloat {
        let max = data.widgetData.max{(first, second)-> Bool in
            if first.units > second.units{return false}
            else{return true}
        }
        let percent = value/CGFloat(max!.units)
        return percent * height
    }
    
    
    func getData(value: CGFloat)->String{
        let format = DateFormatter()
        format.dateFormat = "MMM dd"
        
        let date = Date(timeIntervalSince1970: Double(value)/1000.0)
        return format.string(from: date)
    }
}



@main
struct MainWidget: Widget {
    var body: some WidgetConfiguration{
        StaticConfiguration(kind: "WidgetApi", provider: Provider()){data in
            WidgetView(data: data)
        }
        .description(Text("Daily Status"))
        .configurationDisplayName(Text("Daily updates"))
        .supportedFamilies([.systemLarge])
    }
}


//attaching completion handler to send back data

func getData(completion: @escaping([JSONModel]) -> ()) {
    let url = "https://canvasjs.com/data/gallery/javascript/daily-sales-data.json"
    
    let session = URLSession(configuration: .default)
    
    session.dataTask(with: URL(string: url)!) { (data, _, err) in
        
        if err != nil{
            print((err!.localizedDescription))
            return
        }
        do{
            let jsonData = try JSONDecoder().decode([JSONModel].self, from: data!)
            completion(jsonData)
            
        }
        catch{
            print(error.localizedDescription)
        }
    }.resume()
}

