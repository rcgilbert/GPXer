# GPXer
A GPX Reading App with SiriKit Integration

## Functionality 
### GPX Storage and Export

This app's core functionality is to allow a user to store and manage GPX files across their Apple services. It stores the GPX data in CoreData which automatically syncs using CloudKit. 
If a user would like to export their GPX data from the app it can easily be done through the share button on the track details screen.

<img src="https://user-images.githubusercontent.com/359394/196279823-e63dc793-aa71-497f-be19-71a0ec4ed32d.png" width="250">

### GPX Map Display and Stats

Each track has a details screen where an interactive map of the track is displayed along with a few basic stats of the track. 
Here the app also allows for some basic editing capabilities like changing the track's name. 

<img src="https://user-images.githubusercontent.com/359394/196280870-115cbe92-bf29-4d19-b120-bbd4d3bf9107.png" width="250">

### SiriKit Integration

This app includes a simple SiriKit integration that allows users to obtain the approximate mile marker of a location along the track. 
This is surfaced as a shortcut action in the Shortcuts app and can be combined with other actions to create unique tracking workflows. 

<img src="https://user-images.githubusercontent.com/359394/196281988-9a0f5016-759d-4f85-a26e-2f10d291c9cb.png" width="250">

### Compound Track Creation

In some cases, GPX files can get large and cumbersome so tracks may be split up into multiple files. 
This app allows the user to combine multiple tracks and treat them as a single track. 
The app still stores the data of each track separately but also contains additional data for how these separate tracks relate to each other. 

<img src="https://user-images.githubusercontent.com/359394/196284274-b7e9f3b9-d65b-49bb-87c4-5f8dfdae26c9.png" width="250">

## Development Process and Goals

### App Inspiration 
I created this app as I prepared for my 6-month-long Pacific Crest Trail hike. 
I wanted a way to store GPS data on the trail and use it to automate some simple tracking and journaling. 
The goal was to create a basic MVP that integrated with Shortcuts for my personal use while hiking. 

### Prototype not Production
This app is in no way production ready. 
I focused on creating a proof-of-concept where I could prototype my ideas and learn new technologies along the way. Because of this, the speed of development topped code quality. In a production-ready app testability and readability of the code would have been prioritized much more. 
There are also likely more bugs and performance issues with this app than with a production-level app. 

### Technologies Used
This app was originally developed for iOS 15. I made some recent small changes to update it for iOS 16 but it still has not adopted many of the API improvements that came with iOS 16. 

The core technologies used within this app include:
- SwiftUI
- CoreData with CloudKit
- SiriKit Intents
