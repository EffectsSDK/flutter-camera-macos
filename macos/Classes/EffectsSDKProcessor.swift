//
//  EffectsSDKProcessor.swift
//  camera_macos
//
//  Created by vasily on 22.05.2023.
//

import Foundation
import CoreVideo

public class EffectsSDKProcessor {
    private var blurOn_: Bool = false
    private var beautificationOn_: Bool = false
    private var backgroundOn_: Bool = false
    
    private var width_: UInt32 = 0
    private var height_: UInt32 = 0
    
    private var blurPower_: Float = -1.0
    private var beautificationLevel_: Float = -1.0
    
    private var TSVBFactory_: TSVBSDKFactory?
    
    private var frameFactory_: TSVBFrameFactory?
    private var replacementController_: AutoreleasingUnsafeMutablePointer<TSVBReplacementController?>?
    private var pipeline_: TSVBPipeline?
    
    private var piplineError_: UnsafeMutablePointer<TSVBPipelineError>?
    
    private var surface_: IOSurfaceRef?
    private var outBuffer_: Unmanaged<CVPixelBuffer>?
    
    init(_ width: Int32, _ height: Int32) {
        self.width_ = UInt32(width)
        self.height_ = UInt32(height)
        
        self.TSVBFactory_ = TSVBSDKFactory()
        self.frameFactory_ = self.TSVBFactory_?.newFrameFactory()
        self.pipeline_ = self.TSVBFactory_?.newPipeline()
        
        let attributesSurface: [NSString: Any] = [
            kIOSurfaceWidth: width_,
            kIOSurfaceHeight: height_,
            kIOSurfaceBytesPerElement: 4, // Assuming 32-bit RGBA
            kIOSurfaceBytesPerRow: width_ * 4,
            kIOSurfaceAllocSize: width_ * height_ * 4,
            kIOSurfacePixelFormat: kCVPixelFormatType_32BGRA
        ]
        
        surface_ = IOSurfaceCreate(attributesSurface as CFDictionary)
                
        let attributesPixelBuffer: [String: Any] = [
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        CVPixelBufferCreateWithIOSurface(kCFAllocatorDefault,
                                                      surface_!,
                                                      attributesPixelBuffer as CFDictionary,
                                                      &outBuffer_)
                
        self.piplineError_ = UnsafeMutablePointer<TSVBPipelineError>.allocate(capacity: 8)
    }
    
    public func AnyEffectActive() -> Bool {
        return blurOn_ || beautificationOn_ || backgroundOn_
    }
    
    public func SetBlur(blurPower: Float) {
        if pipeline_ != nil && !blurOn_ {
            blurPower_ = blurPower
            pipeline_?.enableBlurBackground(withPower: blurPower_)
            blurOn_ = true
        }
    }
    
    public func ClearBlur() {
        if pipeline_ != nil && blurOn_ {
            blurOn_ = false
            
            pipeline_?.disableBlurBackground()
            blurPower_ = -1.0
        }
    }
    
    public func SetBeautification(beautificationLevel: Float) {
        if pipeline_ != nil && !beautificationOn_ {
            beautificationLevel_ = beautificationLevel
            pipeline_?.beautificationLevel = beautificationLevel_
            pipeline_?.enableBeautification()
            beautificationOn_ = true
        }
    }
    
    public func ClearBeautification() {
        if pipeline_ != nil && beautificationOn_ {
            beautificationLevel_ = -1.0
            pipeline_?.disableBeautification()
            beautificationOn_ = false
        }
    }
    
    public func SetBackgroundImage(pathToImage: String) {
        if pipeline_ != nil && !backgroundOn_ {
            let controller: UnsafeMutablePointer<TSVBReplacementController?> =  UnsafeMutablePointer<TSVBReplacementController?>.allocate(capacity: 1)
            replacementController_ = AutoreleasingUnsafeMutablePointer<TSVBReplacementController?>.init(controller)
            
            let error =  pipeline_?.enableReplaceBackground(replacementController_)
            if error != TSVBPipelineErrorOk {
                print("Can't enable replace background")
            }
                    
            let backgroundImage = frameFactory_?.image(withContentOfFile: pathToImage)
        
            replacementController_?.pointee?.background = backgroundImage
                        
            backgroundOn_ = true
        }
    }
    
    public func SetBackgroundColor(color: UInt32) {
        if pipeline_ != nil && !backgroundOn_ {
            let controller: UnsafeMutablePointer<TSVBReplacementController?> =  UnsafeMutablePointer<TSVBReplacementController?>.allocate(capacity: 1)
            replacementController_ = AutoreleasingUnsafeMutablePointer<TSVBReplacementController?>.init(controller)
            
            let error = pipeline_?.enableReplaceBackground(replacementController_)
            if error != TSVBPipelineErrorOk {
                print("Can't enable replace background")
            }
                    
            let size = width_ * height_ * 4
            
            let bgra = withUnsafeBytes(of: color.littleEndian, Array.init)
            
            var colorBackgroundData = Array<UInt8>(repeating: 0, count: Int(size))
            
            var i:Int = 0

            while i < size {
                colorBackgroundData[i] = bgra[0]
                colorBackgroundData[i + 1] = bgra[1]
                colorBackgroundData[i + 2] = bgra[2]
                colorBackgroundData[i + 3] = bgra[3]

                i += 4
            }
            
            let bytesPointer = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: 1)
            bytesPointer.copyMemory(from: colorBackgroundData, byteCount: Int(size))
            
            let background = frameFactory_?.newFrame(with: TSVBFrameFormatBgra32, data: bytesPointer, bytesPerLine: width_ * 4, width: width_, height: height_, makeCopy: true)

            bytesPointer.deallocate()
            
            replacementController_?.pointee?.background = background
            
            backgroundOn_ = true
        }
    }
    
    public func ClearBackground() {
        if replacementController_ != nil && pipeline_ != nil && backgroundOn_ {
            backgroundOn_ = false
            pipeline_?.disableReplaceBackground()
            replacementController_ = nil
        }
    }
    
    public func Process(cameraBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        CVPixelBufferLockBaseAddress(cameraBuffer, CVPixelBufferLockFlags.readOnly)

        guard let pixelBufferAdress = CVPixelBufferGetBaseAddress(cameraBuffer) else {
            return nil
        }

        guard let initialFrame = frameFactory_?.newFrame(with: TSVBFrameFormatBgra32, data: pixelBufferAdress, bytesPerLine: width_ * 4, width: width_, height: height_, makeCopy: false) else {
            return nil
        }

        CVPixelBufferUnlockBaseAddress(cameraBuffer, CVPixelBufferLockFlags.readOnly)

        guard let processedFrame = pipeline_?.process(initialFrame, error: self.piplineError_) else {
            return nil
        }

        guard let processedPixelBuffer = processedFrame.toCVPixelBuffer()?.takeUnretainedValue() else {
            return nil
        }

        CVPixelBufferLockBaseAddress(processedPixelBuffer, CVPixelBufferLockFlags.readOnly)

        guard let processedPixelBufferAdress = CVPixelBufferGetBaseAddress(processedPixelBuffer) else {
            return nil
        }
        
        guard let surface = surface_ else {
            return nil
        }

        IOSurfaceLock(surface, [], nil)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(processedPixelBuffer)

        let surfaceBaseAddress = IOSurfaceGetBaseAddress(surface)
        let surfaceBytesPerRow = IOSurfaceGetBytesPerRow(surface)

        for y in 0..<Int(height_) {
            let pixelBufferOffset = y * bytesPerRow
            let surfaceOffset = y * surfaceBytesPerRow

            memcpy(surfaceBaseAddress.advanced(by: surfaceOffset),
                   processedPixelBufferAdress.advanced(by: pixelBufferOffset),
                   bytesPerRow)
        }

        IOSurfaceUnlock(surface, [], nil)
        CVPixelBufferUnlockBaseAddress(processedPixelBuffer, CVPixelBufferLockFlags.readOnly)
        
        guard let outBuffer = outBuffer_ else {
            return nil
        }
                
        return outBuffer.takeUnretainedValue()
    }
    
    public func destroy() {
        ClearBlur()
        ClearBackground()
        ClearBeautification()

//        self.piplineError_?.deallocate()
        self.piplineError_ = nil

        self.TSVBFactory_ = nil
        self.frameFactory_ = nil
        self.replacementController_ = nil
        self.pipeline_ = nil

        self.surface_ = nil
        self.outBuffer_ = nil
    }
}
