"""Creates a Jinja2 ENV based on the settings ENV"""
function mkjinjaenv(env::MarbleEnv)
    return jinja2.Environment(
        loader=jinja2.FileSystemLoader([
            env.settings["templatedir"],
            "$(ENV["HOME"])/.mrbl/templates",
            "$(Pkg.dir("Marble"))/templates"
        ]),
        block_start_string=env.settings["JINJA_block_start_string"],
        block_end_string=env.settings["JINJA_block_end_string"],
        variable_start_string=env.settings["JINJA_variable_start_string"],
        variable_end_string=env.settings["JINJA_variable_end_string"],
        comment_start_string=env.settings["JINJA_comment_start_string"],
        comment_end_string=env.settings["JINJA_comment_end_string"],
        keep_trailing_newline=true
    )
end
