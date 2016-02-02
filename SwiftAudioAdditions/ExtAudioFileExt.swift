//
//  ExtAudioFileExt.swift
//  SwiftAdditions
//
//  Created by C.W. Betts on 4/18/15.
//  Copyright (c) 2015 C.W. Betts. All rights reserved.
//

import Foundation
import AudioToolbox
import SwiftAdditions

public func ExtAudioFileCreate(URL inURL: NSURL, fileType inFileType: AudioFileType, inout streamDescription inStreamDesc: AudioStreamBasicDescription, channelLayout inChannelLayout: UnsafePointer<AudioChannelLayout> = nil, flags: AudioFileFlags = AudioFileFlags(rawValue: 0), inout audioFile outAudioFile: ExtAudioFileRef) -> OSStatus {
	return ExtAudioFileCreateWithURL(inURL, inFileType.rawValue, &inStreamDesc, inChannelLayout, flags.rawValue, &outAudioFile)
}

public func ExtAudioFileSetProperty(inExtAudioFile: ExtAudioFileRef, propertyID inPropertyID: ExtAudioFilePropertyID, dataSize propertyDataSize: UInt32, data propertyData: UnsafePointer<Void>) -> OSStatus {
	return ExtAudioFileSetProperty(inExtAudioFile, inPropertyID, propertyDataSize, propertyData)
}

public func ExtAudioFileSetProperty(inExtAudioFile: ExtAudioFileRef, propertyID inPropertyID: ExtAudioFilePropertyID, dataSize propertyDataSize: Int, data propertyData: UnsafePointer<Void>) -> OSStatus {
	return ExtAudioFileSetProperty(inExtAudioFile, inPropertyID, UInt32(propertyDataSize), propertyData)
}

public func ExtAudioFileGetPropertyInfo(inExtAudioFile: ExtAudioFileRef, propertyID inPropertyID: ExtAudioFilePropertyID, inout size outSize: Int, inout writable outWritable: Bool) -> OSStatus {
	var ouSize = UInt32(outSize)
	var ouWritable: DarwinBoolean = false
	let aRet = ExtAudioFileGetPropertyInfo(inExtAudioFile, inPropertyID, &ouSize, &ouWritable)
	outWritable = ouWritable.boolValue
	outSize = Int(ouSize)
	return aRet
}

public func ExtAudioFileGetPropertyInfo(inExtAudioFile: ExtAudioFileRef, propertyID inPropertyID: ExtAudioFilePropertyID, inout size outSize: UInt32, inout writable outWritable: Bool) -> OSStatus {
	var ouWritable: DarwinBoolean = false
	let aRet = ExtAudioFileGetPropertyInfo(inExtAudioFile, inPropertyID, &outSize, &ouWritable)
	outWritable = ouWritable.boolValue
	return aRet
}

public func ExtAudioFileGetProperty(inExtAudioFile: ExtAudioFileRef, propertyID inPropertyID: ExtAudioFilePropertyID, inout propertyDataSize ioPropertyDataSize: UInt32, propertyData outPropertyData: UnsafeMutablePointer<Void>) -> OSStatus {
	return ExtAudioFileGetProperty(inExtAudioFile, inPropertyID, &ioPropertyDataSize, outPropertyData)
}

final public class ExtAudioFile {
	var internalPtr: ExtAudioFileRef = nil
	
	public init(openURL: NSURL) throws {
		let iErr = ExtAudioFileOpenURL(openURL, &internalPtr)
		
		if iErr != noErr {
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(iErr), userInfo: nil)
		}
	}
	
	public init(createURL inURL: NSURL, fileType inFileType: AudioFileType, inout streamDescription inStreamDesc: AudioStreamBasicDescription, channelLayout inChannelLayout: UnsafePointer<AudioChannelLayout> = nil, flags: AudioFileFlags = AudioFileFlags(rawValue: 0)) throws {
		let iErr = ExtAudioFileCreate(URL: inURL, fileType: inFileType, streamDescription: &inStreamDesc, channelLayout: inChannelLayout, flags: flags, audioFile: &internalPtr)
		
		if iErr != noErr {
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(iErr), userInfo: nil)
		}
	}
	
	public func write(frames: UInt32, data: UnsafePointer<AudioBufferList>) throws {
		let iErr = ExtAudioFileWrite(internalPtr, frames, data)
		
		if iErr != noErr {
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(iErr), userInfo: nil)
		}
	}
	
	/// N.B. Errors may occur after this call has returned. Such errors may be thrown
	/// from subsequent calls to this method.
	public func writeAsync(frames: UInt32, data: UnsafePointer<AudioBufferList>) throws {
		let iErr = ExtAudioFileWriteAsync(internalPtr, frames, data)
		
		if iErr != noErr {
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(iErr), userInfo: nil)
		}
	}
	
	deinit {
		if internalPtr != nil {
			ExtAudioFileDispose(internalPtr)
		}
	}
	
	public func getPropertyInfo(ID: ExtAudioFilePropertyID) throws -> (size: UInt32, writeable: Bool) {
		var outSize: UInt32 = 0
		var outWritable: DarwinBoolean = false
		
		let iErr = ExtAudioFileGetPropertyInfo(internalPtr, ID, &outSize, &outWritable)
		
		if iErr != noErr {
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(iErr), userInfo: nil)
		}
		
		return (outSize, outWritable.boolValue)
	}
	
	public func getProperty(ID: ExtAudioFilePropertyID, inout dataSize: UInt32, data: UnsafeMutablePointer<Void>) throws {
		let iErr = ExtAudioFileGetProperty(internalPtr, ID, &dataSize, data)
		
		if iErr != noErr {
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(iErr), userInfo: nil)
		}
	}
	
	public func setProperty(ID: ExtAudioFilePropertyID, dataSize: UInt32, data: UnsafePointer<Void>) throws {
		let iErr = ExtAudioFileSetProperty(internalPtr, ID, dataSize, data)
		
		if iErr != noErr {
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(iErr), userInfo: nil)
		}
	}
	
	public var fileDataFormat: AudioStreamBasicDescription {
		get {
			var toRet = AudioStreamBasicDescription()
			var (size, _) = try! getPropertyInfo(kExtAudioFileProperty_FileDataFormat)
			try! getProperty(kExtAudioFileProperty_FileDataFormat, dataSize: &size, data: &toRet)
			return toRet
		}
	}
	
	public var fileChannelLayout: AudioChannelLayout {
		get {
			var toRet = AudioChannelLayout()
			var (size, _) = try! getPropertyInfo(kExtAudioFileProperty_FileChannelLayout)
			try! getProperty(kExtAudioFileProperty_FileChannelLayout, dataSize: &size, data: &toRet)
			return toRet
		}
		/*
		TODO: add throwable setter
		set throws {
		var newVal = newValue
		let (size, writable) = try! getPropertyInfo(kExtAudioFileProperty_ClientDataFormat)
		if !writable {
		//paramErr
		//throw NSError(domain: NSOSStatusErrorDomain, code: -50, userInfo: nil)
		fatalError(NSError(domain: NSOSStatusErrorDomain, code: -50, userInfo: nil).description)
		}
		try! setProperty(kExtAudioFileProperty_ClientDataFormat, dataSize: size, data: &newVal)
		}*/
	}
	
	public var clientDataFormat: AudioStreamBasicDescription {
		get {
			var toRet = AudioStreamBasicDescription()
			var (size, _) = try! getPropertyInfo(kExtAudioFileProperty_ClientDataFormat)
			try! getProperty(kExtAudioFileProperty_ClientDataFormat, dataSize: &size, data: &toRet)
			return toRet
		}
		//TODO: add throwable setter
		set {
			var newVal = newValue
			let (size, writable) = try! getPropertyInfo(kExtAudioFileProperty_ClientDataFormat)
			if !writable {
				//paramErr
				//throw NSError(domain: NSOSStatusErrorDomain, code: -50, userInfo: nil)
				fatalError(NSError(domain: NSOSStatusErrorDomain, code: -50, userInfo: nil).description)
			}
			try! setProperty(kExtAudioFileProperty_ClientDataFormat, dataSize: size, data: &newVal)
		}
	}
	
	public var clientChannelLayout: AudioChannelLayout {
		get {
			var toRet = AudioChannelLayout()
			var (size, _) = try! getPropertyInfo(kExtAudioFileProperty_ClientChannelLayout)
			try! getProperty(kExtAudioFileProperty_ClientChannelLayout, dataSize: &size, data: &toRet)
			return toRet
		}
		/*
		TODO: add throwable setter
		set throws {
		var newVal = newValue
		let (size, writable) = try! getPropertyInfo(kExtAudioFileProperty_ClientDataFormat)
		if !writable {
		//paramErr
		//throw NSError(domain: NSOSStatusErrorDomain, code: -50, userInfo: nil)
		fatalError(NSError(domain: NSOSStatusErrorDomain, code: -50, userInfo: nil).description)
		}
		try! setProperty(kExtAudioFileProperty_ClientDataFormat, dataSize: size, data: &newVal)
		}*/
	}
	
	public var codecManufacturer: UInt32 {
		get {
			var toRet: UInt32 = 0
			var (size, _) = try! getPropertyInfo(kExtAudioFileProperty_CodecManufacturer)
			try! getProperty(kExtAudioFileProperty_CodecManufacturer, dataSize: &size, data: &toRet)
			return toRet
		}
		/*
		TODO: add throwable setter
		set throws {
		var newVal = newValue
		let (size, writable) = try! getPropertyInfo(kExtAudioFileProperty_ClientDataFormat)
		if !writable {
		//paramErr
		//throw NSError(domain: NSOSStatusErrorDomain, code: -50, userInfo: nil)
		fatalError(NSError(domain: NSOSStatusErrorDomain, code: -50, userInfo: nil).description)
		}
		try! setProperty(kExtAudioFileProperty_ClientDataFormat, dataSize: size, data: &newVal)
		}*/
	}
	
	// MARK: read-only
	
	public var audioConverter: AudioConverterRef {
		var toRet: AudioConverterRef = nil
		var (size, _) = try! getPropertyInfo(kExtAudioFileProperty_AudioConverter)
		try! getProperty(kExtAudioFileProperty_AudioConverter, dataSize: &size, data: &toRet)
		return toRet
	}
	
	public var audioFile: AudioFileID {
		var toRet: AudioFileID = nil
		var (size, _) = try! getPropertyInfo(kExtAudioFileProperty_AudioFile)
		try! getProperty(kExtAudioFileProperty_AudioFile, dataSize: &size, data: &toRet)
		return toRet
	}
	
	public var fileMaxPacketSize: UInt32 {
		var toRet: UInt32 = 0
		var (size, _) = try! getPropertyInfo(kExtAudioFileProperty_FileMaxPacketSize)
		try! getProperty(kExtAudioFileProperty_FileMaxPacketSize, dataSize: &size, data: &toRet)
		return toRet
	}

	public var clientMaxPacketSize: UInt32 {
		var toRet: UInt32 = 0
		var (size, _) = try! getPropertyInfo(kExtAudioFileProperty_ClientMaxPacketSize)
		try! getProperty(kExtAudioFileProperty_ClientMaxPacketSize, dataSize: &size, data: &toRet)
		return toRet
	}
	
	public var fileLengthFrames: Int64 {
		var toRet: Int64 = 0
		var (size, _) = try! getPropertyInfo(kExtAudioFileProperty_FileLengthFrames)
		try! getProperty(kExtAudioFileProperty_FileLengthFrames, dataSize: &size, data: &toRet)
		return toRet
	}
	
	//MARK: writable
	
	public func setConverterConfig(newVal: CFPropertyListRef?) throws {
		var cOpaque = COpaquePointer()
		if let newVal = newVal {
			cOpaque = Unmanaged.passUnretained(newVal).toOpaque()
		}
			let (size, writable) = try getPropertyInfo(kExtAudioFileProperty_ConverterConfig)
			if !writable {
				//paramErr
				throw NSError(domain: NSOSStatusErrorDomain, code: -50, userInfo: nil)
			}
			try setProperty(kExtAudioFileProperty_ConverterConfig, dataSize: size, data: &cOpaque)
	}
	
	public func setIOBufferSize(var bytes bytes: UInt32) throws {
		let (size, writable) = try getPropertyInfo(kExtAudioFileProperty_IOBufferSizeBytes)
		if !writable {
			//paramErr
			throw NSError(domain: NSOSStatusErrorDomain, code: -50, userInfo: nil)
		}
		try setProperty(kExtAudioFileProperty_IOBufferSizeBytes, dataSize: size, data: &bytes)
	}

	public func setIOBuffer(newVal: UnsafeMutablePointer<Void>) throws {
		let (size, writable) = try getPropertyInfo(kExtAudioFileProperty_IOBuffer)
		if !writable {
			//paramErr
			throw NSError(domain: NSOSStatusErrorDomain, code: -50, userInfo: nil)
		}
		try setProperty(kExtAudioFileProperty_IOBuffer, dataSize: size, data: newVal)
	}
	
	public func setPacketTable(var newVal: AudioFilePacketTableInfo) throws {
		let (size, writable) = try getPropertyInfo(kExtAudioFileProperty_PacketTable)
		if !writable {
			//paramErr
			throw NSError(domain: NSOSStatusErrorDomain, code: -50, userInfo: nil)
		}
		try setProperty(kExtAudioFileProperty_PacketTable, dataSize: size, data: &newVal)
	}
}
