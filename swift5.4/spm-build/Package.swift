// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import PackageDescription

let package = Package(
    name: "Action",
    dependencies: [
        // .package(url: "https://github.com/watson-developer-cloud/swift-sdk", .exact("4.2.1"))
        .package(name: "WatsonDeveloperCloud", url: "https://github.com/watson-developer-cloud/swift-sdk", .exact("4.2.1"))
    ],
    targets: [
      .target(
        name: "Action",
        dependencies: [
          .product(name: "AssistantV1", package: "WatsonDeveloperCloud"),
          .product(name: "AssistantV2", package: "WatsonDeveloperCloud"),
          .product(name: "DiscoveryV1", package: "WatsonDeveloperCloud"),
          .product(name: "LanguageTranslatorV3", package: "WatsonDeveloperCloud"),
          .product(name: "NaturalLanguageClassifierV1", package: "WatsonDeveloperCloud"),
          .product(name: "NaturalLanguageUnderstandingV1", package: "WatsonDeveloperCloud"),
          .product(name: "PersonalityInsightsV3", package: "WatsonDeveloperCloud"),
          .product(name: "ToneAnalyzerV3", package: "WatsonDeveloperCloud"),
          .product(name: "VisualRecognitionV3", package: "WatsonDeveloperCloud")
          ],
        path: "."
      )
    ]
)
