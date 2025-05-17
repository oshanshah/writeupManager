import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    struct Writeup: Codable {
        let title: String
        let course: String
        let notes: String
        let portal: String
        let due: Date
        var isDone: Bool
    }
    struct AppTheme {
        static let lightRed = UIColor(hex: "#FDEDEE")   // Soft blush background (very light red/pink)
        static let coral = UIColor(hex: "#F7B7A3")   // Muted coral cell background
        static let brickRed = UIColor(hex: "#D94F4F")    // Deep brick red header or title accent
        static let warm = UIColor(hex: "#FF6F59")        // Warm coral text for course names
        static let red = UIColor(hex: "#E94F37")      // Vibrant tomato red for due date text
    }

    
    @IBOutlet weak var tableView: UITableView!
    
    var completed: [Writeup] = []
    var missing: [Writeup] = []
    var upcoming: [Writeup] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        loadAndClassifyWriteups()
        view.backgroundColor = AppTheme.lightRed
        tableView.backgroundColor = AppTheme.lightRed
        tableView.separatorColor = AppTheme.brickRed

    }

    func getFileURL() -> URL {
        let manager = FileManager.default
        let urls = manager.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("writeups.json")
    }

    func loadAndClassifyWriteups() {
        let url = getFileURL()
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let writeups = try decoder.decode([Writeup].self, from: data)
            
            let now = Date()
            completed = writeups.filter { $0.isDone }
            missing = writeups.filter { !$0.isDone && $0.due < now }
            upcoming = writeups.filter { !$0.isDone && $0.due >= now }

            tableView.reloadData()
        } catch {
            print("Error loading or decoding writeups: \(error)")
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return " Completed"
        case 1: return " Missing"
        case 2: return " Upcoming"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return completed.count
        case 1: return missing.count
        case 2: return upcoming.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let writeup: Writeup
        switch indexPath.section {
        case 0: writeup = completed[indexPath.row]
        case 1: writeup = missing[indexPath.row]
        case 2: writeup = upcoming[indexPath.row]
        default: fatalError("Invalid section")
            
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "AssignmentCell", for: indexPath)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        cell.backgroundColor = .white
        cell.textLabel?.textColor = AppTheme.brickRed
        cell.detailTextLabel?.textColor = AppTheme.coral

        cell.textLabel?.text = writeup.title
        cell.detailTextLabel?.text = "\(writeup.course) • Due: \(formatter.string(from: writeup.due))"

        return cell
    }

    @IBAction func refresh(_ sender: Any) {
        loadAndClassifyWriteups()
    }
}
