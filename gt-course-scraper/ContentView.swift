//
//  ContentView.swift
//  gt-course-scraper
//
//  Created by Steve Shi on 4/23/22.
//

import SwiftUI
import SwiftSoup
import Alamofire

// SAMPLE courses, should be 0 in this case since they are pretty much full, if not zero then someone trolling
// CS2110   83167   81465
// CS2340   86068   81106
// LMC3442  86324

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
    @State private var curr_crnRes: [String: Int] = [:]
    @State private var curr_crn: String = ""
    @State private var cron_running = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("What semester are we looking at in \(String(ContentView.year_search_param))?")
                    Picker("\(curr_semester) semester", selection: $curr_semester) {
                        ForEach(ContentView.semester_list, id:\.self) {
                            Text($0)
                        }
                    }
                }
                Section {
                    Text("List of CRN to check (ex: 83167)")
                    HStack {
                        TextField("CRN #", text: $curr_crn)
                        Button(action: addCRN) {
                            Image(systemName: "plus")
                        }
                    }
                    List {
                        ForEach(curr_crnList, id: \.self) { currCrn in
                            Text("\(currCrn)   -->   \(curr_crnRes[currCrn] ?? -99)")
                        }.onDelete(perform: deleteCRN)
                    }
                }
                Section {
                    Text("Click to see the current seats for each CRN")
                    Button(action: checkAvailability) {
                        Label("Check Availaility", systemImage: "alarm")
                    }
                }
            }
            .navigationTitle("Course Checker")
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
        curr_crnRes[currCourse] = spotLeft
        return spotLeft
    }
    
    // Check the courses within curr_crnList for the user
    func checkAvailability() {
        if curr_crnList.count == 0 { return }
        var classSpots: [String: Int] = [:]
        for currCrn in curr_crnList {
            let seatsLeft = loadAvailability(for: currCrn)
            classSpots[currCrn] = seatsLeft
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
