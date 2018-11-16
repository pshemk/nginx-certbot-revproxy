#!/usr/bin/env python

import sys
import os
import signal

def write_stdout(s):
    # only eventlistener protocol messages may be sent to stdout
    sys.stdout.write(s)
    sys.stdout.flush()

def write_stderr(s):
    sys.stderr.write(s)
    sys.stderr.flush()

def main():
    while 1:
        # transition from ACKNOWLEDGED to READY
        write_stdout('READY\n')

        # read header line and print it to stderr
        line = sys.stdin.readline()
        write_stderr(line)

        # read event payload and print it to stderr
        headers = dict([ x.split(':') for x in line.split() ])
        sys.stdin.read(int(headers['len']))
        # write_stderr(data)
        #write_stderr(json.dumps(headers))
        if headers['eventname'] == 'PROCESS_STATE_FATAL':
            try:
                    pidfile = open('/supervisord.pid','r')
                    pid = int(pidfile.readline());
                    os.kill(pid, signal.SIGQUIT)
            except Exception as e:
                    write_stderr('Could not kill supervisor: ' + e.strerror + '\n')

        # transition from READY to ACKNOWLEDGED
        write_stdout('RESULT 2\nOK')

if __name__ == '__main__':
    main()