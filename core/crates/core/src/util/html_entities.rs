//! 基础 HTML/XML 实体解码（漫画标题等元数据清洗用）。
//!
//! 支持常见命名实体与十/十六进制数字实体；未识别片段原样保留。

/// 解码常见 HTML/XML 实体。已干净的字符串幂等返回。
pub fn decode_basic_html_entities(input: &str) -> String {
    if !input.contains('&') {
        return input.to_string();
    }

    let mut out = String::with_capacity(input.len());
    let bytes = input.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] != b'&' {
            let ch = input[i..].chars().next().unwrap();
            out.push(ch);
            i += ch.len_utf8();
            continue;
        }

        let rest = &input[i..];
        if let Some((decoded, consumed)) = try_decode_entity(rest) {
            out.push(decoded);
            i += consumed;
        } else {
            out.push('&');
            i += 1;
        }
    }
    out
}

fn try_decode_entity(s: &str) -> Option<(char, usize)> {
    if s.len() < 3 || !s.starts_with('&') {
        return None;
    }

    if let Some(semi) = s.find(';') {
        let body = &s[1..semi];
        if body.is_empty() {
            return None;
        }
        let consumed = semi + 1;
        if let Some(ch) = decode_named(body).or_else(|| decode_numeric(body)) {
            return Some((ch, consumed));
        }
    }
    None
}

fn decode_named(name: &str) -> Option<char> {
    match name {
        "amp" => Some('&'),
        "lt" => Some('<'),
        "gt" => Some('>'),
        "quot" => Some('"'),
        "apos" => Some('\''),
        _ => None,
    }
}

fn decode_numeric(body: &str) -> Option<char> {
    let (radix, digits) = if let Some(hex) = body.strip_prefix('#') {
        if let Some(hex_digits) = hex
            .strip_prefix('x')
            .or_else(|| hex.strip_prefix('X'))
        {
            (16, hex_digits)
        } else {
            (10, hex)
        }
    } else {
        return None;
    };

    if digits.is_empty() {
        return None;
    }
    let code = u32::from_str_radix(digits, radix).ok()?;
    char::from_u32(code)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn decodes_decimal_numeric_apostrophe_entities() {
        assert_eq!(decode_basic_html_entities("&#039;"), "'");
        assert_eq!(decode_basic_html_entities("&#39;"), "'");
    }

    #[test]
    fn decodes_hex_numeric_apostrophe_entity() {
        assert_eq!(decode_basic_html_entities("&#x27;"), "'");
        assert_eq!(decode_basic_html_entities("&#X27;"), "'");
    }

    #[test]
    fn decodes_common_named_entities() {
        assert_eq!(decode_basic_html_entities("&amp;"), "&");
        assert_eq!(decode_basic_html_entities("&lt;"), "<");
        assert_eq!(decode_basic_html_entities("&gt;"), ">");
        assert_eq!(decode_basic_html_entities("&quot;"), "\"");
        assert_eq!(decode_basic_html_entities("&apos;"), "'");
    }

    #[test]
    fn decodes_mixed_title_and_preserves_box_drawing_slash() {
        let input = "Fate╱Stay Night Heaven&#039;s Feel - 卷04";
        let expected = "Fate╱Stay Night Heaven's Feel - 卷04";
        assert_eq!(decode_basic_html_entities(input), expected);
    }

    #[test]
    fn returns_clean_string_unchanged() {
        let clean = "Fate╱Stay Night Heaven's Feel";
        assert_eq!(decode_basic_html_entities(clean), clean);
    }

    #[test]
    fn is_idempotent_after_decode() {
        let once = decode_basic_html_entities("A&#039;B&amp;C");
        assert_eq!(once, "A'B&C");
        assert_eq!(decode_basic_html_entities(&once), once);
    }

    #[test]
    fn leaves_incomplete_or_unknown_entities_in_place() {
        assert_eq!(decode_basic_html_entities("&amp"), "&amp");
        assert_eq!(decode_basic_html_entities("&#;"), "&#;");
        assert_eq!(decode_basic_html_entities("&unknown;"), "&unknown;");
        assert_eq!(decode_basic_html_entities("a&b"), "a&b");
    }
}
