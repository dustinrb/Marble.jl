"Given a directory, watches for changes to the main document and rebuilds
the whole project when it's saved"
function makepath(path)
    settings = get_settings_env(path)
    env = MarbleEnv(settings)
    prepair(env)
    run_build_loop(env)
end


function makefile(file, env)
    path="$(ENV["HOME"])/.mrbl/builds/$file"
    settings = get_settings_env(path)
    println(
        split(file, '/')[end][1:findlast(file, '.') - 1],
        readstring(file),
        Cache("$(settings["cachedir"])/filehash_list.json"),
        settings)
    env = MarbleDoc(
        split(file, '/')[end][1:findlast(file, '.') - 1],
        readstring(file),
        Cache("$(settings["cachedir"])/filehash_list.json"),
        settings)
    prepair(env)
    run_build_loop(env)
end


function watch_env(env, dir, files...)
    # And keept it persistant if that's what's desired
    if env.settings["watch"]
        println("Starting build loop. Press Ctl-c to stop.")
        while true
            filename, event = watch_file(env.settings["workdir"])

            if filename ∈ files && event.changed
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
    run(`cp -r $(Pkg.dir("Marble"))/templates/project/ $path`)
    cd(path)
    run(`sh $(Pkg.dir("Marble"))/src/cli/init_scripts/init.sh`)
end
