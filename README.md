# Marble

[![Build Status](https://travis-ci.org/dustinrb/Marble.jl.svg?branch=master)](https://travis-ci.org/dustinrb/Marble.jl)

Marble is a framework for taking a Markdown document from production to published Latex with little hassle. It has the following parts:

1. Settings framework so we know what's up
2. Markdown parser based on the built in Julia parser (but with a few added element types)
3. Julia post processor to tweak the generated document tree
4. Jijna2 based renderer to convert the Document tree into a usable content body
5. Jinja2 based templating engine to make sure each document has it's headers, footer, and other stuff.
