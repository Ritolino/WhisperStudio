import Foundation
import Darwin

enum MemoryPressureLevel: Equatable, Sendable {
    case normal
    case warning
    case critical
}

struct SystemMemorySnapshot: Equatable, Sendable {
    let totalGB: Double
    let usedSystemGB: Double
    let pressure: MemoryPressureLevel
}

enum SystemMemoryService {
    static var isSupportedEnvironment: Bool {
        #if arch(arm64)
        let ver = ProcessInfo.processInfo.operatingSystemVersion
        return ver.majorVersion >= 26
        #else
        return false
        #endif
    }

    static func totalPhysicalRAMGB() -> Double {
        Double(ProcessInfo.processInfo.physicalMemory) / Double(1024 * 1024 * 1024)
    }

    static func currentSnapshot() -> SystemMemorySnapshot {
        let totalBytes = Double(ProcessInfo.processInfo.physicalMemory)
        let totalGB = totalBytes / Double(1024 * 1024 * 1024)
        var usedGB = 0.0

        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        var vmPageSize: vm_size_t = 0
        let hostPort = mach_host_self()
        host_page_size(hostPort, &vmPageSize)
        let result = withUnsafeMutablePointer(to: &vmStats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(hostPort, HOST_VM_INFO64, intPtr, &count)
            }
        }
        mach_port_deallocate(mach_task_self_, hostPort)

        if result == KERN_SUCCESS {
            let pageSize = vmPageSize > 0 ? Double(vmPageSize) : Double(getpagesize())
            let internalPages = vmStats.internal_page_count
            let purgeablePages = vmStats.purgeable_count
            let appPages = internalPages > purgeablePages ? (internalPages - purgeablePages) : 0
            let usedPages = appPages + vmStats.wire_count + vmStats.compressor_page_count
            usedGB = (Double(usedPages) * pageSize) / Double(1024 * 1024 * 1024)
        }

        let pressure = readMemoryPressure()
        return SystemMemorySnapshot(
            totalGB: (totalGB * 10).rounded() / 10,
            usedSystemGB: (usedGB * 10).rounded() / 10,
            pressure: pressure
        )
    }

    private static func readMemoryPressure() -> MemoryPressureLevel {
        var level: Int32 = 100
        var size = MemoryLayout<Int32>.size
        if sysctlbyname("kern.memorystatus_level", &level, &size, nil, 0) == 0 {
            if level <= 15 { return .critical }
            if level <= 30 { return .warning }
            return .normal
        }
        return .normal
    }
}
