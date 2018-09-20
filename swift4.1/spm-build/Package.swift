// swift-tools-version:4.0
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
    products: [
      .executable(
        name: "Action",
        targets:  ["Action"]
      )
    ],
    dependencies: [
        .package(url: "https://github.com/watson-developer-cloud/swift-sdk", .exact("0.34.0"))
    ],
    targets: [
      .target(
        name: "Action",
        dependencies: [
          "AssistantV1",
          "ConversationV1",
          "DiscoveryV1",
          "LanguageTranslatorV3",
          "NaturalLanguageClassifierV1",
          "NaturalLanguageUnderstandingV1",
          "PersonalityInsightsV3",
          "ToneAnalyzerV3",
          "VisualRecognitionV3"
          ]
      )
    ]
)
