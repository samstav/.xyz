#! /usr/bin/env python
from __future__ import print_function

import argparse
import getpass
import json
import os

import requests

MAILGUN = 'https://api.mailgun.net/v3'


def _mailgun_session(user, key):
    mailgun = requests.session()
    mailgun.auth = requests.auth.HTTPBasicAuth(user, key)
    return mailgun

def _show_domains(args):
    mailgun = _mailgun_session(args.mailgun_user, args.mailgun_api_key)
    url = '{0}/domains'.format(MAILGUN)
    res = mailgun.get(url)
    res.raise_for_status()
    if args.verbose:
        domains = res.json()['items']
    else:
        domains = [_x['name'] for _x in res.json()['items']]
    print(json.dumps(domains, sort_keys=True, indent=2))


def _show_domain(args):
    mailgun = _mailgun_session(args.mailgun_user, args.mailgun_api_key)
    url = '{0}/domains/{1}'.format(MAILGUN, args.domain)
    res = mailgun.get(url)
    res.raise_for_status()
    print(json.dumps(res.json(), sort_keys=True, indent=2))



def _tfvars(args):
    mailgun = _mailgun_session(args.mailgun_user, args.mailgun_api_key)
    url = '{0}/domains/{1}'.format(MAILGUN, args.domain)
    res = mailgun.get(url)
    res.raise_for_status()
    domain = res.json()
    print(json.dumps(domain, sort_keys=True, indent=2))
    tfvars = {
        'domain': domain['domain']['name'],
        'mailgun_domain_smtp_password': domain['domain']['smtp_password'],
        'mailgun_domain_spam_action': domain['domain']['spam_action'],
        'mailgun_domain_wildcard': domain['domain']['wildcard'],
    }
    print(json.dumps(tfvars, sort_keys=True, indent=2))

def _dispatch(parser):
    args = parser.parse_args()
    required = ['mailgun_api_key', 'mailgun_user']
    for _arg in required:
        if hasattr(args, _arg) and not getattr(args, _arg, None):
            parser.error('{0} required'.format(_arg))
    return args._func(args)


if __name__ == '__main__':

    parser = argparse.ArgumentParser(
        description='Get variables for terraform.'
    )
    parser.add_argument(
        '--verbose', '-v',
        action='count',
    )

    parser.add_argument(
        '--mailgun-api-key', '-k',
        help='Defaults to the MAILGUN_API_KEY environment variable.',
        default=os.getenv('MAILGUN_API_KEY') or None,
    )
    parser.add_argument(
        '--mailgun-user', '-u',
        help='Defaults to the MAILGUN_USER environment variable.',
        default=os.getenv('MAILGUN_USER') or None,
    )

    subparsers = parser.add_subparsers()
    show_domains = subparsers.add_parser('show-domains')
    show_domains.set_defaults(_func=_show_domains)

    show_domain = subparsers.add_parser('show-domain')
    show_domain.add_argument(
        '--domain', '-d',
        required=True,
        help='Show details for this domain.'
    )
    show_domain.set_defaults(_func=_show_domain)


    tfvars = subparsers.add_parser(
        'tfvars',
        help='Produce tfvars for Route 53 setup.',
    )
    tfvars.set_defaults(_func=_tfvars)
    tfvars.add_argument(
        '--domain', '-d',
        required=True,
        help='Domain to get tfvars for.'
    )

    try:
        # Parse argument and check required.
        _dispatch(parser)
    except KeyboardInterrupt:
        print(' Stahp', file=sys.stderr)
        sys.exit(1)
