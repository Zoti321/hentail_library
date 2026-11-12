import io, re, collections

s = io.open('dcl_features.txt', encoding='utf-8').read()
cur = None
c = collections.defaultdict(collections.Counter)
rule_re = re.compile(r'^\s*(\S[^\s]*)\s*:\s*https://dcl', re.M)
for line in s.split('\n'):
    st = line.strip()
    if st.startswith('lib') and st.endswith('.dart:'):
        cur = st[:-1].replace(chr(92), '/')
        continue
    if cur and re.match(r'^(STYLE|ERROR|WARNING)\s', line):
        c[cur]['_n'] += 1
        continue
    m = re.search(r'([a-z-]+)\s*:\s*https://dcl', line)
    if cur and m:
        c[cur][m.group(1)] += 1
for f in sorted(c):
    print(sum(v for k, v in c[f].items() if k != '_n'), f, dict(c[f]))
