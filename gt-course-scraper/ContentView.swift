//
//  ContentView.swift
//  gt-course-scraper
//
//  Created by Steve Shi on 4/23/22.
//

import SwiftUI

// Testing courses
// CS2110   83167   81465
// CS2340   86068   81106

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
    
    @State private var classSpots: [Int] = []
    
    // Parsing the whole html entities from the web using the oscar_url
    // Oscar-url example: https://oscar.gatech.edu/bprod/bwckschd.p_disp_detail_sched?term_in=201508&crn_in=83686
    // term_in=201508&crn_in=83686      need param: year(20??), semester(08/02/05), crn??
    func loadAvailability(for currCourse: String) -> Int {
        do {
            let oscarURL = URL(string: url_routes
                               + ContentView.semester_param[ContentView.semester_list.firstIndex(of: curr_semester)!]
                               + url_search
                               + currCourse)
            
            let oscarContents = try String(contentsOf: oscarURL!) //, encoding: String.Encoding.ascii)
            
            print(oscarContents)
        } catch {
            print("Error loading up the contents for the url")
            curr_crnList.remove(at: curr_crnList.firstIndex(of: currCourse)!)
        }
        return 0
    }
    
    func addCRN() {
        let tempCrn = curr_crn.trimmingCharacters(in: .whitespacesAndNewlines)
        curr_crn = ""
        if tempCrn.count != 5 || Int(tempCrn) == nil || curr_crnList.contains(tempCrn){ return } // CRN # has to be a 5 count integer
        curr_crnList.append(tempCrn)
    }
    
    func notify() {
        print("START NOTIFIYING")
        if curr_crnList.count == 0 { return }
        //if phoneNum.count != 10 { return }
        for currCrn in curr_crnList {
            print("Attempting to load up availability for: " + currCrn)
            classSpots.append(loadAvailability(for: currCrn))
        }
        print("Mission successful")
    }
    
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
                        }
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
