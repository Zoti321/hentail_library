use super::local::io_error;
use crate::error::HentaiError;
use quick_xml::{events::Event, name::ResolveResult, NsReader};
use std::ops::Range;

pub(super) struct Node {
    pub name: String,
    pub namespace: String,
    pub attributes: Vec<(String, String)>,
    pub range: Range<usize>,
    pub content: Range<usize>,
    pub depth: usize,
    pub text: String,
    pub empty: bool,
}
impl Node {
    pub fn attr(&self, name: &str) -> Option<&str> {
        self.attributes
            .iter()
            .find(|(key, _)| key == name)
            .map(|(_, value)| value.as_str())
    }
}
pub(super) fn nodes(xml: &str) -> Result<Vec<Node>, HentaiError> {
    let mut reader = NsReader::from_str(xml);
    let mut stack: Vec<Node> = Vec::new();
    let mut nodes = Vec::new();
    let mut roots = 0;
    loop {
        let before = reader.buffer_position() as usize;
        let (namespace, event) = reader.read_resolved_event().map_err(io_error)?;
        let namespace = match namespace {
            ResolveResult::Bound(ns) => String::from_utf8_lossy(ns.as_ref()).into_owned(),
            ResolveResult::Unbound => String::new(),
            ResolveResult::Unknown(_) => return Err(io_error("Unbound XML namespace")),
        };
        match event {
            Event::Start(ref start) | Event::Empty(ref start) => {
                let empty = matches!(event, Event::Empty(_));
                if stack.is_empty() {
                    roots += 1;
                }
                let attributes = start
                    .attributes()
                    .map(|attribute| {
                        let attribute = attribute.map_err(io_error)?;
                        Ok((
                            String::from_utf8_lossy(attribute.key.as_ref()).into_owned(),
                            attribute
                                .decode_and_unescape_value(reader.decoder())
                                .map_err(io_error)?
                                .into_owned(),
                        ))
                    })
                    .collect::<Result<Vec<_>, HentaiError>>()?;
                let after = reader.buffer_position() as usize;
                let node = Node {
                    name: String::from_utf8_lossy(start.local_name().as_ref()).into_owned(),
                    namespace,
                    attributes,
                    range: before..after,
                    content: after..after,
                    depth: stack.len(),
                    text: String::new(),
                    empty,
                };
                if empty {
                    nodes.push(node);
                } else {
                    stack.push(node);
                }
            }
            Event::End(_) => {
                let mut node = stack
                    .pop()
                    .ok_or_else(|| io_error("Unmatched XML closing tag"))?;
                node.content.end = before;
                node.range.end = reader.buffer_position() as usize;
                nodes.push(node);
            }
            Event::Text(text) => {
                let text = text.unescape().map_err(io_error)?;
                if stack.is_empty() && !text.trim().is_empty() {
                    return Err(io_error("Text outside XML root"));
                }
                for node in &mut stack {
                    node.text.push_str(&text);
                }
            }
            Event::CData(text) => {
                let text = text.decode().map_err(io_error)?;
                for node in &mut stack {
                    node.text.push_str(&text);
                }
            }
            Event::DocType(_) => return Err(io_error("DTD is unsupported")),
            Event::Eof => break,
            _ => {}
        }
    }
    if roots != 1 || !stack.is_empty() {
        return Err(io_error("Incomplete or conflicting XML roots"));
    }
    nodes.sort_by_key(|node| node.range.start);
    Ok(nodes)
}
pub(super) fn replace(
    xml: &str,
    mut edits: Vec<(Range<usize>, String)>,
) -> Result<String, HentaiError> {
    edits.sort_by_key(|(range, _)| (range.start, range.end));
    let mut output = String::new();
    let mut cursor = 0;
    for (range, value) in edits {
        if range.start < cursor {
            return Err(io_error("Overlapping XML metadata edits"));
        }
        output.push_str(&xml[cursor..range.start]);
        output.push_str(&value);
        cursor = range.end;
    }
    output.push_str(&xml[cursor..]);
    nodes(&output)?;
    Ok(output)
}
pub(super) fn escaped(text: &str) -> String {
    quick_xml::escape::escape(text).into_owned()
}
