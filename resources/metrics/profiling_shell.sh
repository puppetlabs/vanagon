#!/bin/bash

# this variant of the Profiling shell wrapper
# uses only the Bash keyword `time`, and the generally
# standard command `tee` to get run time. This was
# needed because the BSD/sysv variants of `date` only
# offer second-resolution. No milliseconds, no nano-
# seconds.

# Create copies of stdout & stderr's file descriptors
# so that the output of the subshell that `time` runs
# can be captured and used.
exec 3>&1
exec 4>&2

# Write some log files, that can be post-processed
# relatively easily.
__stdout="${VANAGON_TARGET}.stdout.log"
__stderr="${VANAGON_TARGET}.stderr.log"

# Define a default time format (seconds and milliseconds),
# and then use some insane output redirection hacks to capture
# the output of the `time` keyword. We're using `tee` to
# output to stdout & stderr but we should figure out how to
# supress that for quieter Vanagon builds.
TIMEFORMAT='%3R'
__seconds="$( {
  time bash -o pipefail "${@}" > >(tee -ai "${__stdout}" >&3) 2> >(tee -ai "${__stderr}" >&4 )
} 2>&1)"

# If any part of the pipeline failed, then
# this status should correspond to whatever
# failing status the pipeline returned. We
# want to check & preserve that.
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
  exit "${PIPESTATUS[0]}"
fi

# Finally, if everything completed successfully,
# finesse the numbers and fire them off to our
# statsd interface.
if [[ "${VANAGON_TARGET}" ]] && [[ "${VANAGON_STATSD_HOST}" ]] && [[ "${VANAGON_STATSD_PORT}" ]]; then
  __elapsed="$(echo "scale=0;${__seconds}*1000/1" | bc -l)"
  echo -n "vanagon.${VANAGON_PROJECT}.${VANAGON_PLATFORM}.${VANAGON_TARGET}:${__elapsed}|ms" > "/dev/udp/${VANAGON_STATSD_HOST}/${VANAGON_STATSD_PORT}"
fi
