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
import common.{TestHelpers, WhiskProperties, WskActorSystem, WskProps, WskTestHelpers}
import scala.io.Source
import spray.json._

abstract class CredentialsIBMSwiftActionWatsonTests extends TestHelpers with WskTestHelpers with WskActorSystem {

  implicit val wskprops: WskProps = WskProps()
  val wsk = new WskRestOperations
  lazy val actionKind = "swift:4.1"
  lazy val datdir: String = "tests/dat/actions/integration/"
  lazy val dictWatsonFile = "testWatsonAction.swift"
  lazy val codWatsonFile = "testWatsonActionCodable.swift"

  // read credentials from from vcap_services.json
  val vcapFile = WhiskProperties.getProperty("vcap.services.file")
  val vcapString = Source.fromFile(vcapFile).getLines.mkString
  val vcapInfo =
    JsonParser(ParserInput(vcapString)).asJsObject.fields("language_translator").asInstanceOf[JsArray].elements(0)
  val creds = vcapInfo.asJsObject.fields("credentials").asJsObject
  val url = creds.fields("url").asInstanceOf[JsString]
  val username = creds.fields("username").asInstanceOf[JsString]
  val password = creds.fields("password").asInstanceOf[JsString]

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
        parameters = Map("url" -> url, "username" -> username, "password" -> password))
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
        parameters = Map("url" -> url, "username" -> username, "password" -> password))
    }

    withActivation(wsk.activation, wsk.action.invoke("testWatsonActionCodable")) { activation =>
      val response = activation.response
      response.result.get.fields.get("error") shouldBe empty
      response.result.get.fields("translation") shouldBe JsString("Hola")
    }

  }

}
