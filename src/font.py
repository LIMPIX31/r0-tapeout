import re
from pathlib import Path

ADDR_WIDTH = 5
SPACE_CODE = "11111"
USE = ["Press to start", "Ready", "Hit", "Miss", "Last:", "Best:", ".", "ms", "\xbb", "\xf6"]
INDENT = ' ' * 8

font = {}
with open("./assets/FONT.F08", 'rb') as f:
    data = f.read()

total_bytes = len(data)
total_chars = total_bytes // 8

for i in range(total_chars):
    offset = i * 8
    chunk = data[offset:offset + 8]
    bitmap = int.from_bytes(chunk, byteorder='big')
    font[i] = bitmap

unique_chars = sorted({char for string in USE for char in string}, key=ord)
unique_codes = { format(i, f"0{ADDR_WIDTH}b") : font[0x30 + i] for i in range(10) }
addr_map = {}
allocated = 10

unique_chars.remove(' ')

for char in unique_chars:
    fmt_addr = format(allocated, f"0{ADDR_WIDTH}b")
    unique_codes[fmt_addr] = font[ord(char)]
    addr_map[char] = fmt_addr
    allocated += 1

if allocated >= 2 ** ADDR_WIDTH - 1:
    print("Not enough address space to allocate all unique characters")
    exit(1)

init = "\n"

for key, value in unique_codes.items():
    init += "\n"
    for row in reversed(range(8)):
        le = f"{value & 0xff:08b}"[::-1]
        init += f"{INDENT}rom[{ADDR_WIDTH + 3}'b{key}_{row:03b}] = 8'b{le};\n"
        value >>= 8

codes_comment = "\n"

for key, value in addr_map.items():
    codes_comment += f"\n{INDENT}// '{key}' => {ADDR_WIDTH}'b{value}"

pattern = re.compile(r'(\(\*\sfont_start\s\*\);)(.*?)(\(\*\sfont_end\s\*\);)', re.DOTALL)

def replacer(match):
    start = match.group(1)
    end = match.group(3)

    return f"{start}{codes_comment}{init}\n{INDENT}{end}"

path = Path("./src/bitmap_rom.sv")
source = path.read_text(encoding='utf-8')
new_source = pattern.sub(replacer, source)
path.write_text(new_source, encoding='utf-8')

print(f"Allocated {allocated} characters in {ADDR_WIDTH}-bit address space")
