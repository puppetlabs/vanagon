#!/bin/bash

# Vanagon profiling shell wrapper
# version: 1.0.0
# author: Ryan McKern <mckern@puppet.com>

# The Vanagon Profiling shell wrapper
# uses only the Bash keyword `time` and the generally
# standard command `tee` to get run time. This was
# needed because the BSD/sysv variants of `date` only
# offer second-resolution. No milliseconds, no nano-
# seconds. The results of `time` will be written to a
# csv file containing a single column (times for each
# subshell run as part of a given Make target. Each line
# is a subshell's runtime in whole seconds with 3 decimal 
# places of precision), named after the Make target, e.g.
#   facter-configure.csv, facter-install.csv, etc.
#
# Of note is that we are intentionally avoiding using
# `set -o pipefail` or `set -e` as these can cause
# numerous false-positive failures depending on the
# level of care and complexity in a given Make recipe.

# Write some log files, that can be post-processed
# relatively easily. While you're at it, store runtimes in batches.
if [[ -n ${VANAGON_TARGET} ]]; then
  __batchfile="runtimes/${VANAGON_TARGET}.csv"
  __stdout="logs/${VANAGON_TARGET}.stdout.log"
  __stderr="logs/${VANAGON_TARGET}.stderr.log"
  mkdir "logs" "runtimes"
else
  # Alternatively, if there's no defined Target, just
  # dump that stuff in the bitbucket
  __batchfile="/dev/null"
  __stdout="/dev/null"
  __stderr="/dev/null"
fi

# Define a default time format (seconds and milliseconds),
# and then use some insane output redirection hacks to capture
# the output of the `time` keyword. We're using `tee` to
# output to stdout & stderr but we should figure out how to
# supress that for quieter Vanagon builds.
TIMEFORMAT='%3R'
{ __seconds="$( {
    time bash "${@}" > >(tee -ai "${__stdout}" >&3) 2> >(tee -ai "${__stderr}" >&4
  ); } 2>&1 )";
} 3>&1 4>&2

# PIPESTATUS can be reset prety easily, so the value of this specific pipeline
# should be preserved to enable correct post-processing.
__status=("${PIPESTATUS[@]}")

# allow a failure in the command pipeline to halt execution,
# the same way Make would if the pipeline was being executed
# directly in Bash without this wrapper. This will halt the job
# without sending metrics for this job upstream.
for value in "${__status[@]}"; do
  if [[ ${value} -ne 0 ]]; then
    exit "${value}"
  fi
done

# Batch the runtime for this task
echo "${__seconds}" >> "${__batchfile}"

# Explicitly exit with success
exit
