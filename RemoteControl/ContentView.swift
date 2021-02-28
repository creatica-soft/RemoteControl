import SwiftUI
import CoreData
import Network

struct ContentView: View {
    @AppStorage("defaultName") var defaultName = "<New Device>"
    @AppStorage("defaultIp") var defaultIp = "0.0.0.0"
    @AppStorage("defaultPort") var defaultPort = "0"
    @AppStorage("defaultOn") var defaultOn = false
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Device.name, ascending: true)],
        animation: .default)
    private var devices: FetchedResults<Device>
    @State var on = Array(repeating: false, count: maxNumberOfDevices)
    @State var deviceNumberLimitExceededAlert = false

    var body: some View {
        NavigationView{
            List {
                ForEach(devices) { device in
                    NavigationLink(
                        destination: EditDevice(index: devices.firstIndex(of: device)!),
                        label: {
                            Text("\(device.name!)")
                            Toggle("", isOn: $on[devices.firstIndex(of: device)!])
                        })
                    }
                    .onDelete(perform: deleteItems)
            }
            .toolbar {
                HStack(content: {
                    EditButton()
                    .frame(width: 155, alignment: .leading)
                    NavigationLink(destination: Settings()) {
                        Label("Settings", systemImage: "gear")
                    }
                    .frame(width: 20, alignment: .center)
                    Button(action: addItem) {
                        Label("Add Device", systemImage: "plus")
                    }
                    .frame(width: 140, alignment: .trailing)
                })
                .padding()
            }
            .onAppear(perform: {
                for device in devices {
                    on[devices.firstIndex(of: device)!] = device.on
                }
            })
            .onDisappear() {
                for device in devices {
                    device.on = on[devices.firstIndex(of: device)!]
                }
                do {
                    try viewContext.save()
                } catch {
                     let nsError = error as NSError
                    NSLog("onDisappear viewContext.save() error \(nsError), \(nsError.userInfo)")
                }
            }
            .onChange(of: on, perform: { value in
                var idx: Int
                for device in devices {
                    idx = devices.firstIndex(of: device)!
                    if device.on != value[idx] {
                        device.on = value[idx]
                        //on[idx] = value[idx]
                        do {
                            try viewContext.save()
                        } catch {
                            let nsError = error as NSError
                            NSLog("onChange viewContext.save() error \(nsError), \(nsError.userInfo)")
                        }
                        send(idx)
                        break;
                    }
                }
            })
            .navigationTitle("Remote Control")
            .alert(isPresented: $deviceNumberLimitExceededAlert) {
                Alert(title: Text("Error"), message: Text("Exeeded the device number limit of \(maxNumberOfDevices)"), dismissButton: Alert.Button.cancel())
            }

        }
    }

    func send(_ index: Int) {
        var data = Data(count: 0)
        if on[index] {
            data.append(contentsOf: [49])
        }
        else {
            data.append(contentsOf: [48])
        }
        let ip4 = IPv4Address(devices[index].ip!)!
        let host = NWEndpoint.Host.ipv4(ip4)
        let port = NWEndpoint.Port(devices[index].port!)!
        let endpoint = NWEndpoint.hostPort(host: host, port: port)
        let udpOption = NWProtocolUDP.Options()
        let params = NWParameters(dtls: nil, udp: udpOption)
        params.requiredInterfaceType = NWInterface.InterfaceType.wifi
        params.prohibitExpensivePaths = true
        params.preferNoProxies = true
        params.expiredDNSBehavior = NWParameters.ExpiredDNSBehavior.allow
        params.prohibitedInterfaceTypes = [.cellular]
        let conn = NWConnection(to: endpoint, using: params)

        conn.start(queue: .main)
        conn.send(content: data, completion: NWConnection.SendCompletion.contentProcessed({ err in
            if err != nil {
                switch(err){
                case .posix(let errcode):
                    NSLog("conn.send POSIXErrorCode: \(errcode)")
                case .dns(let dnserr):
                    NSLog("conn.send DNSServiceErrorType: \(dnserr)")
                case .tls(let osstat):
                    NSLog("conn.send OSStatus: \(osstat)")
                case .none:
                    NSLog("conn.send err none")
                case .some(let someerr):
                    NSLog("conn.send err \(someerr)")
                }
                NSLog("Error message: \(err.debugDescription)")
            }
            else {
                NSLog("sent %c to \(devices[index].name!) at \(devices[index].ip!):\(devices[index].port!)", data[0])
            }
        }))
    }

    private func addItem() {
        withAnimation {
            if devices.count < maxNumberOfDevices {
                let newItem = Device(context: viewContext)
                newItem.name = defaultName
                newItem.ip = defaultIp
                newItem.port = defaultPort
                newItem.on = defaultOn
                do {
                    try viewContext.save()
                } catch {
                    let nsError = error as NSError
                    NSLog("addItem viewContext.save() error \(nsError), \(nsError.userInfo)")
                }
            } else {
                deviceNumberLimitExceededAlert = true
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { devices[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                NSLog("deleteItems viewContext.save() error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
