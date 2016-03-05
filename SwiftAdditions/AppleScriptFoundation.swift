//
//  AppleScriptFoundation.swift
//  SwiftAdditions
//
//  Created by C.W. Betts on 2/4/16.
//  Copyright © 2016 C.W. Betts. All rights reserved.
//

import Foundation

#if os(OSX)
private func getErrorFromDict(dict: NSDictionary?) -> NSError {
	if var dict = dict as? [NSObject : AnyObject] {
		let errNum = dict[NSAppleScriptErrorNumber] as? Int ?? errOSAScriptError
		
		dict[NSLocalizedFailureReasonErrorKey] = dict[NSAppleScriptErrorMessage]
		dict[NSLocalizedDescriptionKey] = dict[NSAppleScriptErrorBriefMessage]
		return NSError(domain: NSOSStatusErrorDomain, code: errNum, userInfo: dict)
	} else {
		return NSError(domain: NSOSStatusErrorDomain, code: errOSAScriptError, userInfo: nil)
	}
}

	extension NSAppleScript {
		//@nonobjc public convenience init(contentsOfURL url: NSURL) throws {
		//	var errDict: NSDictionary?
		//	if let hi = self.init(contentsOfURL: url, error: &errDict) {
		//
		//	}
		//}
		
		/// Compile the script, if it is not already compiled.  Throws if unsuccessful.
		@nonobjc public func compile() throws {
			var errDict: NSDictionary?
			if !compileAndReturnError(&errDict) {
				throw getErrorFromDict(errDict)
			}
		}
		
		/// Execute the script, compiling it first if it is not already compiled.  Return the result of executing the script, or throws for failure.
		@nonobjc public func execute() throws -> NSAppleEventDescriptor {
			var errDict: NSDictionary?
			if let descriptor = executeAndReturnError(&errDict) as NSAppleEventDescriptor? {
				return descriptor
			} else {
				throw getErrorFromDict(errDict)
			}
		}
		
		/// Execute an Apple event in the context of the script, compiling the script first if it is not already compiled.  Return the result of executing the event, or throws an `NSError`.
		@nonobjc public func executeAppleEvent(event: NSAppleEventDescriptor) throws -> NSAppleEventDescriptor {
			var errDict: NSDictionary?
			if let descriptor = executeAppleEvent(event, error: &errDict) as NSAppleEventDescriptor? {
				return descriptor
			} else {
				throw getErrorFromDict(errDict)
			}
		}
	}
#endif
