#!/usr/bin/env sh
{{ zeopack_filepath }}
exit_status=$?
if [ $exit_status -eq 0 ]; then
    rm -f {{ zeopack_old_data_filepath }}
fi
exit $exit_status
