import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var timer: Timer?
    private var eventMonitor: Any?
    private let apiService = MiniMaxAPIService()
    private let usageHistoryService = UsageHistoryService()

    private var usageData: ModelRemain?
    private var lastUpdateTime: Date?
    private var apiStatus: APIStatus = .unknown

    enum APIStatus {
        case unknown
        case success
        case error(String)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        startPolling()

        if apiService.getAPIKey() == nil {
            showSettings()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: 70)

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            updateStatusItemView(percentage: 0, isPlaceholder: true)
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 450)
        popover.behavior = .transient
        popover.animates = true
    }

    private func updateStatusItemView(percentage: Int, isPlaceholder: Bool = false) {
        guard let button = statusItem.button else { return }

        let view = NSHostingView(rootView: StatusItemView(
            percentage: percentage,
            isPlaceholder: isPlaceholder
        ))
        view.frame = NSRect(x: 0, y: 0, width: 70, height: 22)
        button.addSubview(view)
        view.autoresizingMask = [.width, .height]
    }

    private func updateStatusItem(percentage: Double) {
        guard let button = statusItem.button else { return }

        button.subviews.forEach { $0.removeFromSuperview() }

        let view = NSHostingView(rootView: StatusItemView(
            percentage: Int(percentage * 100),
            isPlaceholder: false
        ))
        view.frame = NSRect(x: 0, y: 0, width: 70, height: 22)
        button.addSubview(view)
        view.autoresizingMask = [.width, .height]
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        if let button = statusItem.button {
            refreshData()
            updatePopoverContent()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            startEventMonitor()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        stopEventMonitor()
    }

    private func startEventMonitor() {
        stopEventMonitor()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if self?.popover.isShown == true {
                self?.closePopover()
            }
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func showSettings() {
        popover.contentViewController = NSHostingController(rootView: SettingsView(
            onSave: { [weak self] in
                self?.closePopover()
                self?.refreshData()
            }
        ))
        popover.show(relativeTo: statusItem.button!.bounds, of: statusItem.button!, preferredEdge: .minY)
        startEventMonitor()
    }

    private func updatePopoverContent() {
        let contentView = PopoverContentView(
            usageData: usageData,
            apiStatus: apiStatus,
            lastUpdateTime: lastUpdateTime,
            onRefresh: { [weak self] in
                self?.refreshData()
            },
            onOpenSettings: { [weak self] in
                self?.showSettings()
            },
            onQuit: {
                NSApplication.shared.terminate(nil)
            },
            usageHistoryService: usageHistoryService
        )
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 280, height: 450)
        popover.contentViewController = hostingController
    }

    private func startPolling() {
        refreshData()

        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refreshData()
        }
    }

    private func refreshData() {
        guard let apiKey = apiService.getAPIKey() else {
            apiStatus = .error("未设置 API Key")
            updatePopoverContent()
            return
        }

        apiService.fetchUsage(apiKey: apiKey) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.usageData = response.modelRemains.first { $0.modelName == "MiniMax-M*" }
                    self?.apiStatus = .success
                    self?.lastUpdateTime = Date()

                    if let data = self?.usageData {
                        // Update usage history
                        self?.usageHistoryService.setWindow(startTime: data.startTime, endTime: data.endTime)
                        self?.usageHistoryService.addSample(remainingCount: data.remainingCount)

                        let total = Double(data.currentIntervalTotalCount)
                        let used = Double(data.currentIntervalTotalCount - data.currentIntervalRemainUsageCount)
                        let percentage = total > 0 ? used / total : 0
                        self?.updateStatusItem(percentage: percentage)
                    }

                case .failure(let error):
                    self?.apiStatus = .error(error.localizedDescription)
                    self?.updateStatusItem(percentage: 0)
                }

                self?.updatePopoverContent()
            }
        }
    }
}
