import re

single_quote_regex = re.compile("'([^\\']|\\')*?'")
whitespace_regex = re.compile("[ \\t]+")

# Parses a string into a list of arguments using bash syntax
# Doesn't handle multiline string
def parse_args(txt, sep = None):
    if sep is None:
        txt = txt.strip()

    out = []

    def fmt(output):
        return ''.join(output).encode('utf-8').decode('unicode_escape')


    idx = 0

    while idx < len(txt):
        char = txt[idx]

        if char == '\n' and not escaped:
            break
        if char == "'":
            if out:
                raise Exception("Used a quote in a place it's not allowed")
            quote = single_quote_regex.match(txt[idx:])
            if not quote:
                raise Exception("Unclosed Quote")
            else:
                group = quote.group()
                idx += len(group)
                out = fmt(group[1:-1])
                continue
        elif sep is None and (char == ' ' or char == '\t'):
            if out:
                yield fmt(out)
                out = []
            group = whitespace_regex.match(txt[idx:]).group()
            idx += len(group)
            continue
        elif sep is not None and char in sep:
            yield fmt(out)
            out = []
            idx += 1
        else:
            out.append(char)
            idx += 1

    if out:
        yield fmt(out)
