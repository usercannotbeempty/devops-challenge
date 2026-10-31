"""Verify environment-specific document access without AWS."""
from pathlib import Path
import unittest

import hcl2

ROOT = Path(__file__).resolve().parents[1]


class DocumentAccessTest(unittest.TestCase):
    def test_upload_and_read_roles_are_separate(self):
        for env in ('dev', 'prod'):
            with self.subTest(environment=env):
                base = ROOT / f'live/acme/ap-southeast-3/claims/{env}'
                with (base / 'claims-upload-iam/terragrunt.hcl').open() as source:
                    upload = hcl2.load(source)
                with (base / 'claims-worker-iam/terragrunt.hcl').open() as source:
                    worker = hcl2.load(source)
                with (base / 'claim-documents-bucket/terragrunt.hcl').open() as source:
                    bucket = hcl2.load(source)['inputs']
                self.assertTrue(bucket['name'].endswith(f'-{env}'))
                self.assertEqual(upload['inputs']['name'], f'claims-upload-{env}')
                self.assertEqual(upload['inputs']['namespace'], 'claims')
                self.assertEqual(upload['inputs']['service_account'], 'claims-api')
                self.assertEqual(len(upload['inputs']['policy_statements']), 1)
                read = next(s for s in worker['inputs']['policy_statements'] if s['sid'] == 'ReadClaimDocuments')
                for statement, action in [(upload['inputs']['policy_statements'][0], 's3:PutObject'), (read, 's3:GetObject')]:
                    self.assertEqual(statement['actions'], [action])
                    self.assertEqual(statement['effect'], 'Allow')
                    self.assertEqual(statement['resources'], ['${dependency.documents.outputs.bucket_arn}/claims/*'])
                for config in (upload, worker):
                    dependencies = {key: value for entry in config['dependency'] for key, value in entry.items()}
                    self.assertEqual(dependencies['documents']['config_path'], '../claim-documents-bucket')
                    self.assertEqual(dependencies['eks']['config_path'], f'../../../platform/{env}/eks')
