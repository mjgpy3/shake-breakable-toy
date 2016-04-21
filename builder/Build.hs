import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util

main :: IO ()
main = do
  shakeArgs shakeOptions{shakeFiles="_build"} $ do
    want ["build-node-project"]

    phony "build-node-project" $ do
      putNormal "Building a node project"
      need ["../node-project" </> "Dockerfile"]
      cmd "docker build -t" ["foo/image"] "../node-project/"
