import UIKit

class ManageWriteupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    struct AppTheme {
        static let lightRed = UIColor(hex: "#FDEDEE")   // Soft blush background (very light red/pink)
        static let coral = UIColor(hex: "#F7B7A3")   // Muted coral cell background
        static let brickRed = UIColor(hex: "#D94F4F")    // Deep brick red header or title accent
        static let warm = UIColor(hex: "#FF6F59")        // Warm coral text for course names
        static let red = UIColor(hex: "#E94F37")      // Vibrant tomato red for due date text
    }


    struct Writeup: Codable {
        let title: String
        let course: String
        let notes: String
        let portal: String
        let due: Date
        var isDone: Bool
        
        enum CodingKeys: String, CodingKey {
            case title, course, notes, portal, due, isDone
        }
    }
    
    
    @IBOutlet weak var emptyMessageLabel: UILabel!
    
    var writeups: [Writeup] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.lightRed
        tableView.backgroundColor = AppTheme.lightRed
        tableView.separatorColor = AppTheme.coral

        tableView.dataSource = self
        tableView.delegate = self
        //clearWriteupsJSON()
        loadAndFilterWriteups()
        printJSONFileContents()
        tableView.reloadData()
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
            print("Error loading writeups in ManageWriteupViewController: \(error)")
            return []
        }
    }
    
    func saveAllWriteups(_ writeups: [Writeup]) {
        let url = getFileURL()
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(writeups)
            try data.write(to: url)
            print("Writeups saved successfully")
        } catch {
            print("Failed to save writeups: \(error)")
        }
    }
    
    func loadAndFilterWriteups() {
        let allWriteups = loadWriteups()
        print("Loaded writeups: \(allWriteups)")
        printJSONFileContents()
        print("File URL: \(getFileURL())")
        
        // Show only pending writeups (isDone == false)
        writeups = allWriteups.filter { !$0.isDone }
        
        if writeups.isEmpty {
                emptyMessageLabel.isHidden = false
                tableView.isHidden = true
                emptyMessageLabel.textColor = AppTheme.brickRed
            } else {
                emptyMessageLabel.isHidden = true
                tableView.isHidden = false
            }
    }
    
    func printJSONFileContents() {
        let url = getFileURL()
        do {
            let data = try Data(contentsOf: url)
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let jsonString = String(data: prettyData, encoding: .utf8) {
                print("JSON file content:\n\(jsonString)")
            } else if let jsonString = String(data: data, encoding: .utf8) {
                print("JSON file content (unformatted):\n\(jsonString)")
            } else {
                print("Unable to convert data to string.")
            }
        } catch {
            print("Failed to read JSON file: \(error)")
        }
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return writeups.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        

        let writeup = writeups[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "WriteupCell", for: indexPath)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        cell.backgroundColor = .white
        cell.textLabel?.textColor = AppTheme.warm
        cell.detailTextLabel?.textColor = AppTheme.coral
        cell.textLabel?.text = writeup.title
        cell.detailTextLabel?.numberOfLines = 2
        cell.detailTextLabel?.text = "\(writeup.course)\nDue: \(formatter.string(from: writeup.due))"
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let writeup = writeups[indexPath.row]
        
        let alert = UIAlertController(title: writeup.title,
                                      message: writeup.notes.isEmpty ? "(No notes available)" : writeup.notes,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.view.tintColor = AppTheme.red
        present(alert, animated: true)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Swipe action to mark done
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let markDoneAction = UIContextualAction(style: .normal, title: "Mark Done") { [weak self] (_, _, completionHandler) in
            
            guard let self = self else { return }
            
            
            // Load all writeups (including done and pending)
            var allWriteups = self.loadWriteups()
            
            let writeupToMark = self.writeups[indexPath.row]
            
            if let indexInAll = allWriteups.firstIndex(where: {
                $0.title == writeupToMark.title &&
                $0.course == writeupToMark.course &&
                $0.due == writeupToMark.due
            }) {
                allWriteups[indexInAll].isDone = true
                
                // Save updated array
                self.saveAllWriteups(allWriteups)
                
                // Reload pending writeups and refresh table
                self.loadAndFilterWriteups()
                self.tableView.reloadData()
                
                // Debug print
                self.printJSONFileContents()
            }
            
            completionHandler(true)
        }
        
        markDoneAction.backgroundColor = AppTheme.red
        
        return UISwipeActionsConfiguration(actions: [markDoneAction])
    }
    
    // Optional: Clear JSON file method (for testing)
    func clearWriteupsJSON() {
        let url = getFileURL()
        do {
            let emptyWriteups: [Writeup] = []
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(emptyWriteups)
            try data.write(to: url)
            print("Cleared writeups.json file.")
        } catch {
            print("Failed to clear JSON file: \(error)")
        }
    }
    
    @IBAction func refresh(_ sender: Any) {
        loadAndFilterWriteups()
        tableView.reloadData()
    }
}
