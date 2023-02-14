# Zotero

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://theogf.github.io/Zotero.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://theogf.github.io/Zotero.jl/dev)
[![Build Status](https://github.com/theogf/Zotero.jl/workflows/CI/badge.svg)](https://github.com/theogf/Zotero.jl/actions)
[![codecov](https://codecov.io/gh/theogf/Zotero.jl/branch/main/graph/badge.svg?token=AXHVQME9M5)](https://codecov.io/gh/theogf/Zotero.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

## Installation

```julia
using Pkg
Pkg.add("Zotero")
```

You first need to obtain an API token from Zotero.
Go to your [Zotero account settings](https://www.zotero.org/settings/keys) and create a new API token.
You should also get your user ID from the same page.
Store both of these values in a `.env` file in the root of your project with
the following format:

```toml
ZOTERO_API_TOKEN="[YOUR API TOKEN]"
ZOTERO_USER_ID="[YOUR USER ID]"
```

## Usage

```julia
using Zotero
client = ZoteroClient() # This will go fetch your tokens and build a client
library = get_library(client) # This will fetch your library as a collection of collections.
```
