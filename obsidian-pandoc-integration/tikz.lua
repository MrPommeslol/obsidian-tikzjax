local pkgs = {}

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function starts_with(s, prefix)
  return s:sub(1, #prefix) == prefix
end

function CodeBlock(el)
  if not el.classes:includes("tikz") then
    return nil
  end

  local out = {}
  local caption = nil
  local label = nil

  for line in el.text:gmatch("[^\r\n]+") do
    local l = trim(line)

    -- Metadata lines inside tikz block:
    -- % caption: ...
    -- % label: ...
    if starts_with(l, "% caption:") then
      caption = trim(l:gsub("^%% caption:", "", 1))
    elseif starts_with(l, "% label:") then
      label = trim(l:gsub("^%% label:", "", 1))
    else
      local pkg = l:match("^\\usepackage%b{}")
      if pkg then
        pkgs[pkg] = true
      elseif not l:match("^\\documentclass%b{}")
        and l ~= "\\begin{document}"
        and l ~= "\\end{document}" then
        table.insert(out, line)
      end
    end
  end

  local tex = table.concat(out, "\n")
  local has_tikzpicture = tex:match("\\begin%s*{%s*tikzpicture%s*}")

  if has_tikzpicture and caption and caption ~= "" then
    local fig = {}
    table.insert(fig, "\\begin{figure}[htbp]")
    table.insert(fig, "\\centering")
    table.insert(fig, tex)
    table.insert(fig, "\\caption{" .. caption .. "}")
    if label and label ~= "" then
      table.insert(fig, "\\label{" .. label .. "}")
    end
    table.insert(fig, "\\end{figure}")
    tex = table.concat(fig, "\n")
  elseif has_tikzpicture then
    tex = "\\begin{center}\n" .. tex .. "\n\\end{center}"
  end

  return pandoc.RawBlock("latex", tex)
end

function Pandoc(doc)
  local includes = doc.meta["header-includes"] or pandoc.List()
  includes:insert(pandoc.RawBlock("latex", "\\usepackage{tikz}"))
  for p, _ in pairs(pkgs) do
    includes:insert(pandoc.RawBlock("latex", p))
  end
  doc.meta["header-includes"] = includes
  return doc
end