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
      let dir = "../node-project"
      need [dir </> "Dockerfile"]
      imageLabel <- readImageLabel
      cmd "docker build -t" ["foo/image:" ++ imageLabel, dir]

    "_build/port" %> \out -> do
      writeFile' out "1234"

    "_build/docker-compose.yml" %> \out -> do
      need ["build-node-project", "_build/port"]
      apiPort <- readFile' "_build/port"
      imageLabel <- readImageLabel
      template "docker-compose.yml" out [
          ("{{image-label}}", imageLabel)
        , ("{{node-port}}", apiPort)
        ]

    phony "local-from-scratch" $ do
      need ["_build/docker-compose.yml"]
      imageLabel <- readImageLabel
      cmd "docker-compose -f" ["_build/docker-compose.yml", "-p", imageLabel,  "up", "-d"]

template :: String -> String -> [(String, String)] -> Action ()
template templateName outputPath replacements = do
  rawText <- readFile' $ "_templates" </> templateName
  writeFile' outputPath $ foldr (uncurry replace) rawText replacements

readImageLabel :: Action String
readImageLabel = getEnvWithDefault "latest" "IMAGE_LABEL"
