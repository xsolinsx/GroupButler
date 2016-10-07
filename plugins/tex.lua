local function run(msg, matches)
    local eq = URL.escape(matches[1])
    local url = "http://latex.codecogs.com/png.download?" ..
    "\\dpi{300}%20\\LARGE%20" .. eq

    return sendPhotoId(msg.chat.id, URL.unescape(url))
end

return {
    description = "TEX",
    patterns =
    {
        "^[#!/][Tt][Ee][Xx] (.+)$",
        -- tex
        "^[Ss][Aa][Ss][Hh][Aa] [Ee][Qq][Uu][Aa][Zz][Ii][Oo][Nn][Ee] (.+)$",
        "^[Ee][Qq][Uu][Aa][Zz][Ii][Oo][Nn][Ee] (.+)$",
    },
    run = run,
    min_rank = 0,
    syntax =
    {
        "USER",
        "(#tex|[sasha] equazione) <equation>",
    },
}