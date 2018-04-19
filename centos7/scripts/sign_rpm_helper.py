#!/usr/bin/env python

# Helper script to sign RPMs by sending the passphrase.
# The GPG_PASSPHRASE from the environment is used for signing

import argparse
import os
import pexpect

parser = argparse.ArgumentParser(description='Sign RPMs by sending the passphrase')
requiredNamed = parser.add_argument_group('required named arguments')
requiredNamed.add_argument('--file_path', help='RPMS to sign.  May be an extended pattern match like /tmp/*.rpm', required=True)
args = parser.parse_args()

child = pexpect.spawn('rpm --addsign {file_path}'.format(file_path=args.file_path))
child.expect('Enter pass phrase: ')
child.send("{secret_passphrase}\n".format(secret_passphrase=os.environ['GPG_PASSPHRASE']))
child.expect('Pass phrase is good')
child.expect(pexpect.EOF)
print(child.before)
exit(child.exitstatus)
