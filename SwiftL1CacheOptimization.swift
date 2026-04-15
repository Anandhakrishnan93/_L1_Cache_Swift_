
import SwiftUI

// 1. A simple struct (Value Type) - Stored contiguously in memory (L1 Friendly)
struct Particle {
    var x: Float = 0.0
    var y: Float = 0.0
}

// 2. A simple class (Reference Type) - Stored as pointers (L1 Unfriendly)
class ParticleObject {
    var x: Float = 0.0
    var y: Float = 0.0
}

struct CacheBenchmarkView: View {
    @State private var structTime: Double = 0.0
    @State private var classTime: Double = 0.0
    @State private var isRunning = false
    
    let count = 1_000_000 // 1 Million elements
    
    var body: some View {
        VStack(spacing: 30) {
            Text("L1 Cache Performance")
                .font(.title).bold()
            
            VStack(alignment: .leading, spacing: 20) {
                ResultRow(title: "Contiguous (Structs)", time: structTime, color: .green)
                ResultRow(title: "Fragmented (Classes)", time: classTime, color: .red)
            }
            .padding()
            
            Button(action: runBenchmark) {
                Text(isRunning ? "Running..." : "Run Benchmark")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(isRunning)
            
            Text("Tip: Structs are packed tightly in memory, allowing the L1 cache to 'pre-fetch' the next item before the CPU even asks for it.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    func runBenchmark() {
        // 1. Instantly update the UI state to disable the button and show "Running..."
        isRunning = true
        
        // 2. Move execution to a concurrent background thread.
        // '.userInitiated' tells the iOS scheduler to ramp up the CPU clock speed
        // because the user is actively waiting for this result.
        DispatchQueue.global(qos: .userInitiated).async {
            
            // --- Benchmark Structs (L1 Friendly) ---
            
            // 3. Initialize a contiguous block of memory.
            // All 1,000,000 structs sit side-by-side in the 'Stack/Heap' buffer.
            var structArray = Array(repeating: Particle(), count: count)
            
            // 4. Capture the high-resolution system clock before the loop starts.
            let start1 = CFAbsoluteTimeGetCurrent()
            
            // 5. The "Cache Winner" loop: Because memory is contiguous, the L1 pre-fetcher
            // loads the next 64 bytes of the array before the CPU even reaches that index.
            for i in 0..<structArray.count {
                structArray[i].x += 1.0
            }
            
            // 6. Capture time after the loop to calculate the 'Struct' duration.
            let end1 = CFAbsoluteTimeGetCurrent()
            
            // --- Benchmark Classes (L1 Unfriendly) ---
            
            // 7. Create 1M class instances. Note: The array only holds 64-bit 'addresses' (pointers),
            // while the actual objects are scattered elsewhere in the Heap.
            let classArray = (0..<count).map { _ in ParticleObject() }
            
            // 8. Capture the start time for the second test.
            let start2 = CFAbsoluteTimeGetCurrent()
            
            // 9. The "Pointer Chaser" loop: For every 'i', the CPU must read an address,
            // jump to a new memory location, and wait for the L1 cache to be filled from RAM.
            for i in 0..<classArray.count {
                classArray[i].x += 1.0
            }
            
            // 10. Capture the end time for the class-based test.
            let end2 = CFAbsoluteTimeGetCurrent()
            
            // 11. Crucial: UI elements (like @State) can ONLY be modified on the Main Thread.
            // This 'dispatches' the result back to the UI queue.
            DispatchQueue.main.async {
                
                // 12. Convert seconds to milliseconds and update the bound SwiftUI variables.
                self.structTime = (end1 - start1) * 1000
                self.classTime = (end2 - start2) * 1000
                
                // 13. Re-enable the UI button for the next run.
                self.isRunning = false
            }
        }
    }
}

struct ResultRow: View {
    var title: String
    var time: Double
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .frame(height: 20)
                    .foregroundColor(Color.gray.opacity(0.2))
                
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: CGFloat(min(time, 300)), height: 20)
                    .foregroundColor(color)
            }
            Text(String(format: "%.2f ms", time))
                .font(.system(.caption, design: .monospaced))
        }
    }
}
