# Local copy of codeowners.nvim

Source: [JonasGavenavicius/codeowners.nvim](https://github.com/JonasGavenavicius/codeowners.nvim/tree/903d065ec01a9a94c9a5346b3fd22bdefb66f4db), commit `903d065ec01a9a94c9a5346b3fd22bdefb66f4db`.

This copy is loaded through a local lazy.nvim spec. Updates require reviewing and replacing these files; Lazy does not download new upstream code.

The upstream implementation passed an unescaped buffer directory to a shell in `get_file_owners`. This copy uses Git argument lists and reuses the resulting repository root. The health check also uses an argument list.

The matcher handles zero directories in `**/`, escapes Lua pattern characters, anchors patterns containing a slash to the repository root, resolves directory symlinks, and supports ownerless rules and inline comments. CODEOWNERS discovery uses `.github/CODEOWNERS`, `CODEOWNERS`, then `docs/CODEOWNERS`. Display results are cached between buffer events, writes, directory changes and focus changes so statusline redraws do not repeatedly spawn Git.

This remains a small CODEOWNERS matcher, not a full GitHub validator. Escaped spaces, negation, brace expansion and character classes are unsupported. Ownership display is informational.

The reviewed runtime consists of `plugin/init.lua`, `lua/codeowners/init.lua` and `lua/codeowners/health.lua`. It reads local CODEOWNERS files and invokes `git rev-parse`; it contains no network requests, installers, file writes or dynamic code evaluation. This source review does not guarantee the absence of vulnerabilities. Upstream's README declares MIT, but the reviewed tree has no separate LICENSE file.
