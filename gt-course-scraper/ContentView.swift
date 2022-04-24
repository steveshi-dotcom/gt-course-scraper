//
//  ContentView.swift
//  gt-course-scraper
//
//  Created by Steve Shi on 4/23/22.
//

import SwiftUI
import SwiftSoup
import Foundation
import Alamofire

// SAMPLE courses, should be 0 in this case since they are pretty much full, if not zero then someone trolling
// CS2110   83167   81465
// CS2340   86068   81106

// Should be 7 as of 10:33PM on 23rd, check if not
// LMC3442  86324

// TODO: Check out what "[boringssl] boringssl_metrics_log_metric_block_invoke(153) Failed to log metrics" is in the debug terminal

struct ContentView: View {
    
    // Current Semester: Represented search param in oscar-url
    static private let semester_list = ["Fall", "Spring", "Summer"]
    static private let semester_param = ["08", "02", "05"]
    
    // Current date that will be used as one of the search param
    static private let year_search_param: Int = Calendar.current.component(.year, from: Date())
    
    // Oscar url that we are looking at, the route and the seperate search parameters
    private let url_routes = "https://oscar.gatech.edu/bprod/bwckschd.p_disp_detail_sched?term_in=\(year_search_param)"
    private let url_search = "&crn_in="
    
    @State private var curr_semester: String = semester_list[0]
    @State private var curr_crnList: [String] = []
    @State private var curr_crn: String = ""
    @State private var phoneNum: String = ""
        
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("What semester are we looking at in \(ContentView.year_search_param)?")
                    Picker("\(curr_semester) semester", selection: $curr_semester) {
                        ForEach(ContentView.semester_list, id:\.self) {
                            Text($0)
                        }
                    }
                }
                Section {
                    Text("List of CRN to notify you")
                    HStack {
                        TextField("CRN #", text: $curr_crn)
                        Button(action: addCRN) {
                            Image(systemName: "plus")
                        }
                    }
                    List {
                        ForEach(curr_crnList, id: \.self) { currCrn in
                            Text(currCrn)
                        }.onDelete(perform: deleteCRN)
                    }
                }
                Section {
                    Text("Phone number")
                    TextField("XXXXXXXXXX", text: $phoneNum)
                }
                Button(action: notify) {
                    Label("Notify Availaility", systemImage: "alarm")
                }
            }
            .navigationTitle("Course Notifier")
        }
    }
    
    // Append curr_crn to curr_crnList
    func addCRN() {
        let tempCrn = curr_crn.trimmingCharacters(in: .whitespacesAndNewlines)
        curr_crn = ""
        if tempCrn.count != 5 || Int(tempCrn) == nil || curr_crnList.contains(tempCrn){ return } // CRN # has to be a 5 count integer
        curr_crnList.append(tempCrn)
    }
    
    // Remove a crn from curr_crnList
    func deleteCRN(offset: IndexSet) {
        curr_crnList.remove(atOffsets: offset)
    }
    
    // Parsing the whole html entities from the web using the oscar_url
    // Oscar-url example: https://oscar.gatech.edu/bprod/bwckschd.p_disp_detail_sched?term_in=201508&crn_in=83686
    // term_in=201508&crn_in=83686      need param: year(20??), semester(08/02/05), crn??
    func loadAvailability(for currCourse: String) -> Int {
        var spotLeft: Int = 0
        do {
            let oscarURL = URL(string: url_routes
                               + ContentView.semester_param[ContentView.semester_list.firstIndex(of: curr_semester)!]
                               + url_search
                               + currCourse)
            
            let oscarContents = try String(contentsOf: oscarURL!)
            
            let doc: Document = try SwiftSoup.parse(oscarContents)
            let trElements: Elements = try doc.select("tr")
            
            // Attemps to look for the number of seats by looping through the
            for currTrElement in trElements {
                if try currTrElement.text().starts(with: "Seats") {
                    let seatTrEle: Element = try currTrElement.select("td").last()!
                    spotLeft = Int(try seatTrEle.text())!
                    break
                }
            }
        } catch Exception.Error(let type, let msg) {
            print("Error type: \(type)")
            print("Error Msg: \(msg)")
        } catch {
            print("Error loading up the contents for the url")
            curr_crnList.remove(at: curr_crnList.firstIndex(of: currCourse)!)
        }
        return spotLeft
    }
    
    // Check to see if there are any spots for the classSpot, if there is send a message, else return
    func makeTwilioRequest(for classSpots: [String: Int]) {
        if classSpots.count == 0 { return }
        for classSpot in classSpots {
            print(classSpot)
        }
        // Make http request to twilio
        if let accountSID = ProcessInfo.processInfo.environment["TWILIO_ACCOUNT_SID"],
           let authToken = ProcessInfo.processInfo.environment["TWILIO_AUTH_TOKEN"] {
            // Prepare URL
            let url = URL(string: "https://api.twilio.com/2010-04-01/Accounts/\(accountSID)/Messages")
            let parameters = ["From": "+16075369164", "To": "+13214822272", "Body": "Steve Says Hi!👋"]
            guard let requestUrl = url else { fatalError() }
            
            // Prepare URL Request Object
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "POST"
            
            let postString = "From=+16075369164&To=+13214822272&Body=Steve Says Hi!👋"
            request.httpBody = postString.data(using: String.Encoding.utf8)
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("Error occured:\n \(error)")
                    return
                }
                
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("Reponse data string:\n \(dataString)")
                }
            }
        }
    }
    
    // Begin notifying the courses within curr_crnList with the phoneNumber the user typed
    func notify() {
        if curr_crnList.count == 0 { return }
        //if phoneNum.count != 10 { return }
        var classSpots: [String: Int] = [:]
        for currCrn in curr_crnList {
            let seatsLeft = loadAvailability(for: currCrn)
            classSpots[currCrn] = seatsLeft
            //if seatsLeft != 0 { classSpots[currCrn] = seatsLeft }
        }
        makeTwilioRequest(for: classSpots)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
