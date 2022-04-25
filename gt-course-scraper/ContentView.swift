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
import Cron

// SAMPLE courses, should be 0 in this case since they are pretty much full, if not zero then someone trolling
// CS2110   83167   81465
// CS2340   86068   81106

// Should be 7 as of 10:33PM on 23rd, check if not
// LMC3442  86324

struct ContentView: View {
//    private let TWILIO_ACCOUNT_SID="123456789...."  // Twilio Account SID in your console
//    private let TWILIO_AUTH_TOKEN="123456789...."   // Twilio Account Token in your console
//    private let TWILIO_NUMBER="+1XXXXXXXXXX"        // Twilio Phone number that you purchased with available credit
//    private let PERSONAL_NUMBER="+1XXXXXXXXXX"      // Personal Number that you verifie with Twilio, must be verified with Twilio

    
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
    @State private var cron_running = false
    
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
    func makeTwilioRequest(msg httpBody: String) {
        print("SENDING")
        let url = "https://api.twilio.com/2010-04-01/Accounts/\(TWILIO_ACCOUNT_SID)/Messages"
        let parameters = ["From": TWILIO_NUMBER, "To": PERSONAL_NUMBER, "Body": httpBody]
        
        AF.request(url, method: .post, parameters: parameters)
            .authenticate(username: TWILIO_ACCOUNT_SID, password: TWILIO_AUTH_TOKEN)
            .responseJSON { response in
                debugPrint(response)
            }
    }
    
    // Compose the actual message if there is a need to tell the user
    func makeMessage(for classSpots: [String: Int]) -> String {
        var bodyMsg = "There is an available spot for one of the crn below"
        for classSpot in classSpots {
            bodyMsg.append("\n \(classSpot.key): \(classSpot.value)")
        }
        
        return bodyMsg
    }
    
    // Begin notifying the courses within curr_crnList for the user
    func notify() {
        // print(ProcessInfo.processInfo.environment["TWILIO_ACCOUNT_SID"]) Not working, skip for now, cry later, all env are nil??

        cronInterval()
//        if curr_crnList.count == 0 { return }
//        var classSpots: [String: Int] = [:]
//        for currCrn in curr_crnList {
//            let seatsLeft = loadAvailability(for: currCrn)
//            classSpots[currCrn] = seatsLeft
//            //if seatsLeft != 0 { classSpots[currCrn] = seatsLeft }
//        }
//        let httpBody = makeMessage(for: classSpots)
//        //print(httpBody)
//        makeTwilioRequest(msg: httpBody)
    }
    
    func cronInterval() {
        cron_running.toggle()
        do {
            let job = try? CronJob(pattern: "* * * * * *", job: {
                print(cron_running)
            })
        } catch {
            print(error)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//        // Prepare URL
//        let url = URL(string: "https://api.twilio.com/2010-04-01/Accounts/\(TWILIO_ACCOUNT_SID)/Messages")
//        let parameters = ["From": TWILIO_NUMBER,
//                          "To": PERSONAL_NUMBER,
//                          "Body": "Steve Says Hi!👋"]
//        guard let requestUrl = url else { fatalError() }
//
//        // Prepare URL Request Objects
//        var request = URLRequest(url: requestUrl)
//        request.httpMethod = "POST"
//
//        let postString = "From=\(TWILIO_NUMBER)&To=\(PERSONAL_NUMBER)&Body=Steve Says Hi!👋"
//        request.httpBody = postString.data(using: String.Encoding.utf8)
//
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in // FOR SOMEREASON NOT WORKING
//            if let error = error {
//                print("Error occured:\n \(error)")
//                return
//            }
//
//            if let data = data, let dataString = String(data: data, encoding: .utf8) {
//                print("Reponse data string:\n \(dataString)")
//            }
//        }
