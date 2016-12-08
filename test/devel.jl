using Marble
reload("Marble")

# Streams
path = Marble.mrbldir("streams/$(string(Base.Random.uuid4()))")
settings = Marble.get_settings(path)
Marble.create_paths(settings)
cache = Marble.Cache("$(settings["paths"]["cache"])/hashes.json")
doc = Marble.MarbleDoc("stream", readstring("$(Pkg.dir("Marble"))//test/docs/test.md"), cache, settings)
Marble.parse(doc)
Marble.process(doc)
Marble.render(doc)
Marble.template(doc)

# File
basename = Marble.get_basename(doc)
texfile = "$(doc.settings["paths"]["base"])/$(Marble.get_basename(doc)).tex"
builddir = abspath(doc.settings["paths"]["build"])
command = `latexmk -$(doc.settings["texcmd"]) -shell-escape -halt-on-error $texfile`
Marble.runindir(builddir) do
    run(command)
end

# Build File
using Marble
reload("Marble")
file_path = Pkg.dir("Marble") * "/test/docs/test.md"
fpath = "/Users/dustinrb/Desktop/t.md"
cd("/Users/dustinrb/Desktop/")
build_path = Marble.get_build_dir(file_path)
run(`open $build_path`)
Marble.clean_tex(file_path)
reload("Marble")
Marble.build_file(fpath, out="/Users/dustinrb/Desktop/test.pdf")
Marble.build_file(file_path, out="/Users/dustinrb/Desktop/test2.pdf")

# Build folder
fpath = "/Users/dustinrb/Desktop/test2"
build_dir(fpath)

# Init Document
using Marble
reload("Marble")
Marble.init_dir("/Users/dustinrb/Desktop/testdoc_$(randstring(3))")
Marble.init_dir("/Users/dustinrb/Desktop/testdoc_$(randstring(3))"; template="test")
Marble.init_dir("/Users/dustinrb/Desktop/testdoc_$(randstring(3))"; template="fail")



run(`open $(pwd())`)
run(`open $path`)
