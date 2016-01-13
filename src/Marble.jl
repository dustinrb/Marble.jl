module Marble

export
    # Types
    MarbleEnv,
    # Functions
    parse, process, render, template, build

# Markdown becoming Latex
using SettingsBundles
using YAML

include("build_chain.jl") # Main application logic
include("flavor/Marble_MD.jl") # Custom MD flavor
include("render/jinja.jl") # Wrpper around Jinja2
include("util.jl") # Utility functions

end # module
