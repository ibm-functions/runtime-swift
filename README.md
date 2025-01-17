# This repository is no longer maintained.
IBM Cloud Functions reached end of life and this repository is no longer active.

For Apache OpenWhisk visit: [https://github.com/apache/openwhisk](https://github.com/apache/openwhisk).

---


# IBM Cloud Functions runtime for swift

[![Build Status](https://travis-ci.org/ibm-functions/runtime-swift.svg?branch=master)](https://travis-ci.org/ibm-functions/runtime-swift)

## Changelogs
- [Swift 4.2   CHANGELOG.md](swift4.2/CHANGELOG.md)
- [Swift 4.1   CHANGELOG.md](swift4.1/CHANGELOG.md)

## Quick Swift Action
### Simple swift action hello.swift
The traditional support for dictionary still works:
```swift
func main(args: [String:Any]) -> [String:Any] {
    if let name = args["name"] as? String {
        return [ "greeting" : "Hello \(name)!" ]
    } else {
        return [ "greeting" : "Hello swif4!" ]
    }
}
```

## Swift 4.x support

Some examples of using Codable In and Out
### Codable style function signature
Create file `helloCodableAsync.swift`
```swift
// Domain model/entity
struct Employee: Codable {
  let id: Int?
  let name: String?
}
// codable main function
func main(input: Employee, respondWith: (Employee?, Error?) -> Void) -> Void {
    // For simplicity, just passing same Employee instance forward
    respondWith(input, nil)
}
```
```
wsk action update helloCodableAsync helloCodableAsync.swift swift:4.2
```
```
ok: updated action helloCodableAsync
```
```
wsk action invoke helloCodableAsync -r -p id 42 -p name Carlos
```
```json
{
    "id": 42,
    "name": "Carlos"
}
```

### Codable Error Handling
Create file `helloCodableAsync.swift`
```swift
struct Employee: Codable {
    let id: Int?
    let name: String?
}
enum VendingMachineError: Error {
    case invalidSelection
    case insufficientFunds(coinsNeeded: Int)
    case outOfStock
}
func main(input: Employee, respondWith: (Employee?, Error?) -> Void) -> Void {
    // Return real error
    do{
        throw VendingMachineError.insufficientFunds(coinsNeeded: 5)
    } catch {
        respondWith(nil, error)
    }
}
```
```
wsk action update helloCodableError helloCodableError.swift swift:4.2
```
```
ok: updated action helloCodableError
```
```
wsk action invoke helloCodableError -b -p id 42 -p name Carlos
```
```json
{
"name": "helloCodableError",
"response": {
  "result": {
    "error": "insufficientFunds(5)"
  },
"status": "application error",
"success": false
}
```

## Packaging an action as a Swift executable using Swift 4.x

When you create an OpenWhisk Swift action with a Swift source file, it has to be compiled into a binary before the action is run. Once done, subsequent calls to the action are much faster until the container holding your action is purged. This delay is known as the cold-start delay.

To avoid the cold-start delay, you can compile your Swift file into a binary and then upload to OpenWhisk in a zip file. As you need the OpenWhisk scaffolding, the easiest way to create the binary is to build it within the same environment as it will be run in.

### Compiling Swift 4.2

### Compiling Swift 4.2 single file

Use the docker container and pass the single source file as stdin.
Pass the name of the method to the flag `-compile`
```
docker run -i openwhisk/action-swift-v4.2 -compile main <main.swift >../action.zip
```

### Compiling Swift 4.2 multiple files with dependencies
Use the docker container and pass a zip archive containing a `Package.swift` and source files a main source file in the location `Sources/main.swift`.
```
zip - -r * | docker run -i openwhisk/action-swift-v4.2 -compile main >../action.zip
```

For more build examples see [here](./examples/)


### Compiling Swift 4.1
These are the steps:

- Run an interactive Swift action container.
  ```
  docker run --rm -it -v "$(pwd):/owexec" openwhisk/action-swift-v4.1 bash
  ```
  This puts you in a bash shell within the Docker container.

- Copy the source code and prepare to build it.
  ```
  cp /owexec/hello.swift /swift4Action/spm-build/Sources/Action/main.swift
  ```
  ```
  cat /swift4Action/epilogue.swift >> /swift4Action/spm-build/Sources/Action/main.swift
  ```
  ```
  echo '_run_main(mainFunction:main)' >> /swift4Action/spm-build/Sources/Action/main.swift
  ```
  Copy any additional source files to `/swift4Action/spm-build/Sources/Action/`


- Create the `Package.swift` file to add dependencies.
```swift
// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
      .package(url: "https://github.com/IBM-Swift/SwiftyRequest.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
      .target(
        name: "Action",
        dependencies: ["SwiftyRequest"],
        path: "."
      )
    ]
```
  As you can see this example adds `SwiftyRequest` dependencies.

  Notice that now with swift:4.2 is no longer required to include `CCurl`, `Kitura-net` and `SwiftyJSON` in your own `Package.swift`.
  You are free now to use no dependencies, or add the combination that you want with the versions you want.

- Copy Package.swift to spm-build directory
  ```
  cp /owexec/Package.swift /swift4Action/spm-build/Package.swift
  ```

- Change to the spm-build directory.
  ```
  cd /swift4Action/spm-build
  ```

- Compile your Swift Action.
  ```
  swift build -c release
  ```

- Create the zip archive.
  ```
  zip /owexec/hello.zip .build/release/Action
  ```

- Exit the Docker container.
  ```
  exit
  ```

  This has created hello.zip in the same directory as hello.swift.

- Upload it to OpenWhisk with the action name helloSwifty:
  ```
  wsk action update helloSwiftly hello.zip openwhisk/action-swift-v4.2
  ```

- To check how much faster it is, run
  ```
  wsk action invoke helloSwiftly --blocking
  ```


### Building the Swift4 Image
```
./gradlew swift4.2:distDocker
```
This will produce the image `whisk/action-swift-v4.2`

Build and Push image
```
docker login
./gradlew core:swift40Action:distDocker -PdockerImagePrefix=$prefix-user -PdockerRegistry=docker.io
```

### Using Swift 4.2
To use as a docker action
```
wsk action update myAction myAction.swift --docker ibmfunctions/action-swift-v4.2
```
This works on any deployment of Apache OpenWhisk

### To use on deployment that contains the rutime as a kind
To use as a kind action
```
wsk action update myAction myAction.swift --kind swift:4.2
```

## Local development
```
./gradlew swift4.2:distDocker
```
This will produce the image `whisk/action-swift-v4.2`

Build and Push image
```
docker login
./gradlew core:swift41Action:distDocker -PdockerImagePrefix=$prefix-user -PdockerRegistry=docker.io
```

Deploy OpenWhisk using ansible environment that contains the kind `swift:4.2`
Assuming you have OpenWhisk already deploy localy and `OPENWHISK_HOME` pointing to root directory of OpenWhisk core repository.

Set `ROOTDIR` to the root directory of this repository.

Redeploy OpenWhisk
```
cd $OPENWHISK_HOME/ansible
ANSIBLE_CMD="ansible-playbook -i ${ROOTDIR}/ansible/environments/local"
$ANSIBLE_CMD setup.yml
$ANSIBLE_CMD couchdb.yml
$ANSIBLE_CMD initdb.yml
$ANSIBLE_CMD wipe.yml
$ANSIBLE_CMD openwhisk.yml
```

Or you can use `wskdev` and create a soft link to the target ansible environment, for example:
```
ln -s ${ROOTDIR}/ansible/environments/local ${OPENWHISK_HOME}/ansible/environments/local-swift
wskdev fresh -t local-swift
```

### Testing
Install dependencies from the root directory on $OPENWHISK_HOME repository
```
./gradlew install
```

Using gradle to run all tests
```
./gradlew :tests:test
```
Using gradle to run some tests
```
./gradlew :tests:test --tests *ActionContainerTests*
```
Using IntelliJ:
- Import project as gradle project.
- Make sure working directory is root of the project/repo


#### Using container image to test
To use as docker action push to your own dockerhub account
```
docker tag whisk/action-swift-v4.2 $user_prefix/action-swift-v4.2
docker push $user_prefix/action-swift-v4.2
```
Then create the action using your the image from dockerhub
```
wsk action update myAction myAction.swift --docker $user_prefix/action-swift-v4.2
```
The `$user_prefix` is usually your dockerhub user id.

## Maintenance Tasks

### Updating Swift 4.2 runtime
- Check if there is a new version of the [Watson SDK 1.x release](https://github.com/watson-developer-cloud/swift-sdk/releases).
  - If there is a new version for 1.x update the [swift4.2/Package.swift](./swift4.2/Package.swift)
- Check if there is a new dockerhub image from upstream [openwhisk/action-swift-v4.2](https://hub.docker.com/r/openwhisk/action-swift-v4.2/tags)
  - If there is a new tag update the [swift4.2/Dockerfile](./swift4.2/Dockerfile)
### Updating Swift 4.1 runtime
- Check if there is a new version of the [Watson SDK 0.x release](https://github.com/watson-developer-cloud/swift-sdk/releases).
  - If there is a new version for 0.x update the [swift4.1/Package.swift](./swift4.1/Package.swift)
- Check if there is a new dockerhub image from upstream [openwhisk/action-swift-v4.1](https://hub.docker.com/r/openwhisk/action-swift-v4.1/tags)
  - If there is a new tag update the [swift4.1/Dockerfile](./swift4.1/Dockerfile)
### Pushing new versions for runtimes
- After the PR is merged and the master pass Travis CI, checkout master.
- Create tag for each runtime and push upstream
```
git tag 4.2@<new version>
git push upstream 4.2@<new version>
```
- After the image is deployed to production update the `latest` tag for each runtime.
```
git tag 4.2@latest -f
git push upstream 4.2@latest -f
```


# License
[Apache 2.0](LICENSE.txt)


