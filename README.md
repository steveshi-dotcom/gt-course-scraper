# gt-course-scraper
Get notified class availability for the list of CRNs inputted. (Work in progress)

## Registering for Twilio Account
In order to make the app work, you must first obtain a free account on twilio, the api used for messaging
Register for a free account on [Twilio](https://www.twilio.com/) or ugrade if more message is needed. After buying the free trial phone #, input the following four value into the four respective variables that are located on the top of ContentView.swift file
- Account SID
- Account Auth Token
- Your Twilio #
- YOur personal Number

## Inputting courses to listen message for
Input the list of CRN # and click on notify and whenever a spot is opened, a message will be sent from the Twilio API to the personal # from Twilio # inputted. If not working, double check to make sure all info such as the account sid/token/twilio#/personal# is inputted correctly
