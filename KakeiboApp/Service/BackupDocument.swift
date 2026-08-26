//
//  BackupDocument.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/26
//
//

import SwiftUI
import UniformTypeIdentifiers

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.json]
    }

    static var writableContentTypes: [UTType] {
        [.json]
    }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
