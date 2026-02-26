# parse_words.awk - Parse IELTS word-list YAML to TSV (title, phonetics, chinese, example)
# Author: pjliu
# Usage: awk -f parse_words.awk word-list-01.yaml [word-list-02.yaml ...]
# Output: one line per word, TAB-separated: title\tphonetics\tchinese\texample
# Newlines in fields are replaced by space. Empty title => use key.

BEGIN { OFS = "\t"; state = "key"; key = ""; title = ""; text = ""; example = "" }

# Skip comments and empty lines at top level
/^#/ { next }
/^[[:space:]]*$/ && state == "key" { next }

# New word key: line does not start with space and ends with :
/^[^[:space:]#][^:]*:[[:space:]]*$/ {
    if (key != "" || state != "key") {
        flush()
    }
    key = $0
    sub(/:[[:space:]]*$/, "", key)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
    state = "title"
    title = ""
    text = ""
    example = ""
    next
}

# In title block: "  title: value" or "  title:"
state == "title" && /^[[:space:]]+title:/ {
    title = $0
    sub(/^[[:space:]]+title:[[:space:]]*/, "", title)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", title)
    state = "text"
    next
}

# In text block: "  text: inline" or "  text: |"
state == "text" && /^[[:space:]]+text:/ {
    if (match($0, /^[[:space:]]+text:[[:space:]]*\|[[:space:]]*$/)) {
        text = ""
        state = "textblock"
    } else {
        text = $0
        sub(/^[[:space:]]+text:[[:space:]]*/, "", text)
        state = "example"
    }
    next
}

# Collecting multiline text
state == "textblock" {
    # Next key (no leading space) or next field (  title:/  example:) ends block
    if (/^[^[:space:]#][^:]*:[[:space:]]*$/) {
        state = "key"
        # Reprocess this line
        if (key != "") flush()
        key = $0
        sub(/:[[:space:]]*$/, "", key)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
        state = "title"
        title = ""
        text = ""
        example = ""
        next
    }
    if (/^[[:space:]]+example:/) {
        example = $0
        sub(/^[[:space:]]+example:[[:space:]]*/, "", example)
        state = "key"
        flush()
        key = ""
        title = ""
        text = ""
        example = ""
        next
    }
    if (/^[[:space:]]+title:/) {
        state = "title"
        title = $0
        sub(/^[[:space:]]+title:[[:space:]]*/, "", title)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", title)
        state = "text"
        next
    }
    # Append to text (strip leading spaces from content line)
    line = $0
    sub(/^[[:space:]]+/, "", line)
    text = (text == "" ? line : text " " line)
    next
}

# "  example: ..."
state == "example" && /^[[:space:]]+example:/ {
    example = $0
    sub(/^[[:space:]]+example:[[:space:]]*/, "", example)
    state = "key"
    flush()
    key = ""
    title = ""
    text = ""
    example = ""
    next
}

# After "  text: inline" we might see "  example:" on next line; if we see new key, flush without example
state == "example" && /^[^[:space:]#][^:]*:[[:space:]]*$/ {
    state = "key"
    if (key != "") flush()
    key = $0
    sub(/:[[:space:]]*$/, "", key)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
    state = "title"
    title = ""
    text = ""
    example = ""
    next
}

END { if (key != "" || state != "key") flush() }

function flush() {
    if (key == "") return
    t = (title != "" ? title : key)
    # Extract phonetics: first [...] in text (keep brackets for display)；无音标时用 "-" 占位，保证 TSV 恒为 4 列（避免空列导致 read 错位）
    ph = "-"
    if (match(text, /\[[^\]]+\]/)) ph = substr(text, RSTART, RLENGTH)
    # Chinese: after first ] (rest of line); if no ] use whole text
    ch = text
    if (match(text, /\]/)) ch = substr(text, RSTART + 1)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", ch)
    # 去掉多词性时出现的 __单词__ 标记，避免释义中残留
    gsub(/__[^_]+__/, "", ch)
    gsub(/[[:space:]]+/, " ", ch)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", ch)
    # Normalize output: no TAB/newline in fields
    gsub(/[\t\n\r]+/, " ", t)
    gsub(/[\t\n\r]+/, " ", ph)
    gsub(/[\t\n\r]+/, " ", ch)
    gsub(/[\t\n\r]+/, " ", example)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", t)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", ph)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", ch)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", example)
    print t, ph, ch, example
}
