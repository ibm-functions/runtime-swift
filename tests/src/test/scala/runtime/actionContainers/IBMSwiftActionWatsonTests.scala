/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package runtime.actionContainers

import org.junit.runner.RunWith
import org.scalatest.junit.JUnitRunner
import spray.json.{JsObject, JsString}
import actionContainers.ActionContainer
import actionContainers.ActionContainer.withContainer
import common.WskActorSystem

@RunWith(classOf[JUnitRunner])
class IBMSwiftActionWatsonTests extends BasicActionRunnerTests with WskActorSystem {

  val enforceEmptyOutputStream = false
  val imageName = "action-swift-v4.1"
  override def withActionContainer(env: Map[String, String] = Map.empty)(code: ActionContainer => Unit) = {
    withContainer(imageName, env)(code)
  }

  lazy val watsonCode = """
    | import ConversationV1
    | import DiscoveryV1
    | import NaturalLanguageClassifierV1
    | import NaturalLanguageUnderstandingV1
    | import PersonalityInsightsV3
    | import ToneAnalyzerV3
    | import VisualRecognitionV3
    |
    | func main(args: [String:Any]) -> [String:Any] {
    |     return ["message": "I compiled and was able to import Watson SDKs"]
    | }
  """.stripMargin

  it should "make Watson SDKs available to action authors" in {
    val (out, err) = withActionContainer() { c =>
      val code = watsonCode

      val (initCode, _) = c.init(initPayload(code))

      initCode should be(200)

      val args = JsObject("message" -> (JsString("serverless")))
      val (runCode, out) = c.run(runPayload(args))
      runCode should be(200)
    }

    checkStreams(out, err, {
      case (o, e) =>
        if (enforceEmptyOutputStream) o shouldBe empty
        e shouldBe empty
    })
  }

}
