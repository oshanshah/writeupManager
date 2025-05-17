import UIKit

class AddWriteupViewController: UIViewController {
    struct AppTheme {
        static let lightRed = UIColor(hex: "#FDEDEE")   // Soft blush background (very light red/pink)
        static let coral = UIColor(hex: "#F7B7A3")   // Muted coral cell background
        static let brickRed = UIColor(hex: "#D94F4F")    // Deep brick red header or title accent
        static let warm = UIColor(hex: "#FF6F59")        // Warm coral text for course names
        static let red = UIColor(hex: "#E94F37")      // Vibrant tomato red for due date text
    }


    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        button.tintColor = UIColor.systemPink
        view.backgroundColor = AppTheme.lightRed
        titleValue.backgroundColor = .white
        courseValue.backgroundColor = .white
        Notes.backgroundColor = .white
        titleValue.textColor = AppTheme.brickRed
            }


    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.view.tintColor = AppTheme.red 
        self.present(alert, animated: true, completion: nil)
    }

    struct Writeup: Codable {
        let title: String
        let course: String
        let notes: String
        let portal: String
        let due: Date
        var isDone: Bool = false  // New field, default to false
    }

    func getFileURL() -> URL {
        let manager = FileManager.default
        let urls = manager.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("writeups.json")
    }
    
    func loadWriteups() -> [Writeup] {
        let url = getFileURL()
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Writeup].self, from: data)
        } catch {
            print("Error loading writeups: \(error)")
            return []
        }
    }

    func saveWriteup(_ writeup: Writeup) {
        var writeups = loadWriteups()
        writeups.append(writeup)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(writeups)
            try data.write(to: getFileURL())
        } catch {
            print("Error saving writeup: \(error)")
        }
    }

    @IBOutlet weak var titleValue: UITextField!
    @IBOutlet weak var courseValue: UITextField!
    @IBOutlet weak var Notes: UITextField!
    @IBOutlet weak var portal: UISegmentedControl!
    @IBOutlet weak var dateValue: UIDatePicker!

    @IBAction func buttonAdd(_ sender: Any) {
        let newWriteup = Writeup(
            title: titleValue.text ?? "Untitled",
            course: courseValue.text ?? "Unknown Course",
            notes: Notes.text ?? "No notes",
            portal: portal.selectedSegmentIndex == 0 ? "LMS" : "Classroom",
            due: dateValue.date,
            isDone: false  // always false on creation
        )
        
        titleValue.text = ""
        courseValue.text = ""
        Notes.text = ""
        
        saveWriteup(newWriteup)
        print("Saved to: \(getFileURL().path)")
        print("New writeup: \(newWriteup)")
        showAlert(title: "Success", message: "Writeup Added")
    }
}
