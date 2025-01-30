import Flutter
import UIKit
import CoreBluetooth

public class SwiftPackageBaruPlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager?
    private var foundDevices: [String] = []
    private var flutterResult: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "package_baru", binaryMessenger: registrar.messenger())
        let instance = SwiftPackageBaruPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "scanBluetoothDevices" {
            self.flutterResult = result
            startScanning()
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    private func startScanning() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager?.scanForPeripherals(withServices: nil)
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            flutterResult?(FlutterError(code: "BLUETOOTH_OFF", message: "Bluetooth is not enabled", details: nil))
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name {
            foundDevices.append("\(name) - \(peripheral.identifier.uuidString)")
        }
    }

    public func centralManager(_ central: CBCentralManager, didStopScan peripherals: [CBPeripheral]) {
        flutterResult?(foundDevices)
    }
}
