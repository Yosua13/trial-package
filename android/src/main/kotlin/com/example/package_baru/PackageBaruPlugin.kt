package com.example.package_baru

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream
import java.util.*

class PackageBaruPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private var bluetoothSocket: BluetoothSocket? = null

    private val UUID_PRINTER = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "package_baru")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "scanBluetoothDevices" -> scanBluetoothDevices(result)
            "connectBluetoothPrinter" -> {
                val address = call.argument<String>("address")
                if (address != null) {
                    connectBluetoothPrinter(address, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Printer address is missing", null)
                }
            }
            "printReceipt" -> {
                val data = call.argument<String>("data")
                if (data != null) {
                    printReceipt(data, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Receipt data is missing", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun scanBluetoothDevices(result: MethodChannel.Result) {
        val devices = mutableListOf<String>()
        bluetoothAdapter?.bondedDevices?.forEach { device ->
            devices.add("${device.name} - ${device.address}")
        }
        result.success(devices)
    }

    private fun connectBluetoothPrinter(address: String, result: MethodChannel.Result) {
        try {
            val device = bluetoothAdapter?.getRemoteDevice(address)
            bluetoothSocket = device?.createRfcommSocketToServiceRecord(UUID_PRINTER)
            bluetoothSocket?.connect()
            result.success("Connected to printer: ${device?.name}")
        } catch (e: Exception) {
            e.printStackTrace()
            result.error("CONNECTION_ERROR", "Failed to connect to printer: ${e.message}", null)
        }
    }

    private fun printReceipt(data: String, result: MethodChannel.Result) {
        try {
            val outputStream: OutputStream? = bluetoothSocket?.outputStream
            outputStream?.write(data.toByteArray(Charsets.US_ASCII))
            outputStream?.write("\n\n".toByteArray(Charsets.US_ASCII)) // Tambahkan baris kosong
            outputStream?.flush()
            result.success("Receipt printed successfully")
        } catch (e: Exception) {
            e.printStackTrace()
            result.error("PRINT_ERROR", "Failed to print receipt: ${e.message}", null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
