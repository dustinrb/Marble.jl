"Given a directory, watches for changes to the main document and rebuilds
the whole project when it's saved"
function make(path)
    env = MarbleEnv()

    println("Loading settings... ") # LOGGING

    # Load default settings
    load_conf_file!(env, "$(Pkg.dir("Marble"))/src/defaults.yaml")

    # Loard reader settings
    load_conf_file!(env, "$(ENV["HOME"])/.mrbl/settings.yaml")

    # Make some session settings
    dirname = split(path, '/')[end]
    session_settings = Dict(
        "workdir" => path,
        "dirname" => dirname,
        "maindoc" => "$dirname.md",
    )
    add!(env.settings, session_settings)

    # Read project settings
    load_conf_file!(env, "$path/settings.yaml")

    # Now that we've bootstraped ourselves, let's get going
    println("Building... ") # LOGGIN
    run_build_loop(env)

    # And keept it persistant if that's what's desired
    if env.settings["watch"]
        println("Starting build loop. Press Ctl-c to stop.")
        while true
            filename, event = watch_file(env.settings["workdir"])

            if filename == env.settings["maindoc"] && event.changed
                println("Rebuilding... ")
                run_build_loop(env)
            end
        end
    end
end

"Creates a new MD project in a specified directory. Also runs git init."
function init_project(path)
    projectname = split(path, '/')[end]
    mkpath(path)
end
