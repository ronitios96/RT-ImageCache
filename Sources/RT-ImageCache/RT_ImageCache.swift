import Foundation
#if canImport(UIKit)
import UIKit

///To throw a string based error directly from anywhere
extension String: Error { }

///Main Actor to be used for Image Caching Purpose
public actor ImageCacheUtility {
    
    ///Image State could be one of the following - Completed (Returns UIImage) - inProgress (Returns the task at hand) - failed (Return failure error)
    enum ImageState {
        case completed(image: UIImage)
        case inProgress(task: Task<UIImage, Error>)
        case failed(error: Error)
    }
    
    ///Reference to the file manager
    private let fileManager = FileManager.default
    ///Shared instance to access the actor anywhere
    public static let shared = ImageCacheUtility()
    ///Directory URL
    private let directory: URL
    ///In-App/In-Memory Cache
    private var cache: [String: ImageState] = [:]
    
    ///Failable initializer based on whether we're able to create a directory properly
    private init?() {
        guard let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("ImageCache") else { return nil }
        self.directory = directory
        if !fileManager.fileExists(atPath: self.directory.path) {
            do {
                try fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
            } catch {
                return nil
            }
        }
    }
    
    ///Adds image state to in-app cache
    private func addImage(_ image: String, _ state: ImageState) {
        cache[image] = state
    }
    
    
    // Check if image exists in the in-app cache / or local directory
    ///
    /// - Parameters:
    ///   - url: URL used as key for storage
    /// - Returns: UIImage if it exists
    private func checkIfImageExists(url: String) -> UIImage? {
        guard let state = cache[url], case .completed(let image) = state else {
            var fileURL: URL
            if #available(iOS 16.0, *) {
                fileURL = directory.appending(path: encodeKey(url))
            } else {
                fileURL = directory.appendingPathComponent(encodeKey(url))
            }
            guard let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) else { return nil }
            cache[url] = .completed(image: image)
            return image }
        return image
    }
    
    // Encodes Key because it's a URL and can cause a malformed path so we encode only allowing alphaNumerics
    ///
    /// - Parameters:
    ///   - key: URL used as key for storage
    /// - Returns: Encoded key to be used as the path component for the directory storage
    private func encodeKey(_ key: String) -> String {
        return key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
    }
    
    
    // MARK: Main Function to access an image based on url
    
    // Main function be called on the shared instance to download an image or retrieve it from cache
    ///
    /// - Parameters:
    ///   - url: URL used as key for storage
    /// - Returns: Image, and an additonal message for debugging purpose
    public func image(for url: String) async throws -> (image: UIImage, msg: String) {
        print("Fetching image for url : \(url)")
        if let imageExists = checkIfImageExists(url: url) {
            print("Found in cache completed")
            return (imageExists, "loaded from cache")
        } else {
            if let state = cache[url] {
                switch state {
                case .inProgress(let task):
                    print("Currently in progress")
                    return (try await task.value, "loaded from task already enqueued")
                case .failed(let error):
                    print("Found in cachce with some error")
                    throw error
                default:
                    //Completed condition already checked above
                    break
                }
            }
            print("Proceeding to download - not found in cache/documents")
            let downloadTask: Task<UIImage, Error> = Task.detached(operation: { [weak self] in
                guard let self = self else {
                    throw "Actor does not exist anymore"
                }
                guard let url = URL(string: url) else {
                    throw "Incorrect URL"
                }
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    throw "Could not form image"
                }
                await self.saveImage(for: url.absoluteString, image: image)
                return image
            })
            cache[url] = .inProgress(task: downloadTask)
            return (try await downloadTask.value, "just downloaded")
        }
    }
    
    // Saves image in cache and writes to directory after downloading
    ///
    /// - Parameters:
    ///   - url: URL used as key for storage
    ///   - image: UIImage data
    /// - Returns: Nothing returned from this function
    private func saveImage(for url: String, image: UIImage) {
        self.cache[url] = .completed(image: image)
        var fileURL: URL
        if #available(iOS 16.0, *) {
            fileURL = directory.appending(path: encodeKey(url))
        } else {
            fileURL = directory.appendingPathComponent(encodeKey(url))
        }
        if let data = image.pngData() {
            do {
                try data.write(to: fileURL)
            } catch {
                print("Error writing : \(error.localizedDescription)")
            }
        }
    }
}
#endif

