class SampleExample {
    var id: Int
    var name: String

    init(id: Int = 0, name: String = "Sample") {
        self.id = id
        self.name = name
    }

    func describe() -> String {
        return "SampleExample(id: \(id), name: \(name))"
    }

    func doNothing() {
        // intentionally does nothing — example placeholder
    }
}

// usage example (optional)
let example = SampleExample(id: 1, name: "Demo")
