return {
  'TODO(t)', -- Actions that are not started and not planned. These are backlog.
  'MAYBE(m)', -- 🤷‍♂️ maybe will do, if so, probably needs refinement.
  'UPCOMING(u)', -- Events that are upcoming, not actions to take.
  'NEXT(n)', -- Actions that are not started, but have been selected through planning to be engaged with next.
  'WAITING(w)', -- Actions that are waiting on some hold up or time to lapse.
  'PROG(s)', -- Actions that are currently WIP - these are the priorities.
  'PROJECT(p)', -- Ongoing projects/epics that span multiple days, and should not be considered as actions.
  '|',
  'CANCELLED(c)',
  'DONE(d)', -- 😎👍
}
