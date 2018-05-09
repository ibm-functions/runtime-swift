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

import java.io.File
import common.WskActorSystem
import actionContainers.{ActionContainer, ActionProxyContainerTestUtils, ResourceHelpers}
import actionContainers.ActionContainer.withContainer
import spray.json.DefaultJsonProtocol._
import spray.json._

abstract class SwiftActionContainerTests extends BasicActionRunnerTests with WskActorSystem {

  // note: "out" will likely not be empty in some swift build as the compiler
  // prints status messages and there doesn't seem to be a way to quiet them
  val enforceEmptyOutputStream = false
  lazy val swiftContainerImageName = "action-swift-v4.1"
  lazy val swiftBinaryName = "tests/dat/build/swift4.1/HelloSwift4.zip"
  lazy val partyCompile = "tests/dat/build/swift4.1/SwiftyRequest.zip"
  lazy val partyCompileCodable = "tests/dat/build/swift4.1/SwiftyRequestCodable.zip"
  val echoURLPost = "https://eu.httpbin.org/post"
  val echoURLGet = "https://eu.httpbin.org/get"

  val httpCode = """
                   | import Dispatch
                   | func main(args:[String: Any]) -> [String:Any] {
                   |     var resp :[String:Any] = ["error":"getUrl failed"]
                   |     guard let urlStr = args["getUrl"] as? String else {
                   |         return ["error":"getUrl not found in action input"]
                   |     }
                   |     guard let url = URL(string: urlStr) else {
                   |         return ["error":"invalid url string \(urlStr)"]
                   |     }
                   |     let request = URLRequest(url: url)
                   |     let session = URLSession(configuration: .default)
                   |     let semaphore = DispatchSemaphore(value: 0)
                   |     let task = session.dataTask(with: request, completionHandler: {data, response, error -> Void in
                   |         print("done with http request")
                   |         if let error = error {
                   |             print("There was an error \(error)")
                   |         } else if let data = data,
                   |             let response = response as? HTTPURLResponse,
                   |             response.statusCode == 200 {
                   |             do {
                   |                 let respJson = try JSONSerialization.jsonObject(with: data)
                   |                 if respJson is [String:Any] {
                   |                     resp = respJson as! [String:Any]
                   |                 } else {
                   |                     resp = ["error":"Response from server is not a dictionary"]
                   |                 }
                   |             } catch {
                   |                 resp = ["error":"Error creating json from response: \(error)"]
                   |             }
                   |         }
                   |         semaphore.signal()
                   |     })
                   |     task.resume()
                   |     _ = semaphore.wait(timeout: .distantFuture)
                   |     return resp
                   | }
                 """.stripMargin

  behavior of swiftContainerImageName

  testEcho(Seq {
    (
      "swift echo",
      """
        | import Foundation
        |
        | extension FileHandle : TextOutputStream {
        |     public func write(_ string: String) {
        |         guard let data = string.data(using: .utf8) else { return }
        |         self.write(data)
        |     }
        | }
        |
        | func main(args: [String: Any]) -> [String: Any] {
        |     print("hello stdout")
        |     var standardError = FileHandle.standardError
        |     print("hello stderr", to: &standardError)
        |     return args
        | }
      """.stripMargin)
  })

  testUnicode(Seq {
    (
      "swift unicode",
      """
        | func main(args: [String: Any]) -> [String: Any] {
        |     if let str = args["delimiter"] as? String {
        |         let msg = "\(str) ☃ \(str)"
        |         print(msg)
        |         return [ "winter" : msg ]
        |     } else {
        |         return [ "error" : "no delimiter" ]
        |     }
        | }
      """.stripMargin.trim)
  })

  testEnv(
    Seq {
      (
        "swift environment",
        """
        | func main(args: [String: Any]) -> [String: Any] {
        |     let env = ProcessInfo.processInfo.environment
        |     var a = "???"
        |     var b = "???"
        |     var c = "???"
        |     var d = "???"
        |     var e = "???"
        |     var f = "???"
        |     if let v : String = env["__OW_API_HOST"] {
        |         a = "\(v)"
        |     }
        |     if let v : String = env["__OW_API_KEY"] {
        |         b = "\(v)"
        |     }
        |     if let v : String = env["__OW_NAMESPACE"] {
        |         c = "\(v)"
        |     }
        |     if let v : String = env["__OW_ACTION_NAME"] {
        |         d = "\(v)"
        |     }
        |     if let v : String = env["__OW_ACTIVATION_ID"] {
        |         e = "\(v)"
        |     }
        |     if let v : String = env["__OW_DEADLINE"] {
        |         f = "\(v)"
        |     }
        |     return ["api_host": a, "api_key": b, "namespace": c, "action_name": d, "activation_id": e, "deadline": f]
        | }
      """.stripMargin)
    },
    enforceEmptyOutputStream)

  it should "support actions using non-default entry points" in {
    withActionContainer() { c =>
      val code = """
                   | func niam(args: [String: Any]) -> [String: Any] {
                   |     return [ "result": "it works" ]
                   | }
                   |""".stripMargin

      val (initCode, initRes) = c.init(initPayload(code, main = "niam"))
      initCode should be(200)

      val (_, runRes) = c.run(runPayload(JsObject()))
      runRes.get.fields.get("result") shouldBe Some(JsString("it works"))
    }
  }

  it should "return some error on action error" in {
    val (out, err) = withActionContainer() { c =>
      val code = """
                   | // You need an indirection, or swiftc detects the div/0
                   | // at compile-time. Smart.
                   | func div(x: Int, y: Int) -> Int {
                   |     return x/y
                   | }
                   | func main(args: [String: Any]) -> [String: Any] {
                   |     return [ "divBy0": div(x:5, y:0) ]
                   | }
                 """.stripMargin

      val (initCode, _) = c.init(initPayload(code))
      initCode should be(200)

      val (runCode, runRes) = c.run(runPayload(JsObject()))
      runCode should be(502)

      runRes shouldBe defined
      runRes.get.fields.get("error") shouldBe defined
    }

    checkStreams(out, err, {
      case (o, e) =>
        if (enforceEmptyOutputStream) o shouldBe empty
        e shouldBe empty
    })
  }

  it should "log compilation errors" in {
    val (out, err) = withActionContainer() { c =>
      val code = """
                   | 10 PRINT "Hello!"
                   | 20 GOTO 10
                 """.stripMargin

      val (initCode, _) = c.init(initPayload(code))
      initCode should not be (200)
    }

    checkStreams(out, err, {
      case (o, e) =>
        if (enforceEmptyOutputStream) o shouldBe empty
        e.toLowerCase should include("error")
    })
  }

  it should "support application errors" in {
    val (out, err) = withActionContainer() { c =>
      val code = """
                   | func main(args: [String: Any]) -> [String: Any] {
                   |     return [ "error": "sorry" ]
                   | }
                 """.stripMargin

      val (initCode, _) = c.init(initPayload(code))
      initCode should be(200)

      val (runCode, runRes) = c.run(runPayload(JsObject()))
      runCode should be(200) // action writer returning an error is OK

      runRes shouldBe defined
      runRes should be(Some(JsObject("error" -> JsString("sorry"))))
    }

    checkStreams(out, err, {
      case (o, e) =>
        if (enforceEmptyOutputStream) o shouldBe empty
        e shouldBe empty
    })
  }

  it should "support pre-compiled binary in a zip file" in {
    val zip = new File(swiftBinaryName).toPath
    val code = ResourceHelpers.readAsBase64(zip)

    val (out, err) = withActionContainer() { c =>
      val (initCode, initRes) = c.init(initPayload(code))
      initCode should be(200)

      val args = JsObject()
      val (runCode, runRes) = c.run(runPayload(args))

      runCode should be(200)
      runRes.get shouldBe JsObject("greeting" -> (JsString("Hello stranger!")))
    }

    checkStreams(out, err, {
      case (o, e) =>
        if (enforceEmptyOutputStream) o shouldBe empty
        e shouldBe empty
    })
  }

  it should "be able to do an http request" in {
    val (out, err) = withActionContainer() { c =>
      val (initCode, _) = c.init(initPayload(httpCode))

      initCode should be(200)

      val argss = List(JsObject("getUrl" -> JsString("https://openwhisk.ng.bluemix.net/api/v1")))

      for (args <- argss) {
        val (runCode, out) = c.run(runPayload(args))
        runCode should be(200)
      }
    }

    // in side try catch finally print (out file)
    // in catch block an error has occurred, get docker logs and print
    // throw

    checkStreams(out, err, {
      case (o, e) =>
        if (enforceEmptyOutputStream) o shouldBe empty
        e shouldBe empty
    })
  }
  it should "support ability to use 3rd party packages like SwiftyRequest" in {
    val zip = new File(partyCompile).toPath
    val code = ResourceHelpers.readAsBase64(zip)

    val (out, err) = withActionContainer() { c =>
      val (initCode, initRes) = c.init(initPayload(code))
      initCode should be(200)

      val args = Map("message" -> JsString("serverless"), "url" -> JsString(echoURLPost))
      val (runCode, runRes) = c.run(runPayload(JsObject(args)))

      runCode should be(200)
      val json = runRes.get.fields.get("json")
      json shouldBe Some(JsObject(args))
    }

    checkStreams(out, err, {
      case (o, e) =>
        if (enforceEmptyOutputStream) o shouldBe empty
        e shouldBe empty
    })
  }

  it should "support ability to use escaping completion in Codable" in {
    val zip = new File(partyCompileCodable).toPath
    val code = ResourceHelpers.readAsBase64(zip)

    val (out, err) = withActionContainer() { c =>
      val (initCode, initRes) = c.init(initPayload(code))
      initCode should be(200)

      val (runCode, runRes) = c.run(runPayload(JsObject("url" -> JsString(echoURLGet))))

      runCode should be(200)
      runRes.get.fields.get("greeting") shouldBe Some(JsString("success"))

    }

    checkStreams(out, err, {
      case (o, e) =>
        if (enforceEmptyOutputStream) o shouldBe empty
        e shouldBe empty
    })
  }

  it should "receive a large (1MB) argument" in {
    withActionContainer() { c =>
      val code = """
                   | func main(args: [String: Any]) -> [String: Any] {
                   |     return args
                   | }
                   |""".stripMargin

      val (initCode, initRes) = c.init(initPayload(code))
      initCode should be(200)

      val arg = JsObject("arg" -> JsString(("a" * 1048561)))
      val (_, runRes) = c.run(runPayload(arg))
      runRes.get shouldBe arg
    }
  }

  // Helpers specific to swift actions
  override def withActionContainer(env: Map[String, String] = Map.empty)(code: ActionContainer => Unit) = {
    withContainer(swiftContainerImageName, env)(code)
  }

}

trait BasicActionRunnerTests extends ActionProxyContainerTestUtils {
  def withActionContainer(env: Map[String, String] = Map.empty)(code: ActionContainer => Unit): (String, String)

  /**
   * Runs tests for actions which do not return a dictionary and confirms expected error messages.
   * @param codeNotReturningJson code to execute, should not return a JSON object
   * @param checkResultInLogs should be true iff the result of the action is expected to appear in stdout or stderr
   */
  def testNotReturningJson(codeNotReturningJson: String, checkResultInLogs: Boolean = true) = {
    it should "run and report an error for script not returning a json object" in {
      val (out, err) = withActionContainer() { c =>
        val (initCode, _) = c.init(initPayload(codeNotReturningJson))
        initCode should be(200)
        val (runCode, out) = c.run(JsObject())
        runCode should be(502)
        out should be(Some(JsObject("error" -> JsString("The action did not return a dictionary."))))
      }

      checkStreams(out, err, {
        case (o, e) =>
          if (checkResultInLogs) {
            (o + e) should include("not a json object")
          } else {
            o shouldBe empty
            e shouldBe empty
          }
      })
    }
  }

  /**
   * Runs tests for code samples which are expected to echo the input arguments
   * and print hello [stdout, stderr].
   */
  def testEcho(stdCodeSamples: Seq[(String, String)]) = {
    stdCodeSamples.foreach { s =>
      it should s"run a ${s._1} script" in {
        val argss = List(
          JsObject("string" -> JsString("hello")),
          JsObject("string" -> JsString("❄ ☃ ❄")),
          JsObject("numbers" -> JsArray(JsNumber(42), JsNumber(1))),
          // JsObject("boolean" -> JsBoolean(true)), // fails with swift3 returning boolean: 1
          JsObject("object" -> JsObject("a" -> JsString("A"))))

        val (out, err) = withActionContainer() { c =>
          val (initCode, _) = c.init(initPayload(s._2))
          initCode should be(200)

          for (args <- argss) {
            val (runCode, out) = c.run(runPayload(args))
            runCode should be(200)
            out should be(Some(args))
          }
        }

        checkStreams(out, err, {
          case (o, e) =>
            o should include("hello stdout")
            e should include("hello stderr")
        }, argss.length)
      }
    }
  }

  def testUnicode(stdUnicodeSamples: Seq[(String, String)]) = {
    stdUnicodeSamples.foreach { s =>
      it should s"run a ${s._1} action and handle unicode in source, input params, logs, and result" in {
        val (out, err) = withActionContainer() { c =>
          val (initCode, _) = c.init(initPayload(s._2))
          initCode should be(200)

          val (runCode, runRes) = c.run(runPayload(JsObject("delimiter" -> JsString("❄"))))
          runRes.get.fields.get("winter") shouldBe Some(JsString("❄ ☃ ❄"))
        }

        checkStreams(out, err, {
          case (o, _) =>
            o.toLowerCase should include("❄ ☃ ❄")
        })
      }
    }
  }

  /** Runs tests for code samples which are expected to return the expected standard environment {auth, edge}. */
  def testEnv(stdEnvSamples: Seq[(String, String)],
              enforceEmptyOutputStream: Boolean = true,
              enforceEmptyErrorStream: Boolean = true) = {
    stdEnvSamples.foreach { s =>
      it should s"run a ${s._1} script and confirm expected environment variables" in {
        val props = Seq(
          "api_host" -> "xyz",
          "api_key" -> "abc",
          "namespace" -> "zzz",
          "action_name" -> "xxx",
          "activation_id" -> "iii",
          "deadline" -> "123")
        val env = props.map { case (k, v) => s"__OW_${k.toUpperCase()}" -> v }

        val (out, err) = withActionContainer(env.take(1).toMap) { c =>
          val (initCode, _) = c.init(initPayload(s._2))
          initCode should be(200)

          val (runCode, out) = c.run(runPayload(JsObject(), Some(props.toMap.toJson.asJsObject)))
          runCode should be(200)
          out shouldBe defined
          props.map {
            case (k, v) =>
              withClue(k) {
                out.get.fields(k) shouldBe JsString(v)
              }

          }
        }

        checkStreams(out, err, {
          case (o, e) =>
            if (enforceEmptyOutputStream) o shouldBe empty
            if (enforceEmptyErrorStream) e shouldBe empty
        })
      }
    }

  }
}
