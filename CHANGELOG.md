# Change Logs

## v0.0.2

 - support subset presentation: `partial` splits each row along its width, the left part being
   the selected share
 - dim rows that are not selected, following `binding.name.filter`. the chart does not emit
   that filter itself ( the host stands in with the `select` event ), but it is told what is
   selected and can now draw it
 - fix bug: labels drifted out of the chart after hovering. the offset that scrolls the label
   list when there are too many to fit is clamped to `last - rbox.height`, which is negative
   when they all fit — and a negative offset pushes the whole group down and off the chart
 - fix bug: label positions are measured from a hidden html copy, but the measuring only
   happened in resize. a late web font or a changed root font size reflows that copy without
   triggering a resize, leaving the measurements stale and the labels misplaced. they are
   re-measured on every render now


## v0.0.1

init release
