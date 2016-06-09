"""
Loads in a specified YAML file if it exists. Otherwise, it fails gracefully
"""
function load_conf_file!(path)
    if isfile(path)
        if extension(path) in ["yaml", "yml"]
            return SettingsYAMLFile(path)
        elseif extension(path) in ["json"]
            return SettingsJSONFile(path)
        else
            error("Marble does not know how to handle settings files of type \"$(extension(path))\"")
        end
    else
        warn("Configuration file `$path` not found. Continuing without it 🙁")
    end
    return env
end

"""
Constructs a MarbleEnv based on current path and settings files
"""
function get_env(path)
    println("Loading settings... ") # LOGGING
    dirname = split(path, '/')[end]
    env = MarbleEnv(
        load_conf_file!("$(Pkg.dir("Marble"))/src/defaults.yaml"), # Defaults
        load_conf_file!("$(ENV["HOME"])/.mrbl/settings.yaml"), # User settings
        Dict(
            "workdir" => path,
            "dirname" => dirname,
            "maindoc" => "$dirname.md",
        ),
        load_conf_file!("$path/settings.yaml") # Project Settings
    )

    return env
end

"""
Builds a document given a specified Marble object
"""
function run_build_loop(env::MarbleEnv)
    # Maybe in the future, allow for drop in replacements based on
    # the evironment. For now, just run the standard loop.
    main_path = "$(env.settings["workdir"])/$(env.settings["maindoc"])"
    analysis_path = "$(env.settings["workdir"])/$(env.settings["analysis"])"

    if changed(env.cache, main_path) | changed(env.cache, analysis_path)
        parse(env)
        process(env)
        render(env)
        template(env)

        # Only caching main_path because caching for analysis_path occures in parse(env)
        cache(env.cache, main_path)
        save(env.cache)
    else
        println("No changes detected. Using existing .tex file")
    end
    build(env)
end

"""
Takes a given filename and returns its extension
"""
function extension(path)
    return split(path, '.')[end]
end
