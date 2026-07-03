/// 卷序排序键，对应 Dart `num volumeSortKey`。
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum VolumeSortKey {
    Int(i32),
    Float(f64),
}

impl VolumeSortKey {
    pub fn int(value: i32) -> Self {
        Self::Int(value)
    }

    pub fn float(value: f64) -> Self {
        Self::Float(value)
    }

    /// 与 Dart [InferredSeriesGrouper.compareVolumeSortKey] 一致。
    pub fn compare(a: Self, b: Self) -> std::cmp::Ordering {
        match (a, b) {
            (Self::Int(x), Self::Int(y)) => x.cmp(&y),
            (a, b) => a
                .as_f64()
                .partial_cmp(&b.as_f64())
                .unwrap_or(std::cmp::Ordering::Equal),
        }
    }

    fn as_f64(self) -> f64 {
        match self {
            Self::Int(i) => f64::from(i),
            Self::Float(f) => f,
        }
    }

    pub fn floor_i32(self) -> i32 {
        match self {
            Self::Int(i) => i,
            Self::Float(f) => f.floor() as i32,
        }
    }

    /// 是否存在非整数卷序（用于稠密名次输出）。
    pub fn is_non_integer(self) -> bool {
        match self {
            Self::Int(_) => false,
            Self::Float(f) => f != f.floor(),
        }
    }
}
