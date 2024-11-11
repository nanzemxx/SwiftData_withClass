import SwiftUI
import SwiftData

// 1. First create a manager class
class ItemManager: ObservableObject {
    @Published var items: [Item] = []
    @Published var error: Error? = nil
    
    var modelContext: ModelContext? = nil
    var modelContainer: ModelContainer? = nil
    
    enum ItemError: Error {
        case nilContext
    }
    
    // 2. Initialize with model container
    @MainActor
    init(inMemory: Bool) {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
            let container = try ModelContainer(for: Item.self, configurations: configuration)
            modelContainer = container
            modelContext = container.mainContext
            modelContext?.autosaveEnabled = true
            
            // Initial data load
            queryItems()
        } catch(let error) {
            print(error)
            self.error = error
        }
    }
    
    // 3. Query method
    private func queryItems() {
        guard let modelContext = modelContext else {
            self.error = ItemError.nilContext
            
            return
        }
        
        let descriptor = FetchDescriptor<Item>(
            sortBy: [.init(\.timestamp, order: .reverse)]
        )
        
        do {
            items = try modelContext.fetch(descriptor)
        } catch(let error) {
            self.error = error
        }
    }
    
    // 4. Add item method
    func addItem() {
        guard let modelContext = modelContext else {
            self.error = ItemError.nilContext
            return
        }
        
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
            save()
            queryItems()
        }
    }
    
    // 5. Delete items method
    func deleteItems(offsets: IndexSet) {
        guard let modelContext = modelContext else {
            self.error = ItemError.nilContext
            return
        }
        
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
            save()
            queryItems()
        }
    }
    
    // 6. Save method
    private func save() {
        guard let modelContext = modelContext else {
            self.error = ItemError.nilContext
            return
        }
        
        do {
            try modelContext.save()
        } catch(let error) {
            print(error)
            self.error = error
        }
    }
}

// 7. Updated ContentView using ItemManager
struct ContentView: View {
    @StateObject private var itemManager: ItemManager
    
    init(inMemory: Bool = false) {
        _itemManager = StateObject(wrappedValue: ItemManager(inMemory: inMemory))
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(itemManager.items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: itemManager.deleteItems)
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: itemManager.addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
}

// 8. Updated preview
#Preview {
    ContentView(inMemory: true)
}
