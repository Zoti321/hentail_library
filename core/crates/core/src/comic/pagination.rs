//! 分页页窗（page window）的唯一主人。
//!
//! 六处钳到末页的调用点（目录、Series、Series 成员、作者、命名 facet、Tag）与三条原样回显
//! 的路径（关键字搜索、元数据表达式搜索、回收站）此前各自手写同一段算术；本模块让它只存在一次。
//!
//! `paginate` 是纯计算：不吃数据库、不做 I/O，因为「总行数」只有调用方拿得到。
//! 它只算「请求的页在 total 行里意味着什么」，不替调用方决定越界语义 ——
//! 每条路径继续自己决定是钳到末页（目录/Series/Series 成员/作者/facet/Tag）
//! 还是原样回显（关键字搜索/元数据表达式搜索/回收站）。

use crate::comic::dto::PageRequestDto;

/// 一次分页请求解析后的页窗。
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PageWindow {
    /// 请求页钳到 `>= 1`。是否再钳到末页由调用方决定（`clamped()`）；空集时原样保留。
    pub page: i32,
    /// 请求的页大小，钳到 `>= 1`。
    pub page_size: i32,
    /// 总页数；`total <= 0` 时为 `0`。
    pub total_pages: i64,
    /// 该页在总行数里的窗口起点。调用方是否使用见模块注释。
    pub offset: i64,
}

/// 把一条分页请求解析成页窗。纯函数：只依赖入参。
pub fn paginate(request: PageRequestDto, total: i64) -> PageWindow {
    let page_size = request.page_size.max(1);
    PageWindow::resolve(request.page, page_size, total)
}

impl PageWindow {
    pub(crate) fn resolve(page: i32, page_size: i32, total: i64) -> Self {
        let page = page.max(1);
        let total_pages = if total <= 0 {
            0
        } else {
            (total + page_size as i64 - 1) / page_size as i64
        };
        Self {
            page,
            page_size,
            total_pages,
            offset: (page as i64 - 1) * page_size as i64,
        }
    }

    /// 请求页钳到末页。调用方声明「越界页要看到最后一页的内容」时用它。
    pub fn clamped(self) -> Self {
        let page = if self.total_pages > 0 && self.page as i64 > self.total_pages {
            self.total_pages as i32
        } else {
            self.page
        };
        Self {
            offset: (page as i64 - 1) * self.page_size as i64,
            page,
            ..self
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn request(page: i32, page_size: i32) -> PageRequestDto {
        PageRequestDto { page, page_size }
    }

    #[test]
    fn page_and_page_size_are_floor_clamped_to_one() {
        let window = paginate(request(0, 0), 100);
        assert_eq!((window.page, window.page_size), (1, 1));

        let negative = paginate(request(-7, -3), 100);
        assert_eq!((negative.page, negative.page_size), (1, 1));
    }

    #[test]
    fn total_pages_rounds_up_and_offset_walks_the_pages() {
        let first = paginate(request(1, 50), 120);
        assert_eq!(first.total_pages, 3);
        assert_eq!(first.offset, 0);

        let second = paginate(request(2, 50), 120);
        assert_eq!(second.offset, 50);

        let third = paginate(request(3, 50), 120);
        assert_eq!(third.offset, 100);
    }

    #[test]
    fn exact_multiple_does_not_add_a_page() {
        assert_eq!(paginate(request(1, 50), 100).total_pages, 2);
    }

    #[test]
    fn empty_result_has_no_pages() {
        let window = paginate(request(9, 20), 0);
        assert_eq!(window.total_pages, 0);
        assert_eq!(window.offset, 160);

        // 负总数按空集看待（计数查询的失败态曾以 0 表达）。
        assert_eq!(paginate(request(3, 20), -5).total_pages, 0);
    }

    #[test]
    fn paginate_alone_does_not_clamp_an_out_of_range_page() {
        // 越界语义留在调用方：搜索路径依赖「原样回显请求页」，目录路径再调 `clamped()`。
        let window = paginate(request(999, 20), 40);
        assert_eq!(window.page, 999);
        assert_eq!(window.total_pages, 2);
        assert_eq!(window.offset, 19960);
    }

    #[test]
    fn clamped_moves_an_out_of_range_page_onto_the_last_page() {
        let window = paginate(request(999, 20), 40).clamped();
        assert_eq!(window.page, 2);
        assert_eq!(window.offset, 20);
        assert_eq!(window.page_size, 20);
        assert_eq!(window.total_pages, 2);
    }

    #[test]
    fn clamped_is_the_identity_inside_the_range_or_when_there_are_no_pages() {
        let in_range = paginate(request(2, 20), 40).clamped();
        assert_eq!((in_range.page, in_range.offset), (2, 20));

        let beyond_end = paginate(request(2, 20), 30).clamped();
        assert_eq!((beyond_end.page, beyond_end.offset), (2, 20));

        // 空集没有可钳的末页；把 page 归 1 是调用方 early return 的事，不是页窗的事。
        let empty = paginate(request(5, 20), 0).clamped();
        assert_eq!((empty.page, empty.total_pages), (5, 0));
    }
}
