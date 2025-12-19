//
//  NetworkMonitor.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation
import Network
import Combine

final class NetworkMonitor: ObservableObject {
    @Published private(set) var isOnline: Bool = true
    @Published private(set) var interface: NWInterface.InterfaceType? = nil
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                self?.interface = path.availableInterfaces.first { path.usesInterfaceType($0.type) }?.type
                print("[Network] status=\(path.status == .satisfied ? "online" : "offline"), expensive=\(path.isExpensive), constrained=\(path.isConstrained)")
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
