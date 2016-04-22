import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util

import Data.List (intersperse)
import Data.String.Utils (replace)

main :: IO ()
main = do
  shakeArgs shakeOptions{shakeFiles="_build"} $ do
    want ["_build/docker-compose.yml"]

    phony "build-node-project" $ do
      let dir = "../node-project"
      need [dir </> "Dockerfile"]
      cmd "docker build -t" ["foo/image", dir]

    "_build/port" %> \out -> do
      writeFile' out "1234"

    "_build/docker-compose.yml" %> \out -> do
      need ["build-node-project", "_build/port"]
      dockerCompose <- readFile' "_templates/docker-compose.yml"
      let finalDockerCompose = replace "{{node-image-name}}" "foo/image" dockerCompose
      writeFile' out finalDockerCompose

    phony "run-locally" $ do
      need ["_build/port", "_build/docker-compose.yml"]
      port <- readFile' "_build/port"
      putNormal port
      cmd "echo" [port]
