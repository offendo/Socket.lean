import Lake

open System
open Lake DSL

package Socket {
  precompileModules := true
}

@[default_target]
lean_lib Socket

def cDir   : FilePath := "native"
def ffiSrc : FilePath := "native.c"
def ffiO   : FilePath := "ffi.o"
def ffiLib : FilePath := "libffi"

target ffi.o (pkg : NPackage _package.name) : FilePath := do
  let oFile := pkg.buildDir / ffiO
  let srcJob ←  inputFile (pkg.dir / cDir / ffiSrc) False
  let job <- buildFileAfterDep oFile srcJob (fun _ => do
    let flags := #["-I", (← getLeanIncludeDir).toString, "-fPIC"]
    compileO oFile (pkg.dir / cDir / ffiSrc) flags "cc")
  return job

extern_lib ffi pkg := do
  let ffiO ←  ffi.o.fetch
  buildStaticLib (pkg.buildDir / "lib" / ffiLib) #[ffiO]

script examples do
  let examplesDir ← ("examples" : FilePath).readDir
  for ex in examplesDir do
    IO.println ex.path
    let o ← IO.Process.output {
      cmd := "lake"
      args := #["build"]
      cwd := ex.path
    }
    IO.println o.stderr
  return 0

script clean do
  let examplesDir ← ("examples" : FilePath).readDir
  let _ ← IO.Process.output {
      cmd := "lake"
      args := #["clean"]
  }
  for ex in examplesDir do
    let _ ← IO.Process.output {
      cmd := "lake"
      args := #["clean"]
      cwd := ex.path
    }
  return 0
