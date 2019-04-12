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

package runtime.integration

import java.io.File

import common.rest.WskRestOperations
import common.{TestHelpers, TestUtils, WskActorSystem, WskProps, WskTestHelpers}
import spray.json._

abstract class CredentialsIBMSwiftActionWatsonTests extends TestHelpers with WskTestHelpers with WskActorSystem {

  implicit val wskprops: WskProps = WskProps()
  val wsk = new WskRestOperations
  lazy val actionKind = "swift:4.1"
  lazy val datdir: String = "tests/dat/actions/integration/"
  lazy val dictWatsonFile = "testWatsonAction.swift"
  lazy val codWatsonFile = "testWatsonActionCodable.swift"

  var creds = TestUtils.getVCAPcredentials("language_translator")

  /*
    Uses Watson Translation Service to translate the word "Hello" in English, to "Hola" in Spanish.
   */

  it should s"Test whether watson translate service is reachable using Dictionary $actionKind" in withAssetCleaner(
    wskprops) { (wp, assetHelper) =>
    val file = Some(new File(datdir, dictWatsonFile).toString())
    assetHelper.withCleaner(wsk.action, "testWatsonAction") { (action, _) =>
      action.create(
        "testWatsonAction",
        file,
        main = Some("main"),
        kind = Some(actionKind),
        parameters = Map(
          "url" -> JsString(creds.get("url")),
          "username" -> JsString(creds.get("username")),
          "password" -> JsString(creds.get("password"))))
    }

    withActivation(wsk.activation, wsk.action.invoke("testWatsonAction")) { activation =>
      val response = activation.response
      response.result.get.fields.get("error") shouldBe empty
      response.result.get.fields("translation") shouldBe JsString("Hola")
    }

  }

  it should s"Test whether watson translate service is reachable using using Codable $actionKind" in withAssetCleaner(
    wskprops) { (wp, assetHelper) =>
    val file = Some(new File(datdir, codWatsonFile).toString())
    assetHelper.withCleaner(wsk.action, "testWatsonActionCodable") { (action, _) =>
      action.create(
        "testWatsonActionCodable",
        file,
        main = Some("main"),
        kind = Some(actionKind),
        parameters = Map(
          "url" -> JsString(creds.get("url")),
          "username" -> JsString(creds.get("username")),
          "password" -> JsString(creds.get("password"))))
    }

    withActivation(wsk.activation, wsk.action.invoke("testWatsonActionCodable")) { activation =>
      val response = activation.response
      response.result.get.fields.get("error") shouldBe empty
      response.result.get.fields("translation") shouldBe JsString("Hola")
    }

  }

}
