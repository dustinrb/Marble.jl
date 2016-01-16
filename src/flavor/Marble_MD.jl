# include("elements/figure.jl")

# Use github flavored markdown as our starting point
mrbl = deepcopy(Markdown.github)

include("block.jl")
include("inline.jl")
# Inserted infront of the paragraph element because that's the catch-all case
insert!(mrbl.regular, length(mrbl.regular), YAMLelement)
mrbl.inner['('] = [interpreted_inline]
mrbl.inner['\$'] = [inline_math]
Markdown.flavors[:mrbl] = mrbl

### DEBUG INFO. DO NOT DELETE YET ###
# Markdown.@flavor mrbl [Markdown.list, Markdown.indentcode, Markdown.blockquote, Markdown.fencedcode, Markdown.hashheader,
#                 Markdown.github_table, Markdown.github_paragraph,
#
#                 Markdown.linebreak, Markdown.escapes, Markdown.en_dash, Markdown.inline_code, Markdown.asterisk_bold,
#                 Markdown.asterisk_italic, Markdown.image, Markdown.link]
#
# const mrbl = Markdown.config([Markdown.list, Markdown.indentcode, Markdown.blockquote, Markdown.fencedcode, Markdown.hashheader,
#                 Markdown.github_table, Markdown.github_paragraph,
#
#                 Markdown.linebreak, Markdown.escapes, Markdown.en_dash, Markdown.inline_code, Markdown.asterisk_bold,
#                 Markdown.asterisk_italic, Markdown.image, Markdown.link]...)
# flavors[$(Expr(:quote, name))] = $(esc(name))
#
# Markdown.github
#
# Base.Markdown.Config(
#     Function[],
#
#     [Base.Markdown.list,Base.Markdown.indentcode,Base.Markdown.blockquote,Base.Markdown.fencedcode,Base.Markdown.hashheader,Base.Markdown.github_table,Base.Markdown.github_paragraph,Base.Markdown.linebreak,Base.Markdown.escapes,Base.Markdown.en_dash,Base.Markdown.inline_code,Base.Markdown.asterisk_bold,Base.Markdown.asterisk_italic,Base.Markdown.image,Base.Markdown.link],
#
#     Dict{Char,Array{Function,1}}()
# )
#
# Base.Markdown.Config(
#     [Base.Markdown.blockquote,Base.Markdown.fencedcode,Base.Markdown.hashheader],
#
#     [Base.Markdown.list,Base.Markdown.indentcode,Base.Markdown.github_table,Base.Markdown.github_paragraph],
#
#     Dict(
#     '['=>[Base.Markdown.link],
#     '\\'=>[Base.Markdown.linebreak,Base.Markdown.escapes],
#     '*'=>[Base.Markdown.asterisk_bold,Base.Markdown.asterisk_italic],
#     '`'=>[Base.Markdown.inline_code],
#     '!'=>[Base.Markdown.image],
#     '-'=>[Base.Markdown.en_dash])
# )
