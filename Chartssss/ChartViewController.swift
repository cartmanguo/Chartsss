//
//  ChartViewController.swift
//  Chartssss
//
//  Created by randy on 16/8/24.
//  Copyright © 2016年 Alpha. All rights reserved.
//

import UIKit
import Charts
import SVProgressHUD
struct StreamDataModel
{
    var eventType:String
    var timestamp:Int
    var data:AnyObject
}
class ChartDateFormater:NSObject,IAxisValueFormatter
{
    var dateFormatter:NSDateFormatter!
    override init()
    {
        super.init()
        dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
    }
    
    func stringForValue(value: Double, axis: AxisBase?) -> String {
        return dateFormatter.stringFromDate(NSDate(timeIntervalSince1970: value))
    }
}
class ChartViewController: UIViewController {
    var lineChart:LineChartView!
    override func viewDidLoad() {
        super.viewDidLoad()
        lineChart = LineChartView()
        lineChart.noDataText = "等待数据..."
        view.addSubview(lineChart)
        lineChart.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[lineChart]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["lineChart":lineChart]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[lineChart]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["lineChart":lineChart]))
        lineChart.rightAxis.enabled = false
        lineChart.descriptionText = ""
        lineChart.infoFont = UIFont.systemFontOfSize(16)
        lineChart.infoTextColor = UIColor.blackColor()
        lineChart.dragEnabled = true;
        lineChart.drawGridBackgroundEnabled = false;
        lineChart.pinchZoomEnabled = true
        //        lineChart.setScaleEnabled(true)
        lineChart.scaleXEnabled = true
        lineChart.scaleYEnabled = false
        lineChart.doubleTapToZoomEnabled = false
        lineChart.highlightPerDragEnabled = true
        lineChart.backgroundColor = UIColor.clearColor()
        
        lineChart.legend.form = .Line;
        lineChart.legend.font = UIFont(name: "HelveticaNeue-Light", size: 14)!
        lineChart.legend.textColor = UIColor.blackColor()
        lineChart.legend.position = Legend.Position.AboveChartLeft
        
        let xAxis = lineChart.xAxis;

        xAxis.valueFormatter = ChartDateFormater()
        xAxis.labelPosition = XAxis.LabelPosition.Bottom
        
        let leftAxis = lineChart.leftAxis;
        leftAxis.labelTextColor = UIColor.blackColor()
        leftAxis.granularityEnabled = true
        leftAxis.axisMinimum = 0
        leftAxis.drawGridLinesEnabled = true
        leftAxis.yOffset = -9.0
        
        SVProgressHUD.showWithStatus("DDD")
        self.listHistoryDataPointsForString()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func timestampFromOneNetDateString(dateString:String)->NSTimeInterval?
    {
        let format = NSDateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let date = format.dateFromString(dateString)
        return date!.timeIntervalSince1970
    }

    
    func listHistoryDataPointsForString()
    {
        var streamDatas = [StreamDataModel]()
        let requestUrlString = "http://api.heclouds.com/datapoints?device_id=3259642&datastream_id=I4F01&start=2016-08-23T15:26:34&end=2016-08-23T18:26:34"
        print(requestUrlString)
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let request = NSMutableURLRequest(URL: NSURL(string: requestUrlString)!)
        request.setValue("WSrXtvJMq3PwLyhQtXR0l5fEAsM=", forHTTPHeaderField: "api-key")
        let task = session.dataTaskWithRequest(request, completionHandler: {(data,response,error) in
            //            completionHandler(data: data, response: response, err: error)
            if error == nil
            {
                let json = JSON(data: data!)
                if json["errno"].int == 0
                {
                    let dataPointsArray = json["data"]["datapoints"].array
                    //                    print(dataPointsArray)
                    for dataPoint in dataPointsArray!
                    {
                        let time = dataPoint["at"].string
                        let value = dataPoint["value"].object
                        let streamData = StreamDataModel(eventType: "", timestamp: Int(self.timestampFromOneNetDateString(time!)!), data: value)
                        streamDatas.append(streamData)
                    }
                    dispatch_async(dispatch_get_main_queue(), {() in
                        self.setupChart(streamDatas)
                        })
                }
                else
                {
                    SVProgressHUD.dismiss()
                }
            }
            else
            {
                SVProgressHUD.dismiss()
            }
        })
        task.resume()
    }
    
    func setupChart(datas:[StreamDataModel])
    {
        SVProgressHUD.dismiss()
        if datas.count == 0
        {
            return
        }
        var entries = [ChartDataEntry]()
        for (_,streamData) in datas.enumerate()
        {
            let timestamp = streamData.timestamp

                let value = streamData.data as! NSNumber
                let chartEntry = ChartDataEntry(x: Double(timestamp), y: Double(value))
                entries.append(chartEntry)
            
        }
        var dataSet:LineChartDataSet
        if self.lineChart.data?.dataSetCount > 0
        {
            dataSet = self.lineChart.data?.dataSets[0] as! LineChartDataSet
            dataSet.values = entries
            self.lineChart.data?.notifyDataChanged()
            self.lineChart.notifyDataSetChanged()
        }
        else
        {
            dataSet = LineChartDataSet(values: entries, label: "data")
            dataSet.axisDependency = YAxis.AxisDependency.Left
            dataSet.setCircleColor(UIColor.orangeColor())
            dataSet.setColor(UIColor.orangeColor())
            dataSet.lineWidth = 2
            dataSet.circleRadius = 3
            dataSet.drawCircleHoleEnabled = false
            dataSet.valueFont = UIFont.systemFontOfSize(9)
            dataSet.drawValuesEnabled = false
            dataSet.drawCirclesEnabled = false
            var dataSets = [LineChartDataSet]()
            dataSets.append(dataSet)
            let data = LineChartData(dataSets: dataSets)
            data.setValueTextColor(UIColor.blackColor())
            self.lineChart.data = data
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
