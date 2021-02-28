import SwiftUI

struct EditDevice: View {    
    @State var name = ""
    @State var ip = ""
    @State var port = ""
    var index = 0

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Device.name, ascending: true)],
        animation: .default)
    private var devices: FetchedResults<Device>

    var body: some View {
        VStack {
            NavigationView {
                Form {
                    HStack {
                        Text("Name: ")
                        TextField("Name", text: $name)
                    }
                    HStack {
                        Text("IP: ")
                        TextField("IP", text: $ip)
                    }
                    HStack {
                        Text("UDP Port: ")
                        TextField("Port", text: $port)
                    }
                }
                .onAppear() {
                    if !devices.isEmpty {
                        name = devices[index].name!
                        ip = devices[index].ip!
                        port = devices[index].port!
                    }
                }
                .onDisappear {
                    if !devices.isEmpty {
                        devices[index].name = name
                        devices[index].ip = ip
                        devices[index].port = port
                        do {
                            try viewContext.save()
                        } catch {
                            let nsError = error as NSError
                            NSLog("EditDevice.onDisappear viewContext.save() error \(nsError), \(nsError.userInfo)")
                        }
                    }
                }
                .frame(height: 760, alignment: .top)
                .navigationTitle("Device Settings")
            }
            .frame(height: 600, alignment: .top)
        }
    }
}

struct EditDevice_Previews: PreviewProvider {
    static var previews: some View {
        EditDevice()
    }
}
