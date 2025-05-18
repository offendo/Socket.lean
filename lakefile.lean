import Lake

open System
open Lake DSL

package Socket {
  precompileModules := true
}

@[default_target]
lean_lib Socket

def cDir   := "native"
def ffiSrc := "native.c"
def ffiO   := "ffi.o"
def ffiLib := "libffi"

input_file ffi_static.c where
  path := cDir / ffiSrc
  text := true

target ffi.o (pkg : NPackage _package.name) : FilePath := do
  let oFile := pkg.buildDir / ffiO
  let srcJob ←  ffi_static.c.fetch
  let job <- buildFileAfterDep oFile srcJob (fun srcFile => do
    let flags := #["-I", (← getLeanIncludeDir).toString, "-fPIC"]
    compileO oFile (pkg.dir / cDir / ffiSrc) flags "cc")
  return job

extern_lib ffi pkg := do
  let ffiO ←  ffi.o.fetch
  let name := nameToStaticLib ffiLib
  buildStaticLib (pkg.staticLibDir / "lib" / ffiLib) #[ffiO]

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
