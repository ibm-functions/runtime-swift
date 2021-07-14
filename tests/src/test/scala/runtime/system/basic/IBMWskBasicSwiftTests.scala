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

package runtime.system.basic

import common.rest.WskRestOperations
import common.{TestHelpers, TestUtils, WskActorSystem, WskProps, WskTestHelpers}
import spray.json._

import scala.concurrent.duration.DurationInt
import scala.language.postfixOps

abstract class IBMWskBasicSwiftTests extends TestHelpers with WskTestHelpers with WskActorSystem {

  implicit val wskprops = WskProps()
  val wsk = new WskRestOperations
  lazy val actionKind = "swift:4.0"
  val activationPollDuration = 5.minutes

  behavior of s"Runtime $actionKind"

  it should s"invoke a $actionKind action" in withAssetCleaner(wskprops) { (wp, assetHelper) =>
    val file = Some(TestUtils.getTestActionFilename("hello.swift"))

    val name = "helloSwift"
    assetHelper.withCleaner(wsk.action, name) { (action, _) =>
      action.create(name = name, artifact = file, timeout = Some(4.minutes), kind = Some(actionKind))
    }

    withActivation(wsk.activation, wsk.action.invoke(name), initialWait = 5 seconds, totalWait = activationPollDuration) {
      activation =>
        // should be successful
        activation.response.success shouldBe true
        activation.response.result.get.toString should include("Hello stranger!")
    }
    withActivation(
      wsk.activation,
      wsk.action.invoke(name, Map("name" -> JsString("Sir"))),
      initialWait = 5 seconds,
      totalWait = 60 seconds) { activation =>
      // should be successful
      activation.response.success shouldBe true
      activation.response.result.get.toString should include("Hello Sir!")
    }

  }

  it should s"ensure that $actionKind actions can have a non-default entrypoint" in withAssetCleaner(wskprops) {
    (wp, assetHelper) =>
      val file = Some(TestUtils.getTestActionFilename("niam.swift"))

      val name = "niamSwiftAction"
      assetHelper.withCleaner(wsk.action, name) { (action, _) =>
        action.create(
          name = name,
          artifact = file,
          timeout = Some(4.minutes),
          main = Some("niam"),
          kind = Some(actionKind))
      }

      withActivation(
        wsk.activation,
        wsk.action.invoke(name),
        initialWait = 5 seconds,
        totalWait = activationPollDuration) { activation =>
        // should be successful
        activation.response.success shouldBe true
        activation.response.result.get.fields.get("error") shouldBe empty
        activation.response.result.get.fields.get("greetings") should be(
          Some(JsString("Hello from a non-standard entrypoint.")))
      }

  }

}
