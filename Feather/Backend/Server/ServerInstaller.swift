//
//  Server.swift
//  feather
//
//  Created by samara on 22.08.2024.
//  Copyright © 2024 Lakr Aream. All Rights Reserved.
//  ORIGINALLY LICENSED UNDER GPL-3.0, MODIFIED FOR USE FOR FEATHER
//

import Foundation
import Vapor
import NIOSSL
import NIOTLS
import SwiftUI
import IDeviceSwift

// MARK: - Class
class ServerInstaller: Identifiable, ObservableObject {
	let id = UUID()
	let port = Int.random(in: 4000...8000)
	private var _needsShutdown = false
	
	var packageUrl: URL?
	var app: AppInfoPresentable
	@ObservedObject var viewModel: InstallerStatusViewModel
	private var _server: Application?

	private let logFile: URL = {
		let url = FileManager.default.temporaryDirectory.appendingPathComponent("feather_svpl.log")
		if !FileManager.default.fileExists(atPath: url.path) {
			FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
		}
		return url
	}()

	init(app: AppInfoPresentable, viewModel: InstallerStatusViewModel) throws {
		self.app = app
		self.viewModel = viewModel
		try _setup()
		try _configureRoutes()
		try _server?.server.start()
		_needsShutdown = true
	}
	
	deinit {
		_shutdownServer()
	}

	private func _setup() throws {
		self._server = try? setupApp(port: port)
	}
		
	private func _configureRoutes() throws {
		_server?.get("*") { [weak self] req in
			guard let self else { return Response(status: .badGateway) }
			switch req.url.path {
			case plistEndpoint.path:
				self._updateStatus(.sendingManifest)
				return Response(status: .ok, version: req.version, headers: [
					"Content-Type": "text/xml",
				], body: .init(data: installManifestData))
			case displayImageSmallEndpoint.path:
				return Response(status: .ok, version: req.version, headers: [
					"Content-Type": "image/png",
				], body: .init(data: displayImageSmallData))
			case displayImageLargeEndpoint.path:
				return Response(status: .ok, version: req.version, headers: [
					"Content-Type": "image/png",
				], body: .init(data: displayImageLargeData))
			case payloadEndpoint.path:
				guard let packageUrl = packageUrl else {
					return Response(status: .notFound)
				}
				
				self._updateStatus(.sendingPayload)
				
				let fileHandle: FileHandle
				do {
					fileHandle = try FileHandle(forReadingFrom: packageUrl)
				} catch {
					return Response(status: .internalServerError)
				}

				let totalBytes = try? FileManager.default.attributesOfItem(atPath: packageUrl.path)[.size] as? Int64 ?? 0
				let chunkSize: Int = 512 * 1024 // 512 KB per chunk so the server can handle it
				var bytesSent: Int64 = 0

				let bodyStream = BodyStream { writer in
					func sendNextChunk() {
						DispatchQueue.global(qos: .utility).async {
							do {
								let data = try fileHandle.read(upToCount: chunkSize) ?? Data()
								if data.isEmpty {
									try fileHandle.close()
									self._updateStatus(.completed(nil))
									let totalSize = Self.humanReadableSize(for: totalBytes ?? 0)
									let line = "Payload completed: \(totalSize)\n"
									if let dataLine = line.data(using: .utf8) {
										try? FileHandle(forWritingTo: self.logFile).seekToEnd()
										try? FileHandle(forWritingTo: self.logFile).write(contentsOf: dataLine)
									}
									writer.write(.end, promise: nil)
									return
								}

								bytesSent += Int64(data.count)
								writer.write(.buffer(ByteBuffer(data: data)), promise: nil)

								//log the chunks so i can see if theres any issues
								if let totalBytes, bytesSent % max(totalBytes/100, 1_048_576) < 4096 {
									let humanSent = Self.humanReadableSize(for: bytesSent)
									let humanTotal = Self.humanReadableSize(for: totalBytes)
									let line = String(format: "Sending Payload: %.2f%% (%@ / %@)\n", Double(bytesSent)/Double(totalBytes) * 100, humanSent, humanTotal)
									if let dataLine = line.data(using: .utf8) {
										try? FileHandle(forWritingTo: self.logFile).seekToEnd()
										try? FileHandle(forWritingTo: self.logFile).write(contentsOf: dataLine)
									}
								}

								sendNextChunk()
							} catch {
								try? fileHandle.close()
								self._updateStatus(.broken)
								writer.write(.end, promise: nil)
							}
						}
					}
					sendNextChunk()
				}

				return Response(status: .ok, version: req.version, headers: [
					"Content-Type": "application/octet-stream"
				], body: bodyStream)

			case "/install":
				var headers = HTTPHeaders()
				headers.add(name: .contentType, value: "text/html")
				return Response(status: .ok, headers: headers, body: .init(string: self.html))
			default:
				return Response(status: .notFound)
			}
		}
	}
	
	private func _shutdownServer() {
		guard _needsShutdown else { return }
		
		_needsShutdown = false
		_server?.server.shutdown()
		_server?.shutdown()
	}
	
	private func _updateStatus(_ newStatus: InstallerStatusViewModel.InstallerStatus) {
		DispatchQueue.main.async {
			self.viewModel.status = newStatus
		}
	}

	private static func humanReadableSize(for bytes: Int64) -> String {
		let gb = Double(bytes) / 1_073_741_824
		if gb >= 1 { return String(format: "%.2f GB", gb) }
		let mb = Double(bytes) / 1_048_576
		if mb >= 1 { return String(format: "%.2f MB", mb) }
		let kb = Double(bytes) / 1024
		return String(format: "%.2f KB", kb)
	}
		
	func getServerMethod() -> Int {
		UserDefaults.standard.integer(forKey: "Feather.serverMethod")
	}
	
	func getIPFix() -> Bool {
		UserDefaults.standard.bool(forKey: "Feather.ipFix")
	}
}
