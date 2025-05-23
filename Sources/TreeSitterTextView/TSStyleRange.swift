import AppKit

public class TSStyleRange {
    public init(
        rangeStyles: [RangeStyle] = [],
        isRangeStylesMerged: Bool = false
    ) {
        self._rangeStyles = rangeStyles
        self.isRangeStylesMerged = isRangeStylesMerged
    }

    public struct RangeStyle: Equatable {
        var range: NSRange
        var style: TSStyle
    }
    public enum TSStyleRangeError: Error {
        case InvaildRange
        case NonContiguousRanges
    }

    private var _rangeStyles: [RangeStyle] = []
    private var isRangeStylesMerged = false
    public var rangeStyles: [RangeStyle] {
        if isRangeStylesMerged { return _rangeStyles }
        _rangeStyles = mergeRangeStyle(_rangeStyles)
        isRangeStylesMerged = true
        return _rangeStyles
    }

    private func mergeRangeStyle(_ rangeStyles: [RangeStyle]) -> [RangeStyle] {
        var merged: [RangeStyle] = []
        var pending: RangeStyle?
        for rangeStyle in rangeStyles {
            if var currentPending = pending {
                if rangeStyle.style == currentPending.style && currentPending.range.upperBound == rangeStyle.range.lowerBound {
                    currentPending.range.length += rangeStyle.range.length
                    pending = currentPending
                } else {
                    merged.append(currentPending)
                    pending = rangeStyle
                }
            } else {
                pending = rangeStyle
            }
        }

        if let pending = pending {
            merged.append(pending)
        }
        return merged
    }

    public func replaceStyle(in range: NSRange, with style: TSStyle, length: Int) throws {
        guard range.location >= 0, range.length >= 0, length >= 0,
            range.upperBound <= _rangeStyles.last?.range.upperBound ?? 0
        else { throw TSStyleRangeError.InvaildRange }

        let delta = length - range.length
        var result: [RangeStyle] = []
        var inserted = false

        for rangeStyle in _rangeStyles {
            let original = rangeStyle.range

            if original.upperBound <= range.lowerBound {
                result.append(rangeStyle)
            } else if original.lowerBound >= range.upperBound {
                let shiftedRange = NSRange(
                    location: original.location + delta, length: original.length)
                let shiftedRangeStyle = RangeStyle(
                    range: shiftedRange,
                    style: rangeStyle.style,
                )
                result.append(shiftedRangeStyle)
            } else {
                if original.location < range.location {
                    let leftRange = NSRange(
                        location: original.location, length: range.location - original.location)
                    let leftRangeStyle = RangeStyle(
                        range: leftRange,
                        style: rangeStyle.style,
                    )
                    result.append(leftRangeStyle)
                }

                if !inserted && length > 0 {
                    let newRange = NSRange(location: range.location, length: length)
                    result.append(RangeStyle(range: newRange, style: style))
                    inserted = true
                }

                if original.upperBound > range.upperBound {
                    let offset = delta
                    let rightStart = range.upperBound + offset
                    let rightLength = original.upperBound - range.upperBound
                    let rightRange = NSRange(location: rightStart, length: rightLength)
                    let rightRangeStyle = RangeStyle(
                        range: rightRange,
                        style: rangeStyle.style,
                    )
                    result.append(rightRangeStyle)
                }
            }
        }

        if !inserted && length > 0 {
            let newRange = NSRange(location: range.location, length: length)
            result.append(RangeStyle(range: newRange, style: style))
        }
        _rangeStyles = result
        isRangeStylesMerged = false
    }

    public func checkRangeStyles() throws {
        var lastEnd: Int?
        for _rangeStyle in _rangeStyles {
            if let lastEnd = lastEnd {
                if lastEnd != _rangeStyle.range.location {
                    throw TSStyleRangeError.NonContiguousRanges
                }
            }
            lastEnd = _rangeStyle.range.upperBound
        }
    }

    private func getStyle(in nsRange: NSRange) -> TSStyle? {
        for rangeStyle in _rangeStyles {
            let intersectionRange = NSIntersectionRange(rangeStyle.range, nsRange)
            if intersectionRange.length > 0 {
                return rangeStyle.style
            }
        }
        return nil
    }

    public static func build(_ rangeStyles: [(range: NSRange, style: TSStyle)]) -> TSStyleRange {
        guard !rangeStyles.isEmpty else { return TSStyleRange() }
        var points = Set<Int>()
        for rangeStyle in rangeStyles {
            points.insert(rangeStyle.range.lowerBound)
            points.insert(rangeStyle.range.upperBound)
        }

        let sortedPoints = points.sorted()
        var result: [RangeStyle] = []
        var pending: RangeStyle?

        for i in 0..<sortedPoints.count - 1 {
            let start = sortedPoints[i]
            let end = sortedPoints[i + 1]
            let subrange = NSRange(location: start, length: end - start)

            var applicableStyle: TSStyle? = nil
            for (range, style) in rangeStyles {
                if NSIntersectionRange(range, subrange).length > 0 {
                    if let currentStyle = applicableStyle {
                        applicableStyle = currentStyle.merge(style)
                    } else {
                        applicableStyle = style
                    }
                }
            }

            if let style = applicableStyle {
                if var currentPending = pending, currentPending.style == style, currentPending.range.upperBound == start {
                    currentPending.range.length += subrange.length
                    pending = currentPending
                } else {
                    let newRangeStyle = RangeStyle(range: subrange, style: style)
                    if let pending = pending {
                        result.append(pending)
                    }
                    pending = newRangeStyle
                }
            }
        }

        if let pending = pending {
            result.append(pending)
        }

        return TSStyleRange(rangeStyles: result, isRangeStylesMerged: true)
    }

    static func getDiffRangeStyle(
        old: TSStyleRange, new: TSStyleRange, baseStyle: TSStyle
    ) -> [RangeStyle] {
        var points = Set<Int>()

        for r in old.rangeStyles {
            points.insert(r.range.lowerBound)
            points.insert(r.range.upperBound)
        }
        for r in new.rangeStyles {
            points.insert(r.range.lowerBound)
            points.insert(r.range.upperBound)
        }
        let sortedPoints = points.sorted()

        var updates: [RangeStyle] = []

        for i in 0..<max(sortedPoints.count - 1, 0) {
            let start = sortedPoints[i]
            let end = sortedPoints[i + 1]
            guard start < end else { continue }
            let subrange = NSRange(location: start, length: end - start)

            let oldStyle = old.getStyle(in: subrange)
            let newStyle = new.getStyle(in: subrange)

            if oldStyle != newStyle {
                let styleToApply: TSStyle
                if oldStyle != nil && newStyle == nil {
                    styleToApply = baseStyle
                } else if let newS = newStyle {
                    styleToApply = newS
                } else {
                    styleToApply = baseStyle
                }
                updates.append(TSStyleRange.RangeStyle(range: subrange, style: styleToApply))
            }
        }

        return updates
    }
}
