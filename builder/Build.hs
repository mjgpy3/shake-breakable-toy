import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util

import Data.List (intersperse)
import Data.String.Utils (replace)

main :: IO ()
main = do
  shakeArgs shakeOptions{shakeFiles="_build"} $ do
    want ["local-from-scratch"]

    phony "build-node-project" $ do
      alwaysRerun
      let dir = "../node-project"
      need [dir </> "Dockerfile"]
      imageLabel <- getEnvWithDefault "latest" "IMAGE_LABEL"
      putNormal imageLabel
      cmd "docker build -t" ["foo/image:" ++ imageLabel, dir]

    "_build/port" %> \out -> do
      writeFile' out "1234"

    "_build/docker-compose.yml" %> \out -> do
      need ["build-node-project", "_build/port"]
      apiPort <- readFile' "_build/port"
      imageLabel <- getEnvWithDefault "latest" "IMAGE_LABEL"
      template "docker-compose.yml" out [
          ("{{image-label}}", imageLabel)
        , ("{{node-port}}", apiPort)
        ]

    phony "local-from-scratch" $ do
      need ["_build/docker-compose.yml"]
      imageLabel <- getEnvWithDefault "latest" "IMAGE_LABEL"
      cmd "docker-compose -f" ["_build/docker-compose.yml", "-p", imageLabel,  "up", "-d"]

template :: String -> String -> [(String, String)] -> Action ()
template templateName outputPath replacements = do
  rawText <- readFile' $ "_templates" </> templateName
  writeFile' outputPath $ foldr (uncurry replace) rawText replacements
