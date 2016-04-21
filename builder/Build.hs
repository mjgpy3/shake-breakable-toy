import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util

main :: IO ()
main = do
  shakeArgs shakeOptions{shakeFiles="_build"} $ do
    want ["build-node-project"]

    phony "clean" $ do
      putNormal "Cleaning files in _build"
      removeFilesAfter "_build" ["//*"]

    phony "build-node-project" $ do
      putNormal "Building a node project"
      need ["../node-project" </> "Dockerfile"]
      cmd "docker build -t" ["foo/image"] "../node-project/"

    "_build/run" <.> exe %> \out -> do
        cs <- getDirectoryFiles "" ["//*.c"]
        let os = ["_build" </> c -<.> "o" | c <- cs]
        need os
        cmd "gcc -o" [out] os

    "_build//*.o" %> \out -> do
        let c = dropDirectory1 $ out -<.> "c"
        let m = out -<.> "m"
        () <- cmd "gcc -c" [c] "-o" [out] "-MMD -MF" [m]
        needMakefileDependencies m
