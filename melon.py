#! /usr/bin/env python
from __future__ import print_function

import argparse
import getpass
import json
import os
import shlex
import subprocess

import boto3
import requests

MAILGUN = 'https://api.mailgun.net/v3'
AWS_DEFAULT_REGION = 'us-east-1'
TERRAFORM_REMOTE_CONFIG_BUCKET = 'melon-terraform-state-{domain}'
TERRAFORM_REMOTE_CONFIG_KEY = 'melon-terraform.tfstate'


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
    tfvars = {
        'variable': {
            'domain': {
                'default': domain['domain']['name']
            },
            'mailgun_api_key': {
                'default': args.mailgun_api_key
            },
            'mailgun_domain_smtp_password': {
                'default': domain['domain']['smtp_password']
            },
            'mailgun_domain_spam_action': {
                'default': domain['domain']['spam_action']
            },
            'mailgun_domain_wildcard': {
                'default': domain['domain']['wildcard']
            },
        }
    }
    print(json.dumps(tfvars, sort_keys=True, indent=4))



def _check_tf_config_bucket(domain):
    s3_service_resource = boto3.resource('s3')
    bucket = s3_service_resource.create_bucket(
        Bucket=TERRAFORM_REMOTE_CONFIG_BUCKET.format(domain=domain),
    )
    bucket.wait_until_exists()


def _tf_remote_config(args):
    _check_tf_config_bucket(args.domain)
    command = [
        'terraform', 'remote', 'config',
        '-state="{0}"'.format(TERRAFORM_REMOTE_CONFIG_KEY),
        # This doesn't seem to have an effect-- commenting out.
        # '-backup="{0}.backup"'.format(
        #     os.path.join(
        #         os.path.abspath(os.getcwd()),
        #         TERRAFORM_REMOTE_CONFIG_KEY
        #     )
        # ),
        '-backend="S3"',
        '-backend-config="bucket={0}"'.format(
            TERRAFORM_REMOTE_CONFIG_BUCKET.format(domain=args.domain)
        ),
        '-backend-config="key={0}"'.format(TERRAFORM_REMOTE_CONFIG_KEY),
        '-backend-config="region={0}"'.format(args.aws_region),
        '-backend-config="encrypt=1"',
    ]
    command = ' '.join(command)
    if args.dry_run:
        print('Would run command:\n')
        print(command)
    else:
        subprocess.call(shlex.split(command))

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
    def _mailgun_args(_parser):
        _parser.add_argument(
            '--mailgun-api-key', '-k',
            help='Defaults to the MAILGUN_API_KEY environment variable.',
            default=os.getenv('MAILGUN_API_KEY') or None,
        )
        _parser.add_argument(
            '--mailgun-user', '-u',
            help='Defaults to the MAILGUN_USER environment variable.',
            default=os.getenv('MAILGUN_USER') or None,
        )

    subparsers = parser.add_subparsers()
    show_domains = subparsers.add_parser(
        'show-domains',
        help='Show domains in Mailgun.'
    )
    _mailgun_args(show_domains)
    show_domains.set_defaults(_func=_show_domains)

    show_domain = subparsers.add_parser(
        'show-domain',
        help='Show details for a single Mailgun domain.'
    )
    _mailgun_args(show_domain)
    show_domain.add_argument(
        'domain',
        help='Show details for this domain.'
    )
    show_domain.set_defaults(_func=_show_domain)


    tfvars = subparsers.add_parser(
        'tfvars',
        help='Produce tfvars for Route 53 setup.',
    )
    _mailgun_args(tfvars)
    tfvars.set_defaults(_func=_tfvars)
    tfvars.add_argument(
        'domain',
        help='Domain to get tfvars for.'
    )

    tf_remote_config = subparsers.add_parser(
        'tf-remote-config',
        help=('Configure the use of remote state '
              'storage in AWS S3 for terraform. This '
              'includes creating the bucket if necessary.'),
    )
    tf_remote_config.set_defaults(_func=_tf_remote_config)
    tf_remote_config.add_argument(
        '--dry-run', '-d',
        action='store_true',
        default=False,
        help=("Don't run the terraform remote config command, "
              "just show me the command.")
    )
    tf_remote_config.add_argument(
        'domain',
        type=lambda _x: _x.lower().replace('.', '-dot-'),
        help=('The domain is used to build the S3 bucket name. '
              'e.g. FOO.com results in a bucket named '
              'melon-terraform-state-foo-dot-com.')
    )
    tf_remote_config.add_argument(
        '--aws-region', '-r',
        default=boto3.Session().region_name or AWS_DEFAULT_REGION,
        help=('AWS Region for terraform S3 backend. '
              'The standard aws/boto machinery will look this up in your '
              'environment, else defaults to {0}'.format(AWS_DEFAULT_REGION))
    )

    try:
        # Parse argument and check required.
        _dispatch(parser)
    except KeyboardInterrupt:
        print(' Stahp', file=sys.stderr)
        sys.exit(1)
