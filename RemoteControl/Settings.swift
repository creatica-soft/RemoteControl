import SwiftUI

struct Settings: View {
    @AppStorage("defaultName") var defaultName = "<New Device>"
    @AppStorage("defaultIp") var defaultIp = "0.0.0.0"
    @AppStorage("defaultPort") var defaultPort = "0"
    @AppStorage("defaultOn") var defaultOn = false

    var body: some View {
        VStack {
            NavigationView {
                Form {
                    HStack {
                        Text("Default Name: ")
                        TextField("Name", text: $defaultName)
                    }
                    HStack {
                        Text("Default IP: ")
                        TextField("IP", text: $defaultIp)
                    }
                    HStack {
                        Text("Default Port: ")
                        TextField("Port", text: $defaultPort)
                    }
                    Toggle(isOn: $defaultOn) {
                        Text("On")
                    }
                }
                .frame(height: 760, alignment: .top)
                .navigationTitle("App Settings")
            }
            .frame(height: 600, alignment: .top)
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
